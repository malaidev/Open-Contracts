const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
    getSelectors,
    get,
    FacetCutAction,
    removeSelectors,
    findAddressPositionInFacets
    } = require('../scripts/libraries/diamond.js')
  
const { assert } = require('chai')

const {deployDiamond}= require('../scripts/deploy_diamond.js')

describe("===== Deposit Test =====", function () {
    let diamondAddress
    let diamondCutFacet
    let diamondLoupeFacet
    let tokenList
    let comptroller
    let deposit
    let bep20
    let accounts
    let contractOwner
    const addresses = []

    const symbol4 = "0xABCD7374737472696e6700000000000000000000000000000000000000000000";
    const symbol2 = "0xABCD7374737972696e6700000000000000000000000000000000000000000000";
   
    const comit_NONE = "0x94557374737472696e6700000000000000000000000000000000000000000000";
    const comit_TWOWEEKS = "0x78629858A2529819179178879ABD797997979AD97987979AC7979797979797DF";
    const comit_ONEMONTH = "0x54567858A2529819179178879ABD797997979AD97987979AC7979797979797DF";
    const comit_THREEMONTHS = "0x78639858A2529819179178879ABD797997979AD97987979AC7979797979797DF";

    before(async function () {
        accounts = await ethers.getSigners()
        contractOwner = accounts[0]
        diamondAddress = await deployDiamond()
        // await deployOpenFacets(diamondAddress)
        diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)

        tokenList = await ethers.getContractAt('TokenList', diamondAddress)
        comptroller = await ethers.getContractAt('Comptroller', diamondAddress)
        deposit = await ethers.getContractAt("Deposit", diamondAddress)

        const Mock = await ethers.getContractFactory('MockBep20')
        bep20 = await Mock.deploy()
        await bep20.deployed()

    })

    it('should have three facets -- call to facetAddresses function', async () => {
        for (const address of await diamondLoupeFacet.facetAddresses()) {
            addresses.push(address)
        }
        assert.equal(addresses.length, 11)
    })

    it('facets should have the right function selectors -- call to facetFunctionSelectors function', async () => {
        let selectors = getSelectors(diamondCutFacet)
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[0])
        assert.sameMembers(result, selectors)
        selectors = getSelectors(diamondLoupeFacet)
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[1])
        assert.sameMembers(result, selectors)
    })

    it("Add token to tokenList", async () => {
        await expect(tokenList.connect(contractOwner).addMarketSupport(
            symbol4, 
            18, 
            bep20.address, 
            1,
            {gasLimit: 250000}
        )).to.emit(tokenList, "MarketSupportAdded")
        expect(await tokenList.isMarketSupported(symbol4)).to.be.equal(true);

        await expect(tokenList.connect(accounts[1]).addMarketSupport(
            symbol2, 18, bep20.address, 1, {gasLimit: 240000}
        )).to.be.revertedWith("Only an admin can call this function");
    })

    it("Initialize", async () => {
        await comptroller.connect(contractOwner).setCommitment(comit_NONE);
        await comptroller.connect(contractOwner).setCommitment(comit_TWOWEEKS);
        await comptroller.connect(contractOwner).setCommitment(comit_ONEMONTH);
        await comptroller.connect(contractOwner).setCommitment(comit_THREEMONTHS);
        
        await comptroller.connect(contractOwner).updateAPY(comit_TWOWEEKS, 6);
    })

    it("hasAccount", async () => {
        await expect(deposit.hasAccount(tokenList.address)).to.revertedWith("ERROR: No savings account")
    })

    it("Token Mint to Deposit", async () => {
        console.log("Before deposit balance is ", await bep20.balanceOf(deposit.address));
        expect(await bep20.balanceOf(deposit.address)).to.be.equal(0);
        await expect(bep20.transfer(deposit.address, 1000000000000000)).to.emit(bep20, 'Transfer');
        expect(await bep20.balanceOf(deposit.address)).to.equal(1000000000000000);
        await bep20.transfer(contractOwner.address, 10000000000000);
    })

    it("Check createDeposit", async () => {
        const depositAmount = 300;
        
        await expect(deposit.connect(contractOwner).createDeposit(symbol4, comit_TWOWEEKS, depositAmount, {gasLimit: 5000000}))
            .emit("NewDeposit")
    })

    it("Check is created", async () => {
        expect(await deposit.hasDeposit(symbol4, comit_TWOWEEKS)).to.equal(true)
    })

    it("withdrawDeposit", async () => {
        console.log(await bep20.balanceOf(contractOwner.address))
        await deposit.connect(contractOwner).withdrawDeposit(symbol4, comit_TWOWEEKS, 150, 0)
        console.log(await bep20.balanceOf(contractOwner.address))
    })

    it("Check addToDeposit", async () => {
        await expect(deposit.connect(contractOwner).addToDeposit(symbol4, comit_TWOWEEKS, 400, {gasLimit: 3000000}))
        .to.emit(deposit, "DepositAdded");
    })
})
