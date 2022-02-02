const { expect } = require("chai");

describe("AccessRegistry", function() {
  it('works', async () => {
    const AccessRegistry = await ethers.getContractFactory("AccessRegistry");
    const AccessRegistryV2 = await ethers.getContractFactory("AccessRegistryV2");
  
    const instance = await upgrades.deployProxy(AccessRegistry,msg.sender);
    const upgraded = await upgrades.upgradeProxy(instance.address, AccessRegistryV2);

    const contractOwner = await upgraded.contractOwner();
    expect(contractOwner.toString()).to.equal(msg.sender);
  });
});