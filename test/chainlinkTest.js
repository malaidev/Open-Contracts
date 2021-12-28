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

describe("===== Chainlink Test =====", function () {
    let diamond
    let diamondCutFacet
    let diamondLoupeFacet
    let tokenList
    let oracle
    let liquidator
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
        // const Diamond = await ethers.getContractFactory("OpenDiamond")
        // diamond = await Diamond.attach("0xEF1a30678f7d205d310bADBA8dfA4B122B0Fb24b")
        // diamond = await ethers.getContractAt('OpenDiamond', "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512")
        diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
        
        tokenList = await ethers.getContractAt('TokenList', diamondAddress)
        oracle = await ethers.getContractAt('OracleOpen', diamondAddress)

        const Mock = await ethers.getContractFactory('MockBep20')

        bep20 = await Mock.deploy()
        await bep20.deployed()
    })

    it('should have three facets -- call to facetAddresses function', async () => {
        for (const address of await diamondLoupeFacet.facetAddresses()) {
            addresses.push(address)
        }
        assert.equal(addresses.length, 11)
    })

    it("Deployment Check", async () => {
        expect(oracle.address).to.not.equal("0x" + "0".repeat(40))
        console.log("Oracle address is ", oracle.address)
    })

    it("Add market", async () => {
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

    it("Check if have bep20 token", async () => {
        const balance = await bep20.balanceOf(contractOwner.address)
        expect(await tokenList.isMarketSupported(symbol4)).to.be.equal(true)
    })

    it("Check getMarket", async () => {
        expect(await tokenList.getMarketDecimal(symbol4)).to.be.equal(Number(18))
    })

    it("MockupBep Transfer", async () => {
        await expect(bep20.transfer(accounts[1].address, 7))
      .to.emit(bep20, 'Transfer')

    })

    it("Test Chainlink", async () => {

    //    const provider = new ethers.providers.JsonRpcProvider("https://api.s0.b.hmny.io")
    //     const aggregatorV3InterfaceABI = [{ "inputs": [], "name": "decimals", "outputs": [{ "internalType": "uint8", "name": "", "type": "uint8" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "description", "outputs": [{ "internalType": "string", "name": "", "type": "string" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "uint80", "name": "_roundId", "type": "uint80" }], "name": "getRoundData", "outputs": [{ "internalType": "uint80", "name": "roundId", "type": "uint80" }, { "internalType": "int256", "name": "answer", "type": "int256" }, { "internalType": "uint256", "name": "startedAt", "type": "uint256" }, { "internalType": "uint256", "name": "updatedAt", "type": "uint256" }, { "internalType": "uint80", "name": "answeredInRound", "type": "uint80" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "latestRoundData", "outputs": [{ "internalType": "uint80", "name": "roundId", "type": "uint80" }, { "internalType": "int256", "name": "answer", "type": "int256" }, { "internalType": "uint256", "name": "startedAt", "type": "uint256" }, { "internalType": "uint256", "name": "updatedAt", "type": "uint256" }, { "internalType": "uint80", "name": "answeredInRound", "type": "uint80" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "version", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }]
    //    const addr = "0xB8c77482e45F1F44dE1745F52C74426C631bDD52"
    //     const priceFeed = new ethers.Contract(addr, aggregatorV3InterfaceABI, provider)
    //     const price = await priceFeed.latestRoundData()
    //     console.log("Latest Round Data", price)

        const addr = "0xB8c77482e45F1F44dE1745F52C74426C631bDD52" // DAI / USD
        const price = await oracle.getLatestPrice(addr)
        // await oracle.unpauseOracle()
        console.log("Price is ", price)

    })

  
})
