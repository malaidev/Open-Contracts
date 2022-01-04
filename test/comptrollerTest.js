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

describe("===== Comptroller Test =====", function () {
    let diamondAddress
    let diamondCutFacet
    let diamondLoupeFacet
    let tokenList
    let comptroller
    let bep20
    let library
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
        // await deployOpenFacets(diamondAddress)
        diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)

        tokenList = await ethers.getContractAt('TokenList', diamondAddress)
        comptroller = await ethers.getContractAt('Comptroller', diamondAddress)
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
        expect(await tokenList.isMarketSupported(symbol4)).to.be.equal(true);

        await expect(tokenList.connect(accounts[1]).addMarketSupport(
            symbol2, 18, bep20.address, 1, {gasLimit: 240000}
        )).to.be.revertedWith("Only an admin can call this function");
    })

    it("Check getAPY empty", async () => {
        await expect(comptroller.getAPY(comit_NONE)).to.be.reverted;
        await expect(comptroller.getAPYInd(comit_NONE, 23)).to.be.reverted;
    })

    it("Check getAPR empty", async () => {
        await expect(comptroller.getAPR(comit_TWOWEEKS)).to.be.reverted;
        await expect(comptroller.getAPRInd(comit_NONE,12)).to.be.reverted;
    })

    it("Check getApytime empty", async () => {
        await expect(comptroller.getApytime(comit_TWOWEEKS, 22)).to.be.reverted;
    })

    it("Check getApyLastTime", async () => {
        await expect(comptroller.getApyLastTime(comit_TWOWEEKS)).to.be.reverted;
    })

    it("Update APY", async () => {
        await comptroller.connect(contractOwner).updateAPY(comit_NONE, 2, {gasLimit: 250000});
        expect(await comptroller.getAPY(comit_NONE)).to.be.equal(2);
    })

    it("Update APR", async () => {
        await comptroller.connect(contractOwner).updateAPR(comit_TWOWEEKS, 4, {gasLimit: 250000});
        expect(await comptroller.getAPR(comit_TWOWEEKS)).to.be.equal(4);
        expect(await comptroller.getAprTimeLength(comit_TWOWEEKS)).to.be.equal(1);
    })

    it("Calc APR", async () => {
        let oldLenAccruedInterest = 1;
        let oldTime = 0;
        let aggregateInterest = 0;

        await comptroller.connect(contractOwner).updateAPR(comit_TWOWEEKS, 8, {gasLimit: 250000});
        console.log("Before: LenIntereset = ", oldLenAccruedInterest, " oldTime = ", oldTime, " aggregateIntereset = ", aggregateInterest);
        await comptroller.calcAPR(comit_NONE, oldLenAccruedInterest, oldTime, aggregateInterest);
        console.log("After: LenIntereset = ", oldLenAccruedInterest, " oldTime = ", oldTime, " aggregateIntereset = ", aggregateInterest);
    })

    it("updateLoanIssuanceFees", async () => {
        await expect(comptroller.connect(contractOwner).updateLoanIssuanceFees(23, {gasLimit: 250000})).to.emit(comptroller, "LoanIssuanceFeesUpdated");
    });

    it("updateLoanClosureFees", async () => {
        await expect(comptroller.connect(contractOwner).updateLoanClosureFees(33, {gasLimit: 250000})).to.emit(comptroller, "LoanClosureFeesUpdated");
    });

    it("updateLoanPreClosureFees", async () => {
        await expect(comptroller.connect(contractOwner).updateLoanPreClosureFees(543, {gasLimit: 250000})).to.emit(comptroller, "LoanPreClosureFeesUpdated");
    });

    it("updateDepositPreclosureFees", async () => {
        await expect(comptroller.connect(contractOwner).updateDepositPreclosureFees(44, {gasLimit: 250000})).to.emit(comptroller, "DepositPreClosureFeesUpdated");
        expect(await comptroller.depositPreClosureFees()).to.be.equal(44);
    });
    
    it("updateWithdrawalFees", async () => {
        await expect(comptroller.connect(contractOwner).updateWithdrawalFees(2, {gasLimit: 250000})).to.emit(comptroller, "DepositWithdrawalFeesUpdated");
        expect(await comptroller.depositWithdrawalFees()).to.be.equal(2);
    });

    it("updateCollateralReleaseFees", async () => {
        await expect(comptroller.connect(contractOwner).updateCollateralReleaseFees(55, {gasLimit: 250000})).to.emit(comptroller, "CollateralReleaseFeesUpdated");
        expect(await comptroller.collateralReleaseFees()).to.be.equal(55);
    });

    it("updateYieldConversion", async () => {
        await expect(comptroller.connect(contractOwner).updateYieldConversion(56, {gasLimit: 250000})).to.emit(comptroller, "YieldConversionFeesUpdated");
    });

    it("updateMarketSwapFees", async () => {
        await expect(comptroller.connect(contractOwner).updateMarketSwapFees(3, {gasLimit: 250000})).to.emit(comptroller, "MarketSwapFeesUpdated");
    });

    it("updateReserveFactor", async () => {
        await expect(comptroller.connect(contractOwner).updateReserveFactor(23, {gasLimit: 250000})).to.emit(comptroller, "ReserveFactorUpdated");
    });

    it("updateMaxWithdrawal", async () => {
        await expect(comptroller.connect(contractOwner).updateMaxWithdrawal(6, 444, {gasLimit: 250000})).to.emit(comptroller, "MaxWithdrawalUpdated");
    });
})
