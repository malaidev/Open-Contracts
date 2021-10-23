const {expect, use}  = require( 'chai');
const {deployContract, MockProvider, solidity} = require ('ethereum-waffle');

use(solidity);

describe("AccessRegistry", async () => {

    let tokenList;
    let comptroller;
    let reserve;
    let deposit;
    let oracle;
    let loan;
    let liquidator;
    let accessRegistry;
    
    const [wallet, account1, account2] = new MockProvider().getWallets();
    const TokenList = require('../build/contracts/TokenList.json');
    const Comptroller = require('../build/contracts/Comptroller.json');
    const Deposit = require("../build/contracts/Deposit.json");
    const OracleOpen  = require("../build/contracts/OracleOpen.json");
    const Reserve = require("../build/contracts/Reserve.json");
    const Liquidator = require("../build/contracts/Liquidator.json");
    const Loan = require("../build/contracts/Loan.json");
    const AccessRegistry = require('../build/contracts/AccessRegistry.json');

    const role1 = "0x94557374737472696e6700000000000000000000000000000000000000000000";
    const role2 = "0x78629858A2529819179178979ABD797997979AD97987979AC7979797979797DF";
    const roleAdmin1 = "0x94557374737472696e6700120000000000000000000000000000000000000000";
    const roleAdmin2 = "0x78629858A2529819179178879ABD797997979AD97987979AC7979797979797DF";

    before(async () => {
        
        tokenList = await deployContract(wallet, TokenList, [wallet.address]);
        comptroller = await deployContract(wallet, Comptroller, [wallet.address]);
        deposit = await deployContract(wallet, Deposit, [wallet.address, tokenList.address, comptroller.address]);
        oracle = await deployContract(wallet, OracleOpen, [wallet.address]);
        liquidator = await deployContract(wallet, Liquidator, [wallet.address, tokenList.address]);
        reserve = await deployContract(wallet, Reserve, [wallet.address, deposit.address]);
        await deposit.connect(wallet).setReserveAddress(reserve.address, {gasLimit: 2500000});
        loan = await deployContract(wallet, Loan, [
            wallet.address,
            tokenList.address,
            comptroller.address,
            reserve.address,
            liquidator.address,
            oracle.address
        ]);
        await reserve.connect(wallet).setLoanAddress(loan.address, {gasLimit: 250000});
        await oracle.connect(wallet).setLoanAddress(loan.address, {gasLimit: 250000});

        accessRegistry = await deployContract(wallet, AccessRegistry, [wallet.address,tokenList.address, comptroller.address, reserve.address, deposit.address, oracle.address, loan.address, liquidator.address]);
    });

    it("Check if the contract is deployed", async () => {
        expect(await tokenList.addrss).to.not.equal("0x" + "0".repeat(40));
        expect(await accessRegistry.address).to.not.equal("0x" + "0".repeat(40));
        console.log("AccessRegistry is deployed at: ", accessRegistry.address);
    });

    it("Add Role", async () => {
        await accessRegistry.addRole(role1, account1.address);
        await accessRegistry.addRole(role1, account2.address);
        await accessRegistry.addRole(role2, account1.address);
        await accessRegistry.addRole(role2, account2.address);
        expect(await accessRegistry.hasRole(role1, account1.address)).to.be.equal(true);
        expect(await accessRegistry.hasRole(role2, account2.address)).to.be.equal(true);
        expect(await accessRegistry.hasRole(role1, account2.address)).to.be.equal(true);
        expect(await accessRegistry.hasRole(role2, account1.address)).to.be.equal(true);
    });

    it("Remove Role", async () => {
        await accessRegistry.removeRole(role1, account1.address);
        expect(await accessRegistry.hasRole(role1, account1.address)).to.be.equal(false);
        await accessRegistry.removeRole(role2, account2.address);
        expect(await accessRegistry.hasRole(role2, account2.address)).to.be.equal(false);
    });

    it("Transfer Role", async () => {
        await accessRegistry.connect(account1)
            .transferRole(role2, account1.address, account2.address, {gasLimit: 250000});
        expect(await accessRegistry.hasRole(role2, account1.address)).to.be.equal(false);
        expect(await accessRegistry.hasRole(role2, account2.address)).to.be.equal(true);
    });

    it("Renounce Role", async () => {
        expect(await accessRegistry.hasRole(role1, account2.address)).to.be.equal(true);
        await expect(accessRegistry.connect(account1).renounceRole(
            role1, 
            account2.address,
            {gasLimit: 250000}
        ))
        .to.revertedWith("Inadequate permissions");

        await accessRegistry.connect(account2).renounceRole(role1, account2.address, {gasLimit: 250000});
        expect(await accessRegistry.hasRole(role1, account2.address)).to.be.equal(false);
    });

    it("Add Admin Role", async () => {
        await accessRegistry.addAdminRole(roleAdmin1, account1.address);
        expect(await accessRegistry.hasAdminRole(roleAdmin1, account1.address)).to.be.equal(true);
        await accessRegistry.addAdminRole(roleAdmin1, account2.address);
        expect(await accessRegistry.hasAdminRole(roleAdmin1, account1.address)).to.be.equal(true);
        await accessRegistry.addAdminRole(roleAdmin2, account1.address);
        expect(await accessRegistry.hasAdminRole(roleAdmin1, account1.address)).to.be.equal(true);
    });

    it("Remove Admin Role", async () => {
        await accessRegistry.connect(account1).removeAdminRole(roleAdmin1, account1.address, {gasLimit: 250000});
        expect(await accessRegistry.hasAdminRole(roleAdmin1, account1.address)).to.be.equal(false);
        await expect(accessRegistry.connect(account1).removeAdminRole(roleAdmin2, account2.address, {gasLimit: 250000})).to.be.revertedWith("Role does not exist.");
    });

    it("Transfer Admin Role", async () => {
        await accessRegistry.connect(account1)
            .adminRoleTransfer(roleAdmin2, account1.address, account2.address, {gasLimit: 250000});
        expect(await accessRegistry.hasAdminRole(roleAdmin2, account1.address)).to.be.equal(false);
        expect(await accessRegistry.hasAdminRole(roleAdmin2, account2.address)).to.be.equal(true);
    });

    it("Renounce Admin Role", async () => {
        expect(await accessRegistry.hasAdminRole(roleAdmin1, account2.address)).to.be.equal(true);
        await expect(accessRegistry.connect(account1).adminRoleRenounce(
            roleAdmin1, 
            account2.address,
            {gasLimit: 250000}
        ))
        .to.revertedWith("Inadequate permissions");

        await accessRegistry.connect(account2).adminRoleRenounce(roleAdmin1, account2.address, {gasLimit: 250000});
        expect(await accessRegistry.hasAdminRole(roleAdmin1, account2.address)).to.be.equal(false);
    });
});