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

describe(" Oracle Test ", function () {
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

		diamondAddress = "0xf87B4A3eD47416De6096d1eE183e86dAbcFc8Cc8";

		tokenList = await ethers.getContractAt('TokenList', diamondAddress)
		comptroller = await ethers.getContractAt('Comptroller', diamondAddress)
		deposit = await ethers.getContractAt("Deposit", diamondAddress)
		loan = await ethers.getContractAt("Loan", diamondAddress)
		loanExt = await ethers.getContractAt("LoanExt", diamondAddress)
		oracle = await ethers.getContractAt('OracleOpen', diamondAddress)
		liquidator = await ethers.getContractAt('Liquidator', diamondAddress)
		reserve = await ethers.getContractAt('Reserve', diamondAddress)

        console.log(tokenList.address);
	})

    it("Check diamond", async () => {
        expect(await tokenList.connect(upgradeAdmin).isMarketSupported(symbolUsdt, {gasLimit: 5000000})).to.be.equal(true)
    })

    it("GetLatestPrice Check", async () => {
        let latestPrice = await oracle.getLatestPrice(symbolCAKE, {gasLimit: 5000000});
        console.log("Latest Cake Price is ", latestPrice);
    })
})
