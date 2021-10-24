const {expect, use}  = require( 'chai');
// const {Contract, utils} = require( 'ethers');
const {deployContract, MockProvider, solidity} = require ('ethereum-waffle');

use(solidity);

describe("Liquidator Contract", async () => {
    let liquidator;
    let tokenList;
    const [wallet, account1, account2] = new MockProvider().getWallets();
    const Liquidator = require('../build/contracts/Liquidator.json');
    const TokenList = require('../build/contracts/TokenList.json');
    const tokenBnb = {
        symbol: "0x74657374737472696e6700000000000000000000000000000000000000000000",
        decimals: Number(18),
        address: "0xB8c77482e45F1F44dE1745F52C74426C631bDD52",
        amount: 100
    };

    const tokenUsdt = {
        symbol: "0x25B29858A2529819179178979ABD797997979AD97987979AC7979797979797DF",
        decimals: Number(18),
        address: "0xdac17f958d2ee523a2206206994597c13d831ec7",
        amount: 300
    }
    before(async () => {
        tokenList = await deployContract(wallet, TokenList, [wallet.address]);
        liquidator = await deployContract(wallet, Liquidator, [wallet.address, tokenList.address]);
        console.log("Liquidator deployed at ", liquidator.address);
    });
    
    it("Deploy Check", async () => {
        expect(tokenList.address).to.not.equal("0x" + "0".repeat(40));
        expect(liquidator.address).to.not.equal("0x" + "0".repeat(40));
        console.log("TokenList is deployed at: ", tokenList.address);
        console.log("Liquidator is deployed at: ", liquidator.address);
    });

    it("Add token", async () => {
        await expect(tokenList.connect(wallet).addMarketSupport(
            tokenBnb.symbol, 
            tokenBnb.decimals, 
            tokenBnb.address, 
            tokenBnb.amount,
            {gasLimit: 250000}
        ))
        .to.emit(tokenList, "MarketSupportAdded");
        expect(await tokenList.isMarketSupported(tokenBnb.symbol)).to.be.equal(true);

        await expect(tokenList.connect(wallet).addMarketSupport(
            tokenUsdt.symbol, 
            tokenUsdt.decimals, 
            tokenUsdt.address, 
            tokenUsdt.amount,
            {gasLimit: 250000}
        ))
        .to.emit(tokenList, "MarketSupportAdded");
        expect(await tokenList.isMarketSupported(tokenUsdt.symbol)).to.be.equal(true);
    });

    // it("Swap", async () => {
    //     const liqWallet = await liquidator.connect(wallet);
    //     expect(await liquidator.connect(wallet).swap(tokenBnb.symbol, tokenUsdt.symbol, 10, {gasLimit: 250000}))
    //     .to.not.equal(Number(0));
    // });
});