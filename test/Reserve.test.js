const {expect, use}  = require( 'chai');
// const {Contract, utils} = require( 'ethers');
const {deployContract, MockProvider, solidity} = require ('ethereum-waffle');

use(solidity);

describe("Reserve Contract", async () => {
    let tokenList;
    let comptroller;
    let deposit;
    let reserve;
    let bep20;

    const [wallet, account1] = new MockProvider().getWallets();
    const TokenList = require("../build/contracts/TokenList.json");
    const Comptroller = require('../build/contracts/Comptroller.json');
    const Deposit = require("../build/contracts/Deposit.json");
    const Reserve = require("../build/contracts/Reserve.json");
    const MockBep20 = require("../build/contracts/MockBep20.json");
    const symbol4 = "0xABCD7374737472696e6700000000000000000000000000000000000000000000";
    // const token1 = {
    //     symbol: "0x25B29858A2529819179178979ABD797997979AD97987979AC7979797979797DF",
    //     decimals: Number(6),
    //     address: "0xB29858A2529819179178979AbD797997979aD979",
    //     amount: 200
    // }
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

        reserve = await deployContract(wallet, Reserve, [wallet.address, deposit.address]);

    });

    it("Check deployement", async() => {
        expect(tokenList.address).to.not.equal("0x" + "0".repeat(40));
        expect(comptroller.address).to.not.equal("0x" + "0".repeat(40));
        expect(deposit.address).to.not.equal("0x" + "0".repeat(40));
        expect(reserve.address).to.not.equal("0x" + "0".repeat(40));

        console.log("Reserve deployed at: ", reserve.address);
    });

    it("Check market reserves", async () => {
        expect(await reserve.connect(wallet).avblMarketReserves(symbol4), {gasLimit: 250000}).to.not.equal(Number(0));
    });

    
});