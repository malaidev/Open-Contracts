const { expect } = require("chai");
const { ethers } = require("hardhat");

const {deployDiamond}= require('../scripts/deploy_all.js')
const {deployOpenFacets}= require('../scripts/deploy_all.js')
const {addMarkets}= require('../scripts/deploy_all.js')

describe("===== Deposit Test =====", function () {
    let diamondAddress
    let diamondCutFacet
    let diamondLoupeFacet
    let tokenList
    let comptroller
    let deposit
    let library
    let bep20
    let tusdt
    let accounts
    let contractOwner
    const addresses = []

    const symbolOne = "0x4f4e452e74000000000000000000000000000000000000000000000000000000";
    const symbolUsdt = "0x555344542e740000000000000000000000000000000000000000000000000000";
    const symbol4 = "0x234e452e74000000000000000000000000000000000000000000000000000000"
    const comit_NONE = "0x636f6d69745f4e4f4e4500000000000000000000000000000000000000000000";
    const comit_TWOWEEKS = "0x636f6d69745f54574f5745454b53000000000000000000000000000000000000";
    const comit_ONEMONTH = "0x636f6d69745f4f4e454d4f4e5448000000000000000000000000000000000000";
    const comit_THREEMONTHS = "0x636f6d69745f54485245454d4f4e544853000000000000000000000000000000";

    before(async function () {
        accounts = await ethers.getSigners()
        contractOwner = accounts[0]

        diamondAddress = await deployDiamond()
        await deployOpenFacets(diamondAddress)
        await addMarkets(diamondAddress)

        diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)

        tokenList = await ethers.getContractAt('TokenList', diamondAddress)
        comptroller = await ethers.getContractAt('Comptroller', diamondAddress)
        deposit = await ethers.getContractAt("Deposit", diamondAddress)
        library = await ethers.getContractAt('LibDiamond', diamondAddress)
        
        const Mock = await ethers.getContractFactory('MockBep20')
        bep20 = await Mock.deploy()
        await bep20.deployed()

        tusdt = await ethers.getContractAt('tUSDT', '0xaBB5e17e3B1e2fc1F7a5F28E336B8130158e4E2c')

    })

    // it('should have three facets -- call to facetAddresses function', async () => {
    //     for (const address of await diamondLoupeFacet.facetAddresses()) {
    //         addresses.push(address)
    //     }
    //     assert.equal(addresses.length, 11)
    // })

    // it('facets should have the right function selectors -- call to facetFunctionSelectors function', async () => {
    //     let selectors = getSelectors(diamondCutFacet)
    //     result = await diamondLoupeFacet.facetFunctionSelectors(addresses[0])
    //     assert.sameMembers(result, selectors)
    //     selectors = getSelectors(diamondLoupeFacet)
    //     result = await diamondLoupeFacet.facetFunctionSelectors(addresses[1])
    //     assert.sameMembers(result, selectors)
    // })

    it("Add token to tokenList", async () => {
        await expect(tokenList.connect(contractOwner).addMarketSupport(
            symbolUsdt, 
            18, 
            bep20.address, 
            1,
            {gasLimit: 250000}
        )).to.emit(library, "MarketSupportAdded")
        expect(await tokenList.isMarketSupported(symbolUsdt)).to.be.equal(true);
    })

    it("Initialize", async () => {
        await comptroller.connect(contractOwner).setCommitment(comit_NONE);
        await comptroller.connect(contractOwner).setCommitment(comit_TWOWEEKS);
        await comptroller.connect(contractOwner).setCommitment(comit_ONEMONTH);
        await comptroller.connect(contractOwner).setCommitment(comit_THREEMONTHS);
        
        await comptroller.connect(contractOwner).updateAPY(comit_NONE, 15);
        await comptroller.connect(contractOwner).updateAPY(comit_TWOWEEKS, 15);
        await comptroller.connect(contractOwner).updateAPY(comit_ONEMONTH, 18);
        await comptroller.connect(contractOwner).updateAPY(comit_THREEMONTHS, 18);
    })

    it("Token Mint to Deposit", async () => {
        // console.log("Before deposit balance is ", await bep20.balanceOf(deposit.address));
        expect(await bep20.balanceOf(deposit.address)).to.be.equal(0);
        await expect(bep20.transfer(deposit.address, 1000000000000000)).to.emit(bep20, 'Transfer');
        expect(await bep20.balanceOf(deposit.address)).to.equal(1000000000000000);
        // await bep20.transfer(contractOwner.address, 10000000000000);
    })

    // it("Check is market support", async () => {
    //     expect (await tokenList.isMarketSupported(symbolOne)).to.equal(true)
    //     expect (await tokenList.isMarketSupported(symbolUsdt)).to.equal(true)

    //     console.log("deposit balance is", await tusdt.balanceOf(deposit.address))
    // })

    it("Check createDeposit", async () => {
        const depositAmount = 300;
        
        // await expect(deposit.connect(contractOwner).createDeposit(symbolUsdt, comit_TWOWEEKS, depositAmount, {gasLimit: 5000000}))
        // .to.emit(deposit, "NewDeposit")

        console.log("Before deposit balance is ", await bep20.balanceOf(deposit.address));


        await expect(deposit.connect(contractOwner).createDeposit(symbolUsdt, comit_NONE, depositAmount, {gasLimit: 5000000}))
        .to.emit(library, "NewDeposit")

        const reserve = await deposit.avblReservesDeposit(symbolUsdt);
        console.log("Reserve amount is ", reserve)
    }) 

    it("Check is created", async () => {
        expect(await deposit.hasDeposit(symbolUsdt, comit_NONE)).to.equal(true)
    })

    it("withdrawDeposit", async () => {
        console.log(await bep20.balanceOf(contractOwner.address))
        await deposit.connect(contractOwner).withdrawDeposit(symbolUsdt, comit_NONE, 150, 0)
        console.log(await bep20.balanceOf(contractOwner.address))
    })

    it("Check addToDeposit", async () => {
        await expect(deposit.connect(contractOwner).addToDeposit(symbolUsdt, comit_NONE, 400, {gasLimit: 3000000}))
        .to.emit(library, "DepositAdded");
    })
})
