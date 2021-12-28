const { expect } = require("chai")
const { ethers } = require("hardhat")
const {
    getSelectors,
    get,
    FacetCutAction,
    removeSelectors,
    findAddressPositionInFacets
    } = require('../scripts/libraries/diamond.js')
  
const { assert } = require('chai')

// const {deployDiamond}= require('../scripts/deploy_diamond.js')
const {deployDiamond}= require('../scripts/deploy_all.js')
const {deployOpenFacets}= require('../scripts/deploy_all.js')
const {addMarkets}= require('../scripts/deploy_all.js')

describe("===== AccessRegistry Test =====", function () {
    let diamondAddress
    let diamondCutFacet
    let diamondLoupeFacet
    let tokenList
    let comptroller
    let reserve
    let deposit
    let oracle
    let loan
    let liquidator
    let library
    let accessRegistry
    let bep20
    let accounts
    let contractOwner
    const addresses = []

    const symbol4 = "0xABCD7374737472696e6700000000000000000000000000000000000000000000"
    const symbol2 = "0xABCD7374737972696e6700000000000000000000000000000000000000000000"
   
    const comit_NONE = "0x94557374737472696e6700000000000000000000000000000000000000000000"
    const comit_TWOWEEKS = "0x78629858A2529819179178879ABD797997979AD97987979AC7979797979797DF"
    const comit_ONEMONTH = "0x54567858A2529819179178879ABD797997979AD97987979AC7979797979797DF"
    const comit_THREEMONTHS = "0x78639858A2529819179178879ABD797997979AD97987979AC7979797979797DF"

    const role1 = "0x94557374737472696e6700000000000000000000000000000000000000000000"
    const role2 = "0x78629858A2529819179178979ABD797997979AD97987979AC7979797979797DF"
    const roleAdmin1 = "0x94557374737472696e6700120000000000000000000000000000000000000000"
    const roleAdmin2 = "0x78629858A2529819179178879ABD797997979AD97987979AC7979797979797DF"

    before(async function () {
        accounts = await ethers.getSigners()
        contractOwner = accounts[0]
        diamondAddress = await deployDiamond()
        await deployOpenFacets(diamondAddress)
        await addMarkets(diamondAddress)
        diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)

        tokenList = await ethers.getContractAt('TokenList', diamondAddress)
        comptroller = await ethers.getContractAt('Comptroller', diamondAddress)
        deposit = await ethers.getContractAt('Deposit', diamondAddress)
        accessRegistry = await ethers.getContractAt('AccessRegistry', diamondAddress)
        library = await ethers.getContractAt('LibDiamond', diamondAddress)

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
        )).to.emit(library, "MarketSupportAdded")
        expect(await tokenList.isMarketSupported(symbol4)).to.be.equal(true)

        await expect(tokenList.connect(accounts[1]).addMarketSupport(
            symbol2, 18, bep20.address, 1, {gasLimit: 240000}
        )).to.be.revertedWith("Only an admin can call this function")
    })

    it("Check if the contract is deployed", async () => {
        expect(await tokenList.adderss).to.not.equal("0x" + "0".repeat(40))
        expect(await accessRegistry.address).to.not.equal("0x" + "0".repeat(40))
        console.log("AccessRegistry is deployed at: ", accessRegistry.address)
    })

    it("Add Role", async () => {
        await accessRegistry.addRole(role1, accounts[1].address)
        await accessRegistry.addRole(role1, accounts[2].address)
        await accessRegistry.addRole(role2, accounts[1].address)
        await accessRegistry.addRole(role2, accounts[2].address)
        expect(await accessRegistry.hasRole(role1, accounts[1].address)).to.be.equal(true)
        expect(await accessRegistry.hasRole(role2, accounts[2].address)).to.be.equal(true)
        expect(await accessRegistry.hasRole(role1, accounts[2].address)).to.be.equal(true)
        expect(await accessRegistry.hasRole(role2, accounts[1].address)).to.be.equal(true)
    })

    it("Remove Role", async () => {
        await accessRegistry.removeRole(role1, accounts[1].address)
        expect(await accessRegistry.hasRole(role1, accounts[1].address)).to.be.equal(false)
        await accessRegistry.removeRole(role2, accounts[2].address)
        expect(await accessRegistry.hasRole(role2, accounts[2].address)).to.be.equal(false)
    })

    it("Transfer Role", async () => {
        await accessRegistry.connect(accounts[1])
            .transferRole(role2, accounts[1].address, accounts[2].address, {gasLimit: 250000})
        expect(await accessRegistry.hasRole(role2, accounts[1].address)).to.be.equal(false)
        expect(await accessRegistry.hasRole(role2, accounts[2].address)).to.be.equal(true)
    })

    it("Renounce Role", async () => {
        expect(await accessRegistry.hasRole(role1, accounts[2].address)).to.be.equal(true)
        await expect(accessRegistry.connect(accounts[1]).renounceRole(
            role1, 
            accounts[2].address,
            {gasLimit: 250000}
        ))
        .to.revertedWith("Inadequate permissions")

        await accessRegistry.connect(accounts[2]).renounceRole(role1, accounts[2].address, {gasLimit: 250000})
        expect(await accessRegistry.hasRole(role1, accounts[2].address)).to.be.equal(false)
    })

    it("Add Admin Role", async () => {
        await accessRegistry.addAdminRole(roleAdmin1, accounts[1].address)
        expect(await accessRegistry.hasAdminRole(roleAdmin1, accounts[1].address)).to.be.equal(true)
        await accessRegistry.addAdminRole(roleAdmin1, accounts[2].address)
        expect(await accessRegistry.hasAdminRole(roleAdmin1, accounts[1].address)).to.be.equal(true)
        await accessRegistry.addAdminRole(roleAdmin2, accounts[1].address)
        expect(await accessRegistry.hasAdminRole(roleAdmin1, accounts[1].address)).to.be.equal(true)
    })

    it("Remove Admin Role", async () => {
        await accessRegistry.connect(accounts[1]).removeAdminRole(roleAdmin1, accounts[1].address, {gasLimit: 250000})
        expect(await accessRegistry.hasAdminRole(roleAdmin1, accounts[1].address)).to.be.equal(false)
        await expect(accessRegistry.connect(accounts[1]).removeAdminRole(roleAdmin2, accounts[2].address, {gasLimit: 250000})).to.be.revertedWith("Role does not exist.")
    })

    it("Transfer Admin Role", async () => {
        await accessRegistry.connect(accounts[1])
            .adminRoleTransfer(roleAdmin2, accounts[1].address, accounts[2].address, {gasLimit: 250000})
        expect(await accessRegistry.hasAdminRole(roleAdmin2, accounts[1].address)).to.be.equal(false)
        expect(await accessRegistry.hasAdminRole(roleAdmin2, accounts[2].address)).to.be.equal(true)
    })

    it("Renounce Admin Role", async () => {
        expect(await accessRegistry.hasAdminRole(roleAdmin1, accounts[2].address)).to.be.equal(true)
        await expect(accessRegistry.connect(accounts[1]).adminRoleRenounce(
            roleAdmin1, 
            accounts[2].address,
            {gasLimit: 250000}
        ))
        .to.revertedWith("Inadequate permissions")

        await accessRegistry.connect(accounts[2]).adminRoleRenounce(roleAdmin1, accounts[2].address, {gasLimit: 250000})
        expect(await accessRegistry.hasAdminRole(roleAdmin1, accounts[2].address)).to.be.equal(false)
    })
})
