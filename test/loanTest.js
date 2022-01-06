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

	it("Token Mint", async () => {
		// expect(await bepUsdt.balanceOf(deposit.address)).to.be.equal(0);
		await bepUsdt.mint(1000000000000000)
		await expect(bepUsdt.transfer(contractOwner.address, 1000000000000000)).to.emit(bepUsdt, 'Transfer');
		await expect(bepUsdt.transfer(accounts[1].address, 1000000000000000)).to.emit(bepUsdt, 'Transfer');
		console.log("account1 balance is ", await bepUsdt.balanceOf(accounts[1].address));
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
		
		// let eventFilter = library.filters.NewDeposit;
		// let events = await library.queryFilter(eventFilter, "latest");
		// console.log(events);
	})

	it("Check borrow", async () => {
		await expect(loan1.connect(accounts[1]).loanRequest(symbolUsdt, comit_ONEMONTH, 100, symbolUsdt, 50, {gasLimit: 5000000}))
				.to.emit(library, "NewLoan");
	})

	it("Check addCollateral", async () => {
		await expect(loan1.connect(accounts[1]).addCollateral(symbolUsdt, comit_ONEMONTH, symbolUsdt, 20, {gasLimit: 5000000}))
				.to.emit(library, "AddCollateral")
	})

	it("SwapLoan", async () => {
		await expect(loan.connect(contractOwner).swapLoan(symbolUsdt, comit_ONEMONTH, symbolUsdt, {
				'gasLimit': 300000,
				'gasPrice': ethers.utils.parseUnits('185', 'gwei'),
		})).to.reverted

		await expect(loan.connect(accounts[1]).swapLoan(symbolUsdt, comit_ONEMONTH, symbolUsdt, {
			'gasLimit': 300000,
			'gasPrice': ethers.utils.parseUnits('185', 'gwei'),
	})).to.emit(library, "MarketSwapped")
	})


	// it("Check repayLoan", async () => {
	//     await (loan.connect(accounts[1]).repayLoan(symbolUsdt, comit_ONEMONTH, 30, {gasLimit: 5000000}));
	// })

})