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

describe("===== TokenList Test =====", function () {
    let diamondAddress
	let diamondCutFacet
	let diamondLoupeFacet
	let tokenList
	let library
	let accounts
	let contractOwner
	let bepUsdt
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
        diamondAddress = await deployDiamond()
        await deployOpenFacets(diamondAddress)
        const rets = await addMarkets(diamondAddress)
        diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)

        tokenList = await ethers.getContractAt('TokenList', diamondAddress)
        library = await ethers.getContractAt('LibDiamond', diamondAddress)

		bepUsdt = await ethers.getContractAt('tUSDT', rets['tUsdtAddress'])
		bepUsdc = await ethers.getContractAt('tUSDC', rets['tUsdcAddress'])
    })

    it("check deployed", async () => {
        expect(await tokenList.address).to.not.equal("0x" + "0".repeat(40))
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

    it("isMarketSupport at empty", async () => {
        expect(await tokenList.isMarketSupported(symbolUsdt)).to.be.equal(true)
    })

    it("Reset Primary market by removing markets", async () => {
        await expect(tokenList.connect(contractOwner).removeMarketSupport(symbolUsdt)).to.emit(library, "MarketSupportRemoved")
        await expect(tokenList.connect(contractOwner).removeMarketSupport(symbolUsdc)).to.emit(library, "MarketSupportRemoved")
        await expect(tokenList.connect(contractOwner).removeMarketSupport(symbolBtc)).to.emit(library, "MarketSupportRemoved")
        await expect(tokenList.connect(contractOwner).removeMarketSupport(symbolWBNB)).to.emit(library, "MarketSupportRemoved")

        await expect(tokenList.isMarketSupported(symbolUsdt)).to.be.revertedWith("ERROR: Unsupported market")
        await expect(tokenList.isMarketSupported(symbolUsdc)).to.be.revertedWith("ERROR: Unsupported market")
        await expect(tokenList.isMarketSupported(symbolBtc)).to.be.revertedWith("ERROR: Unsupported market")
        await expect(tokenList.isMarketSupported(symbolWBNB)).to.be.revertedWith("ERROR: Unsupported market")

    })

    it("Add token to tokenList", async () => {
        await expect(tokenList.connect(contractOwner).addMarketSupport(
            symbolUsdt, 
            18, 
            bepUsdt.address, 
            1,
            {gasLimit: 250000}
        )).to.emit(library, "MarketSupportAdded")
        expect(await tokenList.isMarketSupported(symbolUsdt)).to.be.equal(true);

    })

    it("Reset Secondary market by removing secondary markets", async () => {
        await expect(tokenList.connect(contractOwner).removeMarket2Support(symbolUsdt)).to.emit(library, "Market2Removed")
        await expect(tokenList.connect(contractOwner).removeMarket2Support(symbolUsdc)).to.emit(library, "Market2Removed")
        await expect(tokenList.connect(contractOwner).removeMarket2Support(symbolSxp)).to.emit(library, "Market2Removed")
        await expect(tokenList.connect(contractOwner).removeMarket2Support(symbolCAKE)).to.emit(library, "Market2Removed")

        await expect(tokenList.isMarket2Supported(symbolUsdt)).to.be.revertedWith("Secondary Token is not supported")
        await expect(tokenList.isMarket2Supported(symbolUsdc)).to.be.revertedWith("Secondary Token is not supported")
        await expect(tokenList.isMarket2Supported(symbolSxp)).to.be.revertedWith("Secondary Token is not supported")
        await expect(tokenList.isMarket2Supported(symbolCAKE)).to.be.revertedWith("Secondary Token is not supported")

    })

    it("Add secondary market to tokenList", async () => {
        await expect(tokenList.connect(contractOwner).addMarket2Support(
            symbolUsdt, 
            18, 
            bepUsdt.address, 
            {gasLimit: 250000}
        )).to.emit(library, "Market2Added")
        expect(await tokenList.isMarket2Supported(symbolUsdt)).to.be.equal(true);
    })

    it("Secondary market test", async () => {
        await tokenList.connect(contractOwner).addMarket2Support(symbolUsdc, 18, bepUsdc.address);
        expect(await tokenList.isMarket2Supported(symbolUsdc)).to.equal(true)
        expect(await tokenList.getMarket2Address(symbolUsdc)).to.equal(bepUsdc.address)
        expect(await tokenList.getMarket2Decimal(symbolUsdc)).to.equal(18)
        await tokenList.connect(contractOwner).removeMarket2Support(symbolUsdc)
        await expect(tokenList.isMarket2Supported(symbolUsdc)).to.revertedWith("Secondary Token is not supported")
    })

    it("getMarketAddress", async() => {
        expect(await tokenList.getMarketAddress(symbolUsdt)).to.be.equal(bepUsdt.address)
    })

    it("getMarketDecimal", async () => {
        expect(await tokenList.getMarketDecimal(symbolUsdt)).to.be.equal(18)
    })

    it("remove market in tokenList", async () => {
        await tokenList.connect(contractOwner).removeMarketSupport(symbolUsdt);
        await expect(tokenList.isMarketSupported(symbolUsdt)).to.be.revertedWith("ERROR: Unsupported market")
    })

    it("minAmountCheck", async () => {
        await tokenList.connect(contractOwner).addMarketSupport(
            symbolUsdt, 
            18, 
            bepUsdt.address, 
            1,
            {gasLimit: 250000}
        )

        await tokenList.minAmountCheck(symbolUsdt, 20);
        await expect(tokenList.minAmountCheck(symbolUsdt, 17)).to.be.revertedWith("ERROR: Less than minimum deposit")
    })

    it("updateMarketSupport", async () => {
        expect(await tokenList.connect(contractOwner).updateMarketSupport(symbolUsdt, 28, bepUsdt.address, {gasLimit: 250000}))
            .to.emit(library, "MarketSupportUpdated")
    })

    it("Pause contract", async () => {
        await tokenList.connect(contractOwner).pauseTokenList()
        await expect(tokenList.connect(contractOwner).pauseTokenList()).revertedWith("Paused status")
    })
})