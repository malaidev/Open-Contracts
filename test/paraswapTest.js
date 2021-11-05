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

const {deployDiamond}= require('../scripts/deploy_diamond.js')

describe("===== Paraswap Test =====", function () {
    let diamond
    let diamondCutFacet
    let diamondLoupeFacet
    let tokenList
    let oracle
    let liquidator
    let bep20
    let bepOne
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
        // await deployOpenFacets(diamondAddress)
        diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
        
        tokenList = await ethers.getContractAt('TokenList', diamondAddress)
        oracle = await ethers.getContractAt('OracleOpen', diamondAddress)
        liquidator = await ethers.getContractAt('Liquidator', diamondAddress)

        const Mock = await ethers.getContractFactory('MockBep20')

        bep20 = await Mock.deploy()
        await bep20.deployed()
        bepOne = await Mock.deploy()
        await bepOne.deployed()
    })

    it("Deployment Check", async () => {
        expect(oracle.address).to.not.equal("0x" + "0".repeat(40))
        console.log("Oracle address is ", oracle.address)
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

    it("Add token to tokenList", async () => {
        await expect(tokenList.connect(contractOwner).addMarketSupport(
            symbol4, 
            18, 
            bep20.address, 
            1,
            {gasLimit: 250000}
        )).to.emit(tokenList, "MarketSupportAdded")
        expect(await tokenList.isMarketSupported(symbol4)).to.be.equal(true);

        await expect(tokenList.connect(accounts[1]).addMarketSupport(
            symbol2, 18, bep20.address, 1, {gasLimit: 240000}
        )).to.be.revertedWith("Only an admin can call this function");
    })

    it("Test Paraswap", async () => {
        expect(await liquidator.swap(symbol2, symbol4, 1, 0)).to.equal(1)
    })
  
})
