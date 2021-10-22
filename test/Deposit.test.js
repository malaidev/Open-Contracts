const {expect, use}  = require( 'chai');
const Web3 = require('web3');
const {deployContract, MockProvider, solidity} = require ('ethereum-waffle');

use(solidity);

describe("Deposit Contract", () => {
    let tokenList;
    let comptroller;
    let deposit;
    let bep20;
    let reserve;

    // const bep20Symbol = Web3.utils.asciiToHex("MKBEP2" + "0".repeat(26));
    const symbol4 = "0xABCD7374737472696e6700000000000000000000000000000000000000000000";
    const [wallet, account1] = new MockProvider().getWallets();
    const TokenList = require("../build/contracts/TokenList.json");
    const Comptroller = require('../build/contracts/Comptroller.json');
    const Deposit = require("../build/contracts/Deposit.json");
    const MockBep20 = require("../build/contracts/MockBep20.json");
    const Reserve = require("../build/contracts/Reserve.json");

    //NONE, TWOWEEKS, ONEMONTH, THREEMONTHS
    const comit_NONE = "0x94557374737472696e6700000000000000000000000000000000000000000000";
    const comit_TWOWEEKS = "0x78629858A2529819179178879ABD797997979AD97987979AC7979797979797DF";
    const comit_ONEMONTH = "0x54567858A2529819179178879ABD797997979AD97987979AC7979797979797DF";
    const comit_THREEMONTHS = "0x78639858A2529819179178879ABD797997979AD97987979AC7979797979797DF";
    
    before(async () => {
        tokenList = await deployContract(wallet, TokenList, [wallet.address]);
        comptroller = await deployContract(wallet, Comptroller, [wallet.address]);
        deposit = await deployContract(wallet, Deposit, [wallet.address, tokenList.address, comptroller.address]);
        bep20 = await deployContract(wallet, MockBep20);
        reserve = await deployContract(wallet, Reserve, [wallet.address, deposit.address]);
        await deposit.setReserveAddress(reserve.address);
        // await bep20.transfer(deposit.address, 400);


        await tokenList.connect(wallet).addMarketSupport(
            symbol4, 
            18, 
            bep20.address, 
            1,
            {gasLimit: 250000}
        );

        await comptroller.connect(wallet).setCommitment(comit_NONE);
        await comptroller.connect(wallet).setCommitment(comit_TWOWEEKS);
        await comptroller.connect(wallet).setCommitment(comit_ONEMONTH);
        await comptroller.connect(wallet).setCommitment(comit_THREEMONTHS);
        
        await comptroller.updateAPY(comit_TWOWEEKS, 6);
    });

    it("Check deployment", async () => {
        console.log("Bep20 is deployed at: ", bep20.address);
        console.log("TokenList is deployed at: ", tokenList.address);
        console.log("Comptroller is deployed at: ", comptroller.address);
        console.log("Deposit is deployed at: ", deposit.address);
        console.log("Reserve is deployed at: ", reserve.address);
    });

    it("Check if have bep20 token", async () => {
        const balance = await bep20.balanceOf(wallet.address);
        console.log("Balance is ", balance);
    });

    if("Check if Bep20 add token success", async () => {
        expect(await tokenList.isMarketSupported(symbol4)).to.be.equal(true);
    });

    it("hasAccount at null", async () => {
        await expect(deposit.hasAccount(account1.address)).to.be.revertedWith("ERROR: No savings account");
    });

    it("MockupBep Transfer", async () => {
        await expect(bep20.transfer(account1.address, 7))
      .to.emit(bep20, 'Transfer');

    });

    it("Token Mint to Deposit", async () => {
        console.log("Before deposit balance is ", await bep20.balanceOf(deposit.address));
        expect(await bep20.balanceOf(deposit.address)).to.be.equal(Number(0));
        await expect(bep20.transfer(deposit.address, 1000000)).to.emit(bep20, 'Transfer');
        expect(await bep20.balanceOf(deposit.address)).to.not.equal(Number(0));
        console.log("After deposit balance is ", await bep20.balanceOf(deposit.address));
    });

    it("Check createDeposit", async () => {
        const depositAmount = 300;
        
        await deposit.connect(wallet).createDeposit(symbol4, comit_TWOWEEKS, depositAmount, {gasLimit: 3000000});

        await expect(deposit.connect(wallet).createDeposit(symbol4, comit_TWOWEEKS, depositAmount, {gasLimit: 3000000}))
            .to.be.reverted;
        
    });

    // it("Check withdrawDeposit", async () => {

    //     console.log("Deposit balance before withdraw is ", await bep20.balanceOf(deposit.address));
    //     await expect(deposit.connect(wallet).withdrawDeposit(symbol4, comit_TWOWEEKS, Number(100), Number(0), {gasLimit: 3000000}))
    //         .to.emit(deposit, "NewDeposit");
    //     console.log("Deposit balance after withdraw is ", await bep20.balanceOf(deposit.address));

    // });

    it("Check addToDeposit", async () => {
        console.log("Deposit balance before addWithdraw is ", await bep20.balanceOf(deposit.address));
        await expect(deposit.connect(wallet).addToDeposit(symbol4, comit_TWOWEEKS, Number(400), {gasLimit: 3000000}))
        .to.emit(deposit, "DepositAdded");
        console.log("Deposit balance after addWithdraw ", await bep20.balanceOf(deposit.address));
    });

});