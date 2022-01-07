const { expect } = require("chai");
const { ethers } = require("hardhat");
const utils = require('ethers').utils
const { BigNumber } = require( "bignumber.js");
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

describe("===== Comptroller Test =====", function () {
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
	let accounts
	let contractOwner
	let bepUsdt
	let bepBtc
	let bepUsdc

	let rets
	const addresses = []

	const symbolWBNB = "0x57424e4200000000000000000000000000000000000000000000000000000000"; // WBNB
	const symbolUsdt = "0x555344542e740000000000000000000000000000000000000000000000000000"; // USDT.t
	const symbolUsdc = "0x555344432e740000000000000000000000000000000000000000000000000000"; // USDC.t
	const symbolBtc = "0x4254432e74000000000000000000000000000000000000000000000000000000"; // BTC.t
	const symbolEth = "0x4554480000000000000000000000000000000000000000000000000000000000";
	const symbolSxp = "0x5358500000000000000000000000000000000000000000000000000000000000"; // SXP
	const symbolCAKE = "0x43414b4500000000000000000000000000000000000000000000000000000000"; // CAKE
	
	const comit_NONE = utils.formatBytes32String("comit_NONE");
	const comit_TWOWEEKS = utils.formatBytes32String("comit_TWOWEEKS");
	const comit_ONEMONTH = utils.formatBytes32String("comit_ONEMONTH");
	const comit_THREEMONTHS = utils.formatBytes32String("comit_THREEMONTHS");

    before(async function () {
        accounts = await ethers.getSigners()
		contractOwner = accounts[0]
		console.log("account1 is ", accounts[1].address)
		
		diamondAddress = await deployDiamond()
		await deployOpenFacets(diamondAddress)
		rets = await addMarkets(diamondAddress)

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

		bepUsdt = await ethers.getContractAt('tUSDT', rets['tUsdtAddress'])
		bepBtc = await ethers.getContractAt('tBTC', rets['tBtcAddress'])
		bepUsdc = await ethers.getContractAt('tUSDC', rets['tUsdcAddress'])
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

    it("Check APY Set Status by deploy script", async() => {
        expect(await comptroller.getAPY(comit_NONE)).to.be.equal(6);
        expect(await comptroller.getAPY(comit_TWOWEEKS)).to.be.equal(16);
        expect(await comptroller.getAPY(comit_ONEMONTH)).to.be.equal(13);
        expect(await comptroller.getAPY(comit_THREEMONTHS)).to.be.equal(10);
    })

    it("Check APR Set Status by deploy script", async () => {
        expect(await comptroller.getAPR(comit_NONE)).to.be.equal(15);
        expect(await comptroller.getAPR(comit_TWOWEEKS)).to.be.equal(15);
        expect(await comptroller.getAPR(comit_ONEMONTH)).to.be.equal(18);
        expect(await comptroller.getAPR(comit_THREEMONTHS)).to.be.equal(18);
    })

    it("Check getApytime empty at big index", async () => {
        await expect(comptroller.getApytime(comit_TWOWEEKS, 22)).to.be.reverted;
    })

    it("Check getApyLastTime", async () => {
        expect(await comptroller.getApyLastTime(comit_TWOWEEKS)).to.not.equal(0)
    })

    it("Calc APY", async () => {
        let oldLenAccruedInterest = 1;
        let oldTime = 0;
        let aggregateInterest = 0;

        await comptroller.connect(contractOwner).updateAPY(comit_TWOWEEKS, 55, {gasLimit: 250000});
        console.log("Before: LenIntereset = ", oldLenAccruedInterest, " oldTime = ", oldTime, " aggregateIntereset = ", aggregateInterest);
        const rets = await comptroller.calcAPY(comit_NONE, oldLenAccruedInterest, oldTime, aggregateInterest);
        console.log("After: LenIntereset = ", rets[0], " oldTime = ", rets[1], " aggregateIntereset = ", rets[2]);
    })

    it("Calc APR", async () => {
        let oldLenAccruedInterest = 1;
        let oldTime = 0;
        let aggregateInterest = 0;

        await comptroller.connect(contractOwner).updateAPR(comit_TWOWEEKS, 55, {gasLimit: 250000});
        console.log("Before: LenIntereset = ", oldLenAccruedInterest, " oldTime = ", oldTime, " aggregateIntereset = ", aggregateInterest);
        await comptroller.calcAPR(comit_NONE, oldLenAccruedInterest, oldTime, aggregateInterest);
        console.log("After: LenIntereset = ", oldLenAccruedInterest, " oldTime = ", oldTime, " aggregateIntereset = ", aggregateInterest);
    })

    // it("updateLoanIssuanceFees", async () => {
    //     await expect(comptroller.connect(contractOwner).updateLoanIssuanceFees(23, {gasLimit: 250000})).to.emit(comptroller, "LoanIssuanceFeesUpdated");
    // });

    // it("updateLoanClosureFees", async () => {
    //     await expect(comptroller.connect(contractOwner).updateLoanClosureFees(33, {gasLimit: 250000})).to.emit(comptroller, "LoanClosureFeesUpdated");
    // });

    // it("updateLoanPreClosureFees", async () => {
    //     await expect(comptroller.connect(contractOwner).updateLoanPreClosureFees(543, {gasLimit: 250000})).to.emit(comptroller, "LoanPreClosureFeesUpdated");
    // });

    // it("updateDepositPreclosureFees", async () => {
    //     await expect(comptroller.connect(contractOwner).updateDepositPreclosureFees(44, {gasLimit: 250000})).to.emit(comptroller, "DepositPreClosureFeesUpdated");
    //     expect(await comptroller.depositPreClosureFees()).to.be.equal(44);
    // });
    
    // it("updateWithdrawalFees", async () => {
    //     await expect(comptroller.connect(contractOwner).updateWithdrawalFees(2, {gasLimit: 250000})).to.emit(comptroller, "DepositWithdrawalFeesUpdated");
    //     expect(await comptroller.depositWithdrawalFees()).to.be.equal(2);
    // });

    // it("updateCollateralReleaseFees", async () => {
    //     await expect(comptroller.connect(contractOwner).updateCollateralReleaseFees(55, {gasLimit: 250000})).to.emit(comptroller, "CollateralReleaseFeesUpdated");
    //     expect(await comptroller.collateralReleaseFees()).to.be.equal(55);
    // });

    // it("updateYieldConversion", async () => {
    //     await expect(comptroller.connect(contractOwner).updateYieldConversion(56, {gasLimit: 250000})).to.emit(comptroller, "YieldConversionFeesUpdated");
    // });

    // it("updateMarketSwapFees", async () => {
    //     await expect(comptroller.connect(contractOwner).updateMarketSwapFees(3, {gasLimit: 250000})).to.emit(comptroller, "MarketSwapFeesUpdated");
    // });

    // it("updateReserveFactor", async () => {
    //     await expect(comptroller.connect(contractOwner).updateReserveFactor(23, {gasLimit: 250000})).to.emit(comptroller, "ReserveFactorUpdated");
    // });

    // it("updateMaxWithdrawal", async () => {
    //     await expect(comptroller.connect(contractOwner).updateMaxWithdrawal(6, 444, {gasLimit: 250000})).to.emit(comptroller, "MaxWithdrawalUpdated");
    // });
})
