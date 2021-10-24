const {expect, use}  = require( 'chai');
// const {Contract, utils} = require( 'ethers');
const {deployContract, MockProvider, solidity} = require ('ethereum-waffle');
const { bigUint } = require('fast-check');

use(solidity);

describe("Comptroller", async () => {
    let contract;
    const [wallet, account1] = new MockProvider().getWallets();
    const Comptroller = require('../build/contracts/Comptroller.json');

    const comit1 = "0x94557374737472696e6700000000000000000000000000000000000000000000";
    const comit2 = "0x78629858A2529819179178879ABD797997979AD97987979AC7979797979797DF";

    before(async () => {
        contract = await deployContract(wallet, Comptroller, [wallet.address]);
    });

    it("Check deployement", async () => {
        expect(contract.address).to.not.equal("0x" + "0".repeat(40));
        console.log("Comptroller is deployed at: ", contract.address);
    });
    
    it("Check getAPY empty", async () => {
        await expect(contract.getAPY(comit1)).to.be.reverted;
        await expect(contract.getAPYInd(comit2, 23)).to.be.reverted;
    });

    it("Check getAPR empty", async () => {
        await expect(contract.getAPR(comit2)).to.be.reverted;
        await expect(contract.getAPRInd(comit1,12)).to.be.reverted;
    });

    it("Check getApytimeber empty", async () => {
        await expect(contract.getApytimeber(comit2, 22)).to.be.reverted;
    });

    it("Check getApyLastTime", async () => {
        await expect(contract.getApyLastTime(comit2)).to.be.reverted;
    });

    it("Update APY", async () => {
        await contract.connect(wallet).updateAPY(comit1, 2, {gasLimit: 250000});
        expect(await contract.getAPY(comit1)).to.be.equal(Number(2));
    });

    it("Update APR", async () => {
        await contract.connect(wallet).updateAPR(comit2, 4, {gasLimit: 250000});
        expect(await contract.getAPR(comit2)).to.be.equal(Number(4));
        expect(await contract.getAprTimeLength(comit2)).to.be.equal(Number(1));
    });

    // it("Get Commitment", async () => {
    //     expect(await contract.getCommitment(0)).to.be.reverted;
    // });

    it("Calc APR", async () => {
        let oldLenAccruedInterest = 1;
        let oldTime = 0;
        let aggregateInterest = 0;

        await contract.connect(wallet).updateAPR(comit2, 8, {gasLimit: 250000});
        console.log("Before: LenIntereset = ", oldLenAccruedInterest, " oldTime = ", oldTime, " aggregateIntereset = ", aggregateInterest);
        await contract.calcAPR(comit1, oldLenAccruedInterest, oldTime, aggregateInterest);
        console.log("After: LenIntereset = ", oldLenAccruedInterest, " oldTime = ", oldTime, " aggregateIntereset = ", aggregateInterest);
    });

    it("updateLoanIssuanceFees", async () => {
        await expect(contract.connect(wallet).updateLoanIssuanceFees(23, {gasLimit: 250000})).to.emit(contract, "LoanIssuanceFeesUpdated");
    });

    it("updateLoanClosureFees", async () => {
        await expect(contract.connect(wallet).updateLoanClosureFees(33, {gasLimit: 250000})).to.emit(contract, "LoanClosureFeesUpdated");
    });

    it("updateLoanPreClosureFees", async () => {
        await expect(contract.connect(wallet).updateLoanPreClosureFees(543, {gasLimit: 250000})).to.emit(contract, "LoanPreClosureFeesUpdated");
    });

    it("updateDepositPreclosureFees", async () => {
        await expect(contract.connect(wallet).updateDepositPreclosureFees(44, {gasLimit: 250000})).to.emit(contract, "DepositPreClosureFeesUpdated");
        expect(await contract.depositPreClosureFees()).to.be.equal(44);
    });
    
    it("updateWithdrawalFees", async () => {
        await expect(contract.connect(wallet).updateWithdrawalFees(2, {gasLimit: 250000})).to.emit(contract, "DepositWithdrawalFeesUpdated");
        expect(await contract.depositWithdrawalFees()).to.be.equal(2);
    });

    it("updateCollateralReleaseFees", async () => {
        await expect(contract.connect(wallet).updateCollateralReleaseFees(55, {gasLimit: 250000})).to.emit(contract, "CollateralReleaseFeesUpdated");
        expect(await contract.collateralReleaseFees()).to.be.equal(Number(55));
    });

    it("updateYieldConversion", async () => {
        await expect(contract.connect(wallet).updateYieldConversion(56, {gasLimit: 250000})).to.emit(contract, "YieldConversionFeesUpdated");
        expect(await contract.yieldConversionFees()).to.be.equal(Number(56));
    });

    it("updateMarketSwapFees", async () => {
        await expect(contract.connect(wallet).updateMarketSwapFees(3, {gasLimit: 250000})).to.emit(contract, "MarketSwapFeesUpdated");
        expect(await contract.marketSwapFees()).to.be.equal(Number(3));
    });

    it("updateReserveFactor", async () => {
        await expect(contract.connect(wallet).updateReserveFactor(23, {gasLimit: 250000})).to.emit(contract, "ReserveFactorUpdated");
        expect(await contract.reserveFactor()).to.be.equal(Number(23));
    });

    it("updateMaxWithdrawal", async () => {
        await expect(contract.connect(wallet).updateMaxWithdrawal(6, 444, {gasLimit: 250000})).to.emit(contract, "MaxWithdrawalUpdated");
        expect(await contract.maxWithdrawalFactor()).to.be.equal(Number(6));
    });
});