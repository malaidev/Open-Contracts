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

describe("===== Deposit Test =====", function () {
    let diamondAddress
	let diamondCutFacet
	let diamondLoupeFacet
	let tokenList
	let comptroller
	let deposit
	let oracle
	let library
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

    it("Token Mint", async () => {
		// expect(await bepUsdt.balanceOf(deposit.address)).to.be.equal(0);
		await bepUsdt.mint(1000000000000000)
		await expect(bepUsdt.transfer(contractOwner.address, 1000000000000000)).to.emit(bepUsdt, 'Transfer');
		await expect(bepUsdt.transfer(accounts[1].address, 1000000000000000)).to.emit(bepUsdt, 'Transfer');
		console.log("account1 balance is ", await bepUsdt.balanceOf(accounts[1].address));
		// await bepUsdt.transfer(contractOwner.address, 10000000000000);
	})

    // // it("Check is market support", async () => {
    // //     expect (await tokenList.isMarketSupported(symbolOne)).to.equal(true)
    // //     expect (await tokenList.isMarketSupported(symbolUsdt)).to.equal(true)

    // //     console.log("deposit balance is", await tusdt.balanceOf(deposit.address))
    // // })

    // it("Check createDeposit", async () => {
    //     const depositAmount = 300;
        
    //     // await expect(deposit.connect(contractOwner).createDeposit(symbolUsdt, comit_TWOWEEKS, depositAmount, {gasLimit: 5000000}))
    //     // .to.emit(deposit, "NewDeposit")

    //     console.log("Before deposit balance is ", await bep20.balanceOf(deposit.address));


    //     await expect(deposit.connect(contractOwner).createDeposit(symbolUsdt, comit_NONE, depositAmount, {gasLimit: 5000000}))
    //     .to.emit(library, "NewDeposit")

    //     const reserve = await deposit.avblReservesDeposit(symbolUsdt);
    //     console.log("Reserve amount is ", reserve)
    // }) 

    // it("Check is created", async () => {
    //     expect(await deposit.hasDeposit(symbolUsdt, comit_NONE)).to.equal(true)
    // })

    // it("withdrawDeposit", async () => {
    //     console.log(await bep20.balanceOf(contractOwner.address))
    //     await deposit.connect(contractOwner).withdrawDeposit(symbolUsdt, comit_NONE, 150, 0)
    //     console.log(await bep20.balanceOf(contractOwner.address))
    // })

    // it("Check addToDeposit", async () => {
    //     await expect(deposit.connect(contractOwner).addToDeposit(symbolUsdt, comit_NONE, 400, {gasLimit: 3000000}))
    //     .to.emit(library, "DepositAdded");
    // })
})
