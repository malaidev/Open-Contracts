const { expect } = require("chai");
const { ethers } = require("hardhat");
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
    let library
    let tokenList
    let bep20
    let accounts    
    let contractOwner
    const addresses = []

    const symbol4 = "0xABCD7374737472696e6700000000000000000000000000000000000000000000";
    const symbol2 = "0xABCD7374737972696e6700000000000000000000000000000000000000000000";
   
    const comit_NONE = "0x94557374737472696e6700000000000000000000000000000000000000000000";
    const comit_TWOWEEKS = "0x78629858A2529819179178879ABD797997979AD97987979AC7979797979797DF";
    const comit_ONEMONTH = "0x54567858A2529819179178879ABD797997979AD97987979AC7979797979797DF";
    const comit_THREEMONTHS = "0x78639858A2529819179178879ABD797997979AD97987979AC7979797979797DF";

    before(async function () {
        accounts = await ethers.getSigners()
        contractOwner = accounts[0]
        diamondAddress = await deployDiamond()
        await deployOpenFacets(diamondAddress)
        await addMarkets(diamondAddress)
        // const diamond = await ethers.getContractAt('OpenDiamond', "0xEF1a30678f7d205d310bADBA8dfA4B122B0Fb24b")
        // diamondAddress = diamond.address
        diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)

        tokenList = await ethers.getContractAt('TokenList', diamondAddress)
        library = await ethers.getContractAt('LibDiamond', diamondAddress)

        const Mock = await ethers.getContractFactory('MockBep20')
        bep20 = await Mock.deploy()
        await bep20.deployed()
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
        await expect(tokenList.isMarketSupported(symbol2)).to.be.revertedWith("ERROR: Unsupported market");
    })

    it("Add token to tokenList", async () => {
        console.log("tokenList = ", tokenList.address);
        await expect(tokenList.connect(contractOwner).addMarketSupport(
            symbol4, 
            18, 
            bep20.address, 
            1,
            {gasLimit: 250000}
        )).to.emit(library, "MarketSupportAdded")
        expect(await tokenList.isMarketSupported(symbol4)).to.be.equal(true);

        console.log("symbol4 = ", symbol4);
        console.log("bep = ", bep20.address);

        // await expect(tokenList.connect(accounts[1]).addMarketSupport(
        //     symbol2, 18, bep20.address, 1, {gasLimit: 240000}
        // )).to.be.revertedWith("Only an admin can call this function");
    })

    it("getMarketAddress", async() => {
        console.log("getmarketaddress = ", await tokenList.getMarketAddress(symbol4));
        expect(await tokenList.getMarketAddress(symbol4)).to.be.equal(bep20.address)
    })

    it("getMarketDecimal", async () => {
        expect(await tokenList.getMarketDecimal(symbol4)).to.be.equal(18)
    })

    it("remove market in tokenList", async () => {
        await tokenList.connect(contractOwner).removeMarketSupport(symbol4);
        await expect(tokenList.isMarketSupported(symbol4)).to.be.revertedWith("ERROR: Unsupported market")
    })

    it("minAmountCheck", async () => {
        await tokenList.connect(contractOwner).addMarketSupport(
            symbol4, 
            18, 
            bep20.address, 
            1,
            {gasLimit: 250000}
        )

        await tokenList.minAmountCheck(symbol4, 20);
        await expect(tokenList.minAmountCheck(symbol4, 17)).to.be.revertedWith("ERROR: Less than minimum deposit")
    })

    it("updateMarketSupport", async () => {
        expect(await tokenList.connect(contractOwner).updateMarketSupport(symbol4, 28, bep20.address, {gasLimit: 250000}))
            .to.emit(library, "MarketSupportUpdated")
    })

    it("Market 2", async () => {
        await tokenList.connect(contractOwner).addMarket2Support(symbol2, 18, bep20.address);
        expect(await tokenList.isMarket2Supported(symbol2)).to.equal(true)

        expect(await tokenList.getMarket2Address(symbol2)).to.equal(bep20.address)

        expect(await tokenList.getMarket2Decimal(symbol2)).to.equal(18)

        await tokenList.connect(contractOwner).removeMarket2Support(symbol2)
        await expect(tokenList.isMarket2Supported(symbol2)).to.revertedWith("Secondary Token is not supported")
    })
})