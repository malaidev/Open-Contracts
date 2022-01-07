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

describe("===== AccessRegistry Test =====", function () {
    let diamondAddress
    let diamondCutFacet
    let diamondLoupeFacet
    let tokenList
    let comptroller
    let deposit
    let oracle
    let loan
    let liquidator
    let library
    let accessRegistry
	let bepUsdt
	let bepBtc
	let bepUsdc
    let accounts
    let contractOwner
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

    const role1 = "0x94557374737472696e6700000000000000000000000000000000000000000000"
    const role2 = "0x78629858A2529819179178979ABD797997979AD97987979AC7979797979797DF"
    const roleAdmin1 = "0x94557374737472696e6700120000000000000000000000000000000000000000"
    const roleAdmin2 = "0x78629858A2529819179178879ABD797997979AD97987979AC7979797979797DF"

    before(async function () {
        accounts = await ethers.getSigners()
        contractOwner = accounts[0]
        diamondAddress = await deployDiamond()
        await deployOpenFacets(diamondAddress)
        rets = await addMarkets(diamondAddress)
        diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)

        tokenList = await ethers.getContractAt('TokenList', diamondAddress)
        comptroller = await ethers.getContractAt('Comptroller', diamondAddress)
        deposit = await ethers.getContractAt('Deposit', diamondAddress)
        accessRegistry = await ethers.getContractAt('AccessRegistry', diamondAddress)
        library = await ethers.getContractAt('LibDiamond', diamondAddress)

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
