const TokenList = artifacts.require("TokenList");
const AccessRegistry = artifacts.require("AccessRegistry");
const Comptroller = artifacts.require("Comptroller");
const Reserve = artifacts.require("Reserve");
const Deposit = artifacts.require("Deposit");
const Liquidator = artifacts.require("Liquidator");
const Loan = artifacts.require("Loan");
const OracleOpen = artifacts.require("OracleOpen");
const ProxyAccessRegistry = artifacts.require("ProxyAccessRegistry");

module.exports = function (deployer, network, accounts) {
  
  await deployer.deploy(TokenList, accounts[0]);
  const tokenList = TokenList.deployed();
  console.log("TokenList is deployed at : ", tokenList.address);
  
  await deployer.deploy(Comptroller, accounts[0]);
  const comptroller = Comptroller.deployed();
  
  await deployer.deploy(Reserve, accounts[0]);
  const reserve = Reserve.deployed();
  
  await deployer.deploy(Liquidator, accounts[0]);
  const liquidator = Liquidator.deployed();
  
  await deployer.deploy(
    Deposit, 
    accounts[0],
    tokenList.address,
    comptroller.address,
    reserve.address
  );
  const deposit = Deposit.deployed();
  
  await deployer.deploy(OracleOpen, accounts[0], accessRegistry, tokenList);
  const oracleOpen = OracleOpen.deployed();
  
  await deployer.deploy(Loan, accounts[0]);
  const loan = Loan.deployed();

  await deployer.deploy(
    AccessRegistry, 
    accounts[0],
    tokenList.address,
    comptroller.address, 
    reserve.address,
    deposit.address,
    oracleOpen.address,
    loan.address,
    liquidator.address
  );
};
