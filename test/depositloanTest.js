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
const {addMarkets}= require('../scripts/deploy_all.js')

describe(" Complex Test ", function () {
    let diamondAddress
	let diamondCutFacet
	let diamondLoupeFacet
	let tokenList
	let comptroller
	let deposit
    let loan
    let loanExt
	let oracle
    let reserve
	let library
	let liquidator
	let accounts
	let upgradeAdmin
	let bepUsdt
	let bepBtc
	let bepUsdc
    let bepCake

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
		upgradeAdmin = accounts[0]
		console.log("account1 is ", accounts[1].address)
		
		diamondAddress = await deployDiamond()
		rets = await addMarkets(diamondAddress)

		diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
		diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
		library = await ethers.getContractAt('LibOpen', diamondAddress)

		tokenList = await ethers.getContractAt('TokenList', diamondAddress)
		comptroller = await ethers.getContractAt('Comptroller', diamondAddress)
		deposit = await ethers.getContractAt("Deposit", diamondAddress)
		loan = await ethers.getContractAt("Loan", diamondAddress)
		loanExt = await ethers.getContractAt("LoanExt", diamondAddress)
		oracle = await ethers.getContractAt('OracleOpen', diamondAddress)
		liquidator = await ethers.getContractAt('Liquidator', diamondAddress)
		reserve = await ethers.getContractAt('Reserve', diamondAddress)

		bepUsdt = await ethers.getContractAt('BEP20Token', rets['tUsdtAddress'])
		bepBtc = await ethers.getContractAt('BEP20Token', rets['tBtcAddress'])
		bepUsdc = await ethers.getContractAt('BEP20Token', rets['tUsdcAddress'])
        bepWbnb = await ethers.getContractAt('BEP20Token', rets['tUsdcAddress'])
        bepCake = await ethers.getContractAt('BEP20Token', rets['tCakeAddress'])
	})

    it('should have three facets -- call to facetAddresses function', async () => {
        for (const address of await diamondLoupeFacet.facetAddresses()) {
            addresses.push(address)
        }
        assert.equal(addresses.length, 10)
    })

    it('facets should have the right function selectors -- call to facetFunctionSelectors function', async () => {
        let selectors = getSelectors(diamondCutFacet)
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[0])
        assert.sameMembers(result, selectors)
        selectors = getSelectors(diamondLoupeFacet)
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[1])
        assert.sameMembers(result, selectors)
    })

    it("Token Mint", async () => {
        console.log("Reserve balance is ", await bepUsdt.balanceOf(diamondAddress));
		// expect(await bepUsdt.balanceOf(deposit.address)).to.be.equal(0);
		await expect(bepUsdt.transfer(upgradeAdmin.address, "500000000000000000000000")).to.emit(bepUsdt, 'Transfer');
		await expect(bepUsdt.transfer(accounts[1].address, "500000000000000000000000")).to.emit(bepUsdt, 'Transfer');
		await expect(bepUsdc.transfer(accounts[1].address, "500000000000000000000000")).to.emit(bepUsdc, 'Transfer');
		await expect(bepBtc.transfer(accounts[1].address, "500000000000")).to.emit(bepBtc, 'Transfer');
		await expect(bepBtc.transfer(diamondAddress, "500000000000")).to.emit(bepBtc, 'Transfer');
		await expect(bepUsdt.transfer(diamondAddress, "500000000000000000000000")).to.emit(bepUsdt, 'Transfer');
		await expect(bepUsdc.transfer(diamondAddress, "500000000000000000000000")).to.emit(bepUsdc, 'Transfer');

		// await bepUsdt.transfer(upgradeAdmin.address, 10000000000000);
	})

    // // it("Check is market support", async () => {
    // //     expect (await tokenList.isMarketSupported(symbolOne)).to.equal(true)
    // //     expect (await tokenList.isMarketSupported(symbolUsdt)).to.equal(true)

    // //     console.log("deposit balance is", await tusdt.balanceOf(deposit.address))
    // // })

    it("Check Deposit", async () => {
        const depositAmount = "5000000000000000000000";

        // USDT

        await bepUsdt.connect(accounts[1]).approve(diamondAddress, depositAmount);
        console.log("Approve before deposit is ", await bepUsdt.allowance(accounts[1].address, diamondAddress));

        await expect(deposit.connect(accounts[1]).depositRequest(symbolUsdt, comit_NONE, depositAmount, {gasLimit: 5000000}))
            .emit(deposit, "NewDeposit")
        // expect(await bepUsdt.balanceOf(accounts[1].address)).to.equal(0xfe00)
        // expect(await reserve.avblMarketReserves(symbolUsdt)).to.equal(0x200)
        console.log("Reserve balance is ", await bepUsdt.balanceOf(diamondAddress));

        await bepUsdt.connect(accounts[1]).approve(diamondAddress, depositAmount);
        await expect(deposit.connect(accounts[1]).depositRequest(symbolUsdt, comit_NONE, depositAmount, {gasLimit: 5000000}))
            .emit(deposit, "DepositAdded")
        // expect(await bepUsdt.balanceOf(accounts[1].address)).to.equal(0xfc00)
        // expect(await reserve.avblMarketReserves(symbolUsdt)).to.equal(0x400)

        // USDC
        await bepUsdc.connect(accounts[1]).approve(diamondAddress, depositAmount);
        await expect(deposit.connect(accounts[1]).depositRequest(symbolUsdc, comit_NONE, depositAmount, {gasLimit: 5000000}))
            .emit(deposit, "NewDeposit")
        // expect(await bepUsdc.balanceOf(accounts[1].address)).to.equal(0xfe00)
        // expect(await reserve.avblMarketReserves(symbolUsdc)).to.equal(0x200)

        await bepUsdc.connect(accounts[1]).approve(diamondAddress, depositAmount);
        await expect(deposit.connect(accounts[1]).depositRequest(symbolUsdc, comit_NONE, depositAmount, {gasLimit: 5000000}))
            .emit(deposit, "DepositAdded")
        // expect(await bepUsdc.balanceOf(accounts[1].address)).to.equal(0xfc00)
        // expect(await reserve.avblMarketReserves(symbolUsdc)).to.equal(0x400)

    })

    // it("Check withdraw", async () => {
    //     await deposit.connect(accounts[1]).withdrawDeposit(symbolUsdt, comit_NONE, 0x100, 0)
    //     // expect(await bepUsdt.balanceOf(accounts[1].address)).to.equal(0xfd00)
    //     // expect(await reserve.avblMarketReserves(symbolUsdt)).to.equal(0x300)
    // })

    it("Check loan", async () => {
        const loanAmount = "300000000000000000000";
        const collateralAmount = "200000000000000000000"
        await bepUsdc.connect(accounts[1]).approve(diamondAddress, loanAmount);
        await expect(loanExt.connect(accounts[1]).loanRequest(symbolUsdc, comit_ONEMONTH, loanAmount, symbolUsdc, collateralAmount, {gasLimit: 5000000}))
			.to.emit(loanExt, "NewLoan");

        // expect(await bepUsdt.balanceOf(accounts[1].address)).to.equal(0xfc00)
        // expect(await reserve.avblMarketReserves(symbolUsdt)).to.equal(0x200)

        // expect(await bepBtc.balanceOf(accounts[1].address)).to.equal(0xfb00)
        // expect(await reserve.avblMarketReserves(symbolBtc)).to.equal(0x300)
    })

    it("Swap", async () => {
        const loanAmount = "300000000000000000000"
        const collateralAmount = "200000000000000000000"
       
        await bepUsdc.connect(accounts[1]).approve(diamondAddress, loanAmount);
        await bepCake.connect(accounts[1]).approve(diamondAddress, loanAmount);
        await loan.connect(accounts[1]).swapLoan(symbolUsdc, comit_ONEMONTH, symbolCAKE, {gasLimit: 5000000,})

    })

    it("SwapToLoan", async () => {
        const loanAmount = "300000000000000000000"
        console.log(accounts[1].address, "USDC balance is ", await bepUsdc.balanceOf(accounts[1].address))
        console.log(accounts[1].address, "CAKE balance is ", await bepCake.balanceOf(accounts[1].address))

        await bepUsdc.connect(accounts[1]).approve(diamondAddress, loanAmount);
        await bepCake.connect(accounts[1]).approve(diamondAddress, loanAmount);
        await loan.connect(accounts[1]).swapToLoan(symbolCAKE, comit_ONEMONTH, symbolUsdc, {gasLimit: 5000000,})

        console.log(accounts[1].address, "USDC balance is ", await bepUsdc.balanceOf(accounts[1].address))
        console.log(accounts[1].address, "CAKE balance is ", await bepCake.balanceOf(accounts[1].address))

    })

    it("Check addCollateral", async () => {
        
        const collateralAmount = "700000000000000000000"
        await bepUsdc.connect(accounts[1]).approve(diamondAddress, collateralAmount);
        await expect(loan.connect(accounts[1]).addCollateral(symbolUsdc, comit_ONEMONTH, symbolUsdc, collateralAmount, {gasLimit: 5000000}))
            .to.emit(loan, "AddCollateral")
    })

   

    // it("Check withdrawCollateral", async () => {
    //     console.log(await bepUsdt.balanceOf(accounts[1].address))
    //     await expect(loan.connect(accounts[1]).withdrawCollateral(symbolUsdc, comit_ONEMONTH, {gasLimit: 5000000}))
    //         .emit(loan, "CollateralReleased")
    //     console.log(await bepUsdt.balanceOf(accounts[1].address))
    // })

    // it("Check repayLoan", async () => {
    //     const repayAmount = "300000000000000000000"

    //     console.log(await reserve.avblMarketReserves(symbolUsdc))
	//     await (loan.connect(accounts[1]).repayLoan(symbolUsdc, comit_ONEMONTH, repayAmount, {gasLimit: 5000000}));
    //     console.log(await reserve.avblMarketReserves(symbolUsdc))
	// })

    it("Check liquidation", async () => {
        await bepUsdt.connect(accounts[1]).approve(diamondAddress, "50000000000000000000000000");

        await loanExt.connect(upgradeAdmin).liquidation(accounts[1].address, 1);
    })
  
})
