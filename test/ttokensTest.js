const { expect } = require("chai");
const { ethers } = require("hardhat");
const { assert } = require('chai')

async function deploytBTC() {
    // const accounts = await ethers.getSigners()

    const tBTC = await ethers.getContractFactory('tBTC')
    // const name_ = 'Bitcoin';
    // const symbol_ = 'BTC.t';
    // const decimals_ = 8;
    // const cappedSupply_ = 2100000000000000;
    const admin_ = '0x14e7bBbDAc66753AcABcbf3DFDb780C6bD357d8E'; // ERC20 address
    // const admin_ = 'one1znnmh0dvve6n4j4uhu7lmduqc67n2lvw256rhn'; // Harmony equivalent
    const tbtc = await tBTC.deploy(admin_)
    await tbtc.deployed()
    console.log("tBTC deployed: ", tbtc.address)

    return tbtc.address
}
describe("===== tTokens Test =====", function () {
    let tbtc
    let deposit
    before(async function () {
        const btcAddress = await deploytBTC()
        tbtc = await ethers.getContractAt('tBTC', btcAddress)

        console.log("Deploying deposit")

        const Deposit = await ethers.getContractFactory('Deposit')
        deposit = await Deposit.deploy()
        await deposit.deployed()
    })

    it("Token Mint", async () => {
        console.log(await tbtc.balanceOf(deposit.address))
        expect(await tbtc.balanceOf(deposit.address)).to.be.equal(0);
        await expect(tbtc.transfer(deposit.address, 1)).to.emit(tbtc, 'Transfer');
        expect(await tbtc.balanceOf(deposit.address)).to.equal(1);
    })
})
