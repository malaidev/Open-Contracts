const { expect } = require("chai");
const { ethers } = require("hardhat");
const utils = require('ethers').utils
const {
    getSelectors,
    get,
    FacetCutAction,
    removeSelectors,
    findAddressPositionInFacets
    } = require('../scripts/libraries/diamond.js')
  
const { assert } = require('chai')

const {deployDiamond}= require('../scripts/1_deploy_diamond.js')
const {deployFacets} = require("../scripts/2_deploy_facets.js")

describe("===== Loan Test =====", function () {
    let diamondAddress
    let diamondCutFacet
    let diamondLoupeFacet
    let tokenList
    let comptroller
    let deposit
    let loan
    let loan1
    let bepUsdt
    let accounts
    let contractOwner
    const addresses = []

    const symbolUsdt = "0x555344542e740000000000000000000000000000000000000000000000000000";
    const comit_NONE = utils.formatBytes32String("comit_NONE");
    const comit_TWOWEEKS = utils.formatBytes32String("comit_TWOWEEKS");
    const comit_ONEMONTH = utils.formatBytes32String("comit_ONEMONTH");
    const comit_THREEMONTHS = utils.formatBytes32String("comit_THREEMONTHS");

    before(async function () {
        accounts = await ethers.getSigners()
        contractOwner = accounts[0]
        // diamondAddress = '0x1f2523fCb78c739Ed60460f9Bc9845a622771710'
        diamondAddress = await deployDiamond()
        await deployFacets(diamondAddress)

        diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)

        tokenList = await ethers.getContractAt('TokenList', diamondAddress)
        comptroller = await ethers.getContractAt('Comptroller', diamondAddress)
        deposit = await ethers.getContractAt("Deposit", diamondAddress)
        loan = await ethers.getContractAt('Loan', diamondAddress)
        loan1 = await ethers.getContractAt('Loan1', diamondAddress)

        const Mock = await ethers.getContractFactory('MockBep20')
        bepUsdt = await Mock.deploy()
        await bepUsdt.deployed()
    })

    it("Add token to tokenList", async () => {
        await expect(tokenList.connect(contractOwner).addMarketSupport(
            symbolUsdt, 
            18, 
            bepUsdt.address, 
            1,
            {gasLimit: 250000}
        )).to.emit(tokenList, "MarketSupportAdded")
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

        await comptroller.connect(contractOwner).updateAPR(comit_NONE, 15);
        await comptroller.connect(contractOwner).updateAPR(comit_TWOWEEKS, 15);
        await comptroller.connect(contractOwner).updateAPR(comit_ONEMONTH, 18);
        await comptroller.connect(contractOwner).updateAPR(comit_THREEMONTHS, 18);
    })


    // it("Token Mint to Deposit", async () => {
    //     // console.log("Before deposit balance is ", await bepUsdt.balanceOf(deposit.address));
    //     expect(await bepUsdt.balanceOf(deposit.address)).to.be.equal(0);
    //     await expect(bepUsdt.transfer(deposit.address, 1000000000000000)).to.emit(bepUsdt, 'Transfer');
    //     expect(await bepUsdt.balanceOf(deposit.address)).to.equal(1000000000000000);
    //     // await bepUsdt.transfer(contractOwner.address, 10000000000000);
    // })

    it("Check is market support", async () => {
        expect (await tokenList.isMarketSupported(symbolUsdt)).to.equal(true)
    })

    it("Check createDeposit", async () => {
        const depositAmount = 200;

        await expect(deposit.connect(contractOwner).createDeposit(symbolUsdt, comit_TWOWEEKS, depositAmount, {gasLimit: 5000000}))
        .to.emit(deposit, "NewDeposit")

        const reserve = await deposit.avblReservesDeposit(symbolUsdt);
        console.log("Reserve amount is ", reserve)

        await expect(deposit.connect(contractOwner).createDeposit(symbolUsdt, comit_TWOWEEKS, depositAmount, {gasLimit: 5000000}))
        .to.emit(deposit, "NewDeposit")
    })

    it("Check borrow", async () => {
        await expect(loan1.loanRequest(symbolUsdt, comit_ONEMONTH, 53, symbolUsdt, 18))
            .to.emit(loan1, "CollCount");
        // await expect(loan1.loanRequest(symbolUsdt, comit_NONE, 53, symbolUsdt, 18))
        //     .to.emit(loan1, "CollCount");
    })

    it("Check addCollateral", async () => {
        await expect(loan1.addCollateral(symbolUsdt, comit_ONEMONTH, symbolUsdt, 20))
            .to.emit(loan1, "CollCount")
    })

    it("Check repayLoan", async () => {
        await (loan.repayLoan(symbolUsdt, comit_ONEMONTH, 0));

    })
})
