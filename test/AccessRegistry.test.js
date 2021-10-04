const {expect, use}  = require( 'chai');
// const {Contract, utils} = require( 'ethers');
const {deployContract, MockProvider, solidity} = require ('ethereum-waffle');

use(solidity);

describe("ProxyAccessRegistry", () => {
    let contract;
    const [wallet, account1] = new MockProvider().getWallets();
    const ProxyAccessRegistry = require('../build/contracts/ProxyAccessRegistry.json');
    const AccessRegistry = require('../build/contracts/AccessRegistry.json');

    before(async () => {
        proxyContract1 = await deployContract(wallet, ProxyAccessRegistry);
        impContract1 = await deployContract(wallet, AccessRegistry, [proxyContract1.address]);
        impContract2 = await deployContract(wallet, AccessRegistry, [proxyContract1.address]);

        console.log("proxyContract1 Addr is ", proxyContract1.address);

        console.log("imp1 address is ", await impContract1.adminAddress());
        console.log("imp2 address is ", await impContract2.adminAddress());
    });

    it("Check if the contracts are deployed", async () => {
        expect(proxyContract1.address).to.not.equal("0x" + "0".repeat(40));
        expect(impContract1.address).to.not.equal("0x" + "0".repeat(40));
        expect(impContract2.address).to.not.equal("0x" + "0".repeat(40));
    });

    it("Check if initial imp address is 0", async () => {
        const addr = await proxyContract1.implementation();
        console.log("addr is ", addr);
        expect(await proxyContract1.implementation()).to.be.equal("0x" + "0".repeat(40));
    });
    
    it("Upgrade to imp1", async () => {
        await proxyContract1.upgradeTo(impContract1.address);
        expect(await proxyContract1.implementation()).to.be.equal(impContract1.address);
    });

    it("Upgrade to imp2", async () => {
        await proxyContract1.upgradeTo(impContract2.address);
        expect(await proxyContract1.implementation()).to.be.equal(impContract2.address);
    });

    it("Upgrade Proxy Owner", async () => {
        console.log("Old Proxy Owner is ", await proxyContract1.proxyOwner());
        proxyContract2 = await deployContract(wallet, ProxyAccessRegistry);
    
        await proxyContract1.transferProxyOwnership(proxyContract2.address);
        console.log("New Proxy Owner is ", await proxyContract1.proxyOwner());

        expect(await proxyContract1.proxyOwner()).to.be.equal(proxyContract2.address);
    });
});
describe("AccessRegistry", async () => {
    let contract;
    const [wallet, account1, account2] = new MockProvider().getWallets();
    const AccessRegistry = require('../build/contracts/AccessRegistry.json');
    const ProxyAccessRegistry = require('../build/contracts/ProxyAccessRegistry.json');
    const role1 = "0x94557374737472696e6700000000000000000000000000000000000000000000";
    const role2 = "0x78629858A2529819179178979ABD797997979AD97987979AC7979797979797DF";
    const roleAdmin1 = "0x94557374737472696e6700120000000000000000000000000000000000000000";
    const roleAdmin2 = "0x78629858A2529819179178879ABD797997979AD97987979AC7979797979797DF";

    before(async () => {
        proxyContract = await deployContract(wallet, ProxyAccessRegistry);
        contract = await deployContract(wallet, AccessRegistry, [proxyContract.address]);

        console.log("Contract addr is ", contract.address);
    });

    it("Check if the contract is deployed", async () => {
        expect(contract.address).to.not.equal("0x" + "0".repeat(40));
    });

    it("Add Role", async () => {
        await contract.addRole(role1, account1.address);
        await contract.addRole(role1, account2.address);
        await contract.addRole(role2, account1.address);
        await contract.addRole(role2, account2.address);
        expect(await contract.hasRole(role1, account1.address)).to.be.equal(true);
        expect(await contract.hasRole(role2, account2.address)).to.be.equal(true);
        expect(await contract.hasRole(role1, account2.address)).to.be.equal(true);
        expect(await contract.hasRole(role2, account1.address)).to.be.equal(true);
    });

    it("Remove Role", async () => {
        await contract.removeRole(role1, account1.address);
        expect(await contract.hasRole(role1, account1.address)).to.be.equal(false);
        await contract.removeRole(role2, account2.address);
        expect(await contract.hasRole(role2, account2.address)).to.be.equal(false);
    });

    it("Transfer Role", async () => {
        await contract.connect(account1)
            .transferRole(role2, account1.address, account2.address, {gasLimit: 250000});
        expect(await contract.hasRole(role2, account1.address)).to.be.equal(false);
        expect(await contract.hasRole(role2, account2.address)).to.be.equal(true);
    });

    it("Renounce Role", async () => {
        expect(await contract.hasRole(role1, account2.address)).to.be.equal(true);
        await expect(contract.connect(account1).renounceRole(
            role1, 
            account2.address,
            {gasLimit: 250000}
        ))
        .to.revertedWith("Inadequate permissions");

        await contract.connect(account2).renounceRole(role1, account2.address, {gasLimit: 250000});
        expect(await contract.hasRole(role1, account2.address)).to.be.equal(false);
    });

    it("Add Admin Role", async () => {
        await contract.addAdminRole(roleAdmin1, account1.address);
        expect(await contract.hasAdminRole(roleAdmin1, account1.address)).to.be.equal(true);
        await contract.addAdminRole(roleAdmin1, account2.address);
        expect(await contract.hasAdminRole(roleAdmin1, account1.address)).to.be.equal(true);
        await contract.addAdminRole(roleAdmin2, account1.address);
        expect(await contract.hasAdminRole(roleAdmin1, account1.address)).to.be.equal(true);
    });

    it("Remove Admin Role", async () => {
        await contract.connect(account1).removeAdminRole(roleAdmin1, account1.address, {gasLimit: 250000});
        expect(await contract.hasAdminRole(roleAdmin1, account1.address)).to.be.equal(false);
        await expect(contract.connect(account1).removeAdminRole(roleAdmin2, account2.address, {gasLimit: 250000})).to.be.revertedWith("Role does not exist.");
    });

    it("Transfer Admin Role", async () => {
        await contract.connect(account1)
            .adminRoleTransfer(roleAdmin2, account1.address, account2.address, {gasLimit: 250000});
        expect(await contract.hasAdminRole(roleAdmin2, account1.address)).to.be.equal(false);
        expect(await contract.hasAdminRole(roleAdmin2, account2.address)).to.be.equal(true);
    });

    it("Renounce Admin Role", async () => {
        expect(await contract.hasAdminRole(roleAdmin1, account2.address)).to.be.equal(true);
        await expect(contract.connect(account1).adminRoleRenounce(
            roleAdmin1, 
            account2.address,
            {gasLimit: 250000}
        ))
        .to.revertedWith("Inadequate permissions");

        await contract.connect(account2).adminRoleRenounce(roleAdmin1, account2.address, {gasLimit: 250000});
        expect(await contract.hasAdminRole(roleAdmin1, account2.address)).to.be.equal(false);
    });
});