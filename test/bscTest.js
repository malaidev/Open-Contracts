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
	let bepCake
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
		upgradeAdmin = accounts[0]
		console.log("account1 is ", accounts[1].address)
		
		diamondAddress = "0x5fc9bDf31BaEe0708077bcD4BA8d1D2468615a8f"

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

		bepUsdc = await ethers.getContractAt('BEP20Token', "0xAeFAF5361cB4Ef012143A11609da3C8a9CC67367")
        bepCake = await ethers.getContractAt('BEP20Token', "0x30fe514A19Ec5BB144f2f6C96C385ea3ff2EBEF3")
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

    it("getlatestprice", async () => {
        console.log("cake price is ", await oracle.getLatestPrice(symbolCAKE), {gasLimit: 5000000})
    })

    it("Check Deposit", async () => {
        const depositAmount = "500000000000000000000";

        console.log(diamondAddress, "USDC balance is ", await bepUsdc.balanceOf(diamondAddress))
        console.log(accounts[1].address, "USDC balance is ", await bepUsdc.balanceOf(accounts[1].address))
        console.log("Avbl Market reserve is ", await reserve.avblMarketReserves(symbolUsdc))
        // USDC
        await bepUsdc.connect(accounts[1]).approve(diamondAddress, depositAmount);
        await deposit.connect(accounts[1]).depositRequest(symbolUsdc, comit_NONE, depositAmount, {gasLimit: 5000000})
        // expect(await bepUsdc.balanceOf(accounts[1].address)).to.equal(0xfe00)
        // expect(await reserve.avblMarketReserves(symbolUsdc)).to.equal(0x200)
        console.log(diamondAddress, "USDC balance is ", await bepUsdc.balanceOf(diamondAddress))
        console.log(accounts[1].address, "USDC balance is ", await bepUsdc.balanceOf(accounts[1].address))
        console.log("Avbl Market reserve is ", await reserve.avblMarketReserves(symbolUsdc))
    })

    it("Check loan", async () => {
        const loanAmount = "300000000000000000000"
        const collateralAmount = "200000000000000000000"
        console.log(accounts[1].address, "USDC balance is ", await bepUsdc.balanceOf(accounts[1].address))
        console.log("Avbl Market reserve is ", await reserve.avblMarketReserves(symbolUsdc))
        await bepUsdc.connect(accounts[1]).approve(diamondAddress, loanAmount);
        await loanExt.connect(accounts[1]).loanRequest(symbolUsdc, comit_ONEMONTH, loanAmount, symbolUsdc, collateralAmount, {gasLimit: 5000000})

        console.log(accounts[1].address, "USDC balance is ", await bepUsdc.balanceOf(accounts[1].address))
        console.log("Avbl Market reserve is ", await reserve.avblMarketReserves(symbolUsdc))
    })

    it("Swap", async () => {
        const loanAmount = "300000000000000000000"
        console.log(accounts[1].address, "USDC balance is ", await bepUsdc.balanceOf(accounts[1].address))
        console.log(accounts[1].address, "CAKE balance is ", await bepCake.balanceOf(accounts[1].address))
        
        await bepUsdc.connect(accounts[1]).approve(diamondAddress, loanAmount);
        await bepCake.connect(accounts[1]).approve(diamondAddress, loanAmount);
        await loan.connect(accounts[1]).swapLoan(symbolUsdc, comit_ONEMONTH, symbolCAKE, {gasLimit: 5000000,})

        console.log(accounts[1].address, "USDC balance is ", await bepUsdc.balanceOf(accounts[1].address))
        console.log(accounts[1].address, "CAKE balance is ", await bepCake.balanceOf(accounts[1].address))

    })

    // it("SwapToLoan", async () => {
    //     const loanAmount = "300000000000000000000"
    //     console.log(accounts[1].address, "USDC balance is ", await bepUsdc.balanceOf(accounts[1].address))
    //     console.log(accounts[1].address, "CAKE balance is ", await bepCake.balanceOf(accounts[1].address))

    //     await bepUsdc.connect(accounts[1]).approve(diamondAddress, loanAmount);
    //     await bepCake.connect(accounts[1]).approve(diamondAddress, loanAmount);
    //     await loan.connect(accounts[1]).swapToLoan(symbolCAKE, comit_ONEMONTH, symbolUsdc, {gasLimit: 5000000,})

    //     console.log(accounts[1].address, "USDC balance is ", await bepUsdc.balanceOf(accounts[1].address))
    //     console.log(accounts[1].address, "CAKE balance is ", await bepCake.balanceOf(accounts[1].address))

    // })
   
    it("Check liquidation1", async () => {
        const loanAmount = "300000000000000000000"
        await bepUsdc.connect(accounts[1]).approve(diamondAddress, loanAmount);
        await loanExt.connect(upgradeAdmin).liquidation(accounts[1].address, 1);
    })
})
