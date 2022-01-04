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

const {deployDiamond}= require('../scripts/deploy_all.js')
const {deployOpenFacets}= require('../scripts/deploy_all.js')
const {addMarkets}= require('../scripts/deploy_all.js')

describe("===== Loan Test =====", function () {
    let diamondAddress
    let diamondCutFacet
    let diamondLoupeFacet
    let tokenList
    let comptroller
    let deposit
    let loan
    let oracle
    let library
    let loan1
    let liquidator
    let bepUsdt
    let bepUsdc
    let bepBtc
    let accounts
    let contractOwner
    const addresses = []

    const symbolUsdt = "0x555344542e740000000000000000000000000000000000000000000000000000";
    const symbolBtc = "0x4254432e74000000000000000000000000000000000000000000000000000000";
    const symbolUsdc = "0x555344432e740000000000000000000000000000000000000000000000000000";
    const comit_NONE = utils.formatBytes32String("comit_NONE");
    const comit_TWOWEEKS = utils.formatBytes32String("comit_TWOWEEKS");
    const comit_ONEMONTH = utils.formatBytes32String("comit_ONEMONTH");
    const comit_THREEMONTHS = utils.formatBytes32String("comit_THREEMONTHS");

    before(async function () {
        accounts = await ethers.getSigners()
        contractOwner = accounts[0]
       
        diamondAddress = await deployDiamond()
        await deployOpenFacets(diamondAddress)
        await addMarkets(diamondAddress)

        diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
        library = await ethers.getContractAt('LibDiamond', diamondAddress)

        tokenList = await ethers.getContractAt('TokenList', diamondAddress)
        comptroller = await ethers.getContractAt('Comptroller', diamondAddress)
        deposit = await ethers.getContractAt("Deposit", diamondAddress)
        loan = await ethers.getContractAt('Loan', diamondAddress)
        loan1 = await ethers.getContractAt('Loan1', diamondAddress)
        oracle = await ethers.getContractAt('OracleOpen', diamondAddress)
        liquidator = await ethers.getContractAt('Liquidator', diamondAddress)

        const Mock = await ethers.getContractFactory('MockBep20')
        bepUsdt = await Mock.deploy()
        await bepUsdt.deployed()
        bepBtc = await Mock.deploy()
        await bepBtc.deployed()
        bepUsdc = await Mock.deploy()
        await bepUsdc.deployed()
    })

    it("Check diamond deploy", async () => {
        console.log("accounts length ", accounts.length)

        console.log("bepUsdt is ", bepUsdt.address)
        console.log("bepUsdc is ", bepUsdc.address)
        console.log("bepBtc is ", bepBtc.address)
    })

    it("Add token to tokenList", async () => {
        await expect(tokenList.connect(contractOwner).addMarketSupport(
            symbolUsdt, 
            18, 
            bepUsdt.address, 
            1,
            {gasLimit: 250000}
        )).to.emit(library, "MarketSupportAdded")
        expect(await tokenList.connect(contractOwner).isMarketSupported(symbolUsdt)).to.be.equal(true);

        await expect(tokenList.connect(contractOwner).addMarketSupport(
            symbolUsdc, 
            18, 
            bepUsdc.address, 
            1,
            {gasLimit: 250000}
        )).to.emit(library, "MarketSupportAdded")
        
        await expect(tokenList.connect(contractOwner).addMarket2Support(
            symbolBtc, 
            8, 
            bepBtc.address, 
            {gasLimit: 250000}
        )).to.emit(library, "Market2Added")
        expect(await tokenList.connect(contractOwner).isMarket2Supported(symbolBtc)).to.be.equal(true);

        await expect(tokenList.connect(contractOwner).addMarket2Support(
            symbolUsdt, 
            18, 
            bepUsdt.address, 
            {gasLimit: 250000}
        )).to.emit(library, "Market2Added")

        await expect(tokenList.connect(contractOwner).addMarket2Support(
            symbolUsdc, 
            18, 
            bepUsdc.address, 
            {gasLimit: 250000}
        )).to.emit(library, "Market2Added")

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

    it("Token Mint to Deposit", async () => {
        console.log("owner balance is ", await bepUsdt.balanceOf(contractOwner.address));
        console.log("Account1 balance is ", await bepUsdt.balanceOf(contractOwner.address));
        // expect(await bepUsdt.balanceOf(deposit.address)).to.be.equal(0);
        await expect(bepUsdt.transfer(contractOwner.address, 1000000000000000)).to.emit(bepUsdt, 'Transfer');
        await expect(bepUsdt.transfer(accounts[1].address, 1000000000000000)).to.emit(bepUsdt, 'Transfer');
        // expect(await bepUsdt.balanceOf(deposit.address)).to.equal(1000000000000000);
        // await bepUsdt.transfer(contractOwner.address, 10000000000000);
    })

    it("Check is market support", async () => {
        expect (await tokenList.isMarketSupported(symbolUsdt)).to.equal(true)
    })

    it("Check createDeposit", async () => {
        const depositAmount = 200;

        await expect(deposit.connect(accounts[1]).createDeposit(symbolUsdt, comit_ONEMONTH, depositAmount, {gasLimit: 5000000}))
        .to.emit(library, "NewDeposit")

        const reserve = await deposit.avblReservesDeposit(symbolUsdt);
        // console.log("Reserve amount is ", reserve)

        // await expect(deposit.connect(contractOwner).createDeposit(symbolUsdt, comit_ONEMONTH, depositAmount, {gasLimit: 5000000}))
        // .to.emit(library, "NewDeposit")

        let eventFilter = library.filters.NewDeposit;
        let events = await library.queryFilter(eventFilter, "latest");
        console.log(events);
    })

    it("Check borrow", async () => {
        await expect(loan1.connect(accounts[1]).loanRequest(symbolUsdt, comit_ONEMONTH, 100, symbolUsdt, 50, {gasLimit: 5000000}))
            .to.emit(library, "NewLoan");
    })

    // it("Check addCollateral", async () => {
    //     await expect(loan1.connect(accounts[1]).addCollateral(symbolUsdt, comit_ONEMONTH, symbolUsdt, 20, {gasLimit: 5000000}))
    //         .to.emit(library, "AddCollateral")
    // })

    // it("LatestPrice", async () => {
    //     const price = await oracle.connect(contractOwner).getLatestPrice(symbolBtc, {gasLimit: 5000000});
    //     console.log("Btc Price is ", price);
    // })

    // it("Swap", async () => {
    //     const tx = await liquidator.connect(contractOwner).swap(symbolBtc, symbolUsdt, 100, 0, {
    //         'gasLimit': 300000,
    //         'gasPrice': ethers.utils.parseUnits('185', 'gwei'),
    //     });
    //     // await tx.wait();
    //     console.log(tx);
    // //     let eventFilter = library.filters.Swapped;
    // //     let events = await library.queryFilter(eventFilter, "latest");
    // //     console.log(events);
    // })

    // it("Swap Loan", async () => {
    //     await expect(loan.connect(accounts[1]).swapLoan(symbolUsdt, comit_ONEMONTH, symbolUsdc, {gasLimit: 5000000}))
    //         .to.emit(library, "SwapTestAmount");
        
    //     let eventFilter = library.filters.SwapTestAmount;
    //     let events = await library.queryFilter(eventFilter, "latest");
    //     console.log(events);
    // })


    // it("Check repayLoan", async () => {
    //     await (loan.connect(accounts[1]).repayLoan(symbolUsdt, comit_ONEMONTH, 30, {gasLimit: 5000000}));
    // })

})