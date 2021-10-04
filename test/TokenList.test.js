const {expect, use}  = require( 'chai');
// const {Contract, utils} = require( 'ethers');
const {deployContract, MockProvider, solidity} = require ('ethereum-waffle');

use(solidity);

describe("TokenList", () => {
    let contract;
    const [wallet, account1] = new MockProvider().getWallets();
    const TokenList = require('../build/contracts/TokenList.json');

    const token1 = {
        symbol: "0x74657374737472696e6700000000000000000000000000000000000000000000",
        decimals: Number(18),
        address: "0x657374737472696e670000000000000000000000"
    };

    const token2 = {
        symbol: "0x25B29858A2529819179178979ABD797997979AD97987979AC7979797979797DF",
        decimals: Number(18),
        address: "0xB29858A2529819179178979AbD797997979aD979"
    }

    before(async () => {
        contract = await deployContract(wallet, TokenList);
    });
    
    it("Check if the contract is deployed", async () => {
        expect(contract.address).to.not.equal("0x" + "0".repeat(40));
        console.log("TokenList is deployed at ", contract.address);
    });

    it("Is supported err in Empty Token return", async () => {
        await expect(contract.isTokenSupported(token1.symbol)).to.be.revertedWith("Hey, Token is not supported");
    });

    it("Add new Token", async () => {
        await expect(contract.connect(account1).addTokenSupport(
            token1.symbol, 
            token1.decimals, 
            token1.address, 
            {gasLimit: 250000}
        ))
        .to.emit(contract, "TokenSupportAdded");

        expect(await contract.isTokenSupported(token1.symbol)).to.be.equal(true);
    });

    it("Update the token", async () => {
        await expect(contract.connect(account1).updateTokenSupport(
            token1.symbol, 
            token2.decimals, 
            token2.address, 
            {gasLimit: 250000}
        ))
        .to.emit(contract, "TokenSupportUpdated");

        const token = await contract.tokenPointer(token1.symbol);

        expect(token.tokenAddress).to.be.equal(token2.address);

        expect(await contract.isTokenSupported(token1.symbol)).to.be.equal(true);
    });

    it("Remove the token", async () => {
        await expect(contract.connect(account1).removeTokenSupport(
            token1.symbol, 
            {gasLimit: 250000}
        ))
        .to.emit(contract, "TokenSupportRemoved");

        await expect(contract.isTokenSupported(token1.symbol)).to.be.revertedWith("Hey, Token is not supported");
    });
});