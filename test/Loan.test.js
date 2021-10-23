const {expect, use}  = require( 'chai');
// const {Contract, utils} = require( 'ethers');
const {deployContract, MockProvider, solidity} = require ('ethereum-waffle');

use(solidity);

describe("Loan Contract", async () => {

    let tokenList;
    let comptroller;
    let liquidator;
    let oracle;
    let deposit;
    let reserve;
    let loan;

    const symbol1 = "0xABCD7374737472696e6700000000000000000000000000000000000000000000";
    const [wallet, account1] = new MockProvider().getWallets();
    const TokenList = require("../build/contracts/TokenList.json");
    const Comptroller = require('../build/contracts/Comptroller.json');
    const MockBep20 = require("../build/contracts/MockBep20.json");
    const Reserve = require("../build/contracts/Reserve.json");
    const Liquidator = require("../build/contracts/Liquidator.json");
    const Loan = require("../build/contracts/Loan.json");
    const Deposit = require("../build/contracts/Deposit.json");
    const OracleOpen = require("../build/contracts/OracleOpen.json");

    //NONE, TWOWEEKS, ONEMONTH, THREEMONTHS
    const comit_NONE = "0x94557374737472696e6700000000000000000000000000000000000000000000";
    const comit_TWOWEEKS = "0x78629858A2529819179178879ABD797997979AD97987979AC7979797979797DF";
    const comit_ONEMONTH = "0x54567858A2529819179178879ABD797997979AD97987979AC7979797979797DF";
    const comit_THREEMONTHS = "0x78639858A2529819179178879ABD797997979AD97987979AC7979797979797DF";
    
    
    beforeEach(async () => {
        tokenList = await deployContract(wallet, TokenList, [wallet.address]);
        comptroller = await deployContract(wallet, Comptroller, [wallet.address]);
        liquidator = await deployContract(wallet, Liquidator, [wallet.address, tokenList.address]);
        deposit = await deployContract(wallet, Deposit, [wallet.address, tokenList.address, comptroller.address]);
        oracle = await deployContract(wallet, OracleOpen, [wallet.address]);
        bep20 = await deployContract(wallet, MockBep20);
        reserve = await deployContract(wallet, Reserve, [wallet.address, deposit.address]);
        loan = await deployContract(wallet, Loan, [
            wallet.address,
            tokenList.address,
            comptroller.address,
            reserve.address,
            liquidator.address,
            oracle.address
        ]);

        await deposit.connect(wallet).setReserveAddress(reserve.address, {gasLimit: 250000});
        // await reserve.connect(wallet).setLoanAddress(loan.address, {gasLimit: 250000});
        await tokenList.connect(wallet).addMarketSupport(
            symbol1, 
            18, 
            bep20.address, 
            1,
            {gasLimit: 250000}
        );

        await comptroller.connect(wallet).setCommitment(comit_NONE);
        await comptroller.connect(wallet).setCommitment(comit_TWOWEEKS);
        await comptroller.connect(wallet).setCommitment(comit_ONEMONTH);
        await comptroller.connect(wallet).setCommitment(comit_THREEMONTHS);
        
        await comptroller.connect(wallet).updateAPY(comit_TWOWEEKS, 6, {gasLimit: 2500000});
    });
    
    it("Check deployement", async () => {
        expect(reserve.address).to.not.equal("0x" + "0".repeat(40));
    });

    it("Token Mint", async () => {
        expect(await bep20.balanceOf(deposit.address)).to.be.equal(Number(0));
        await expect(bep20.transfer(deposit.address, 1000000)).to.emit(bep20, 'Transfer');
        expect(await bep20.balanceOf(deposit.address)).to.not.equal(Number(0));

        await expect(bep20.transfer(loan.address, 10000000)).to.emit(bep20, "Transfer");
    });

    it("Check loanRequest", async () => {
        expect(await bep20.balanceOf(deposit.address)).to.be.equal(Number(0));
        await expect(bep20.transfer(deposit.address, 1000000)).to.emit(bep20, 'Transfer');
        expect(await bep20.balanceOf(deposit.address)).to.not.equal(Number(0));
        await expect(bep20.transfer(loan.address, 10000000)).to.emit(bep20, "Transfer");

        await expect(loan.connect(wallet).loanRequest(symbol1, comit_TWOWEEKS, 1000, symbol1, 500, {gasLimit: 3000000}))
        .emit("NewLoan");
    });
});