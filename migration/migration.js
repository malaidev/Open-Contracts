const AccessRegistry = artifacts.require("AccessRegistry");

module.exports = async function (deployer, network, accounts) {
  // deployment steps
  await deployer.deploy(AccessRegistry);
};