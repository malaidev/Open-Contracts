var fs = require('fs');
const TokenList = artifacts.require("TokenList");
const AccessRegistry = artifacts.require("AccessRegistry");
const Comptroller = artifacts.require("Comptroller");
const Reserve = artifacts.require("Reserve");
const Deposit = artifacts.require("Deposit");
const Liquidator = artifacts.require("Liquidator");
const Loan = artifacts.require("Loan");
const OracleOpen = artifacts.require("OracleOpen");

const contracts = require("../contracts.json");
const configs = require("../configs.json");

module.exports = async function (deployer, network, accounts) {
  
  let dataParse = contracts;

  if(!configs.TokenList) {
    await deployer.deploy(TokenList, accounts[0]);
    var tokenList = await TokenList.deployed();
    dataParse['TokenList'] = tokenList.address;
  }
  else {
    var tokenList = await TokenList.at(configs.TokenList);
    dataParse['TokenList'] = configs.TokenList;
  }
  console.log("TokenList deployed at: ", dataParse['TokenList']);

  if(!configs.Comptroller) {
    await deployer.deploy(Comptroller, accounts[0]);
    var comptroller = await Comptroller.deployed();
    dataParse['Comptroller'] = comptroller.address;    
  }
  else {
    var comptroller = await Comptroller.at(configs.Comptroller);
    dataParse['Comptroller'] = configs.Comptroller;
  }
  console.log("Comptroller deployed at: ", dataParse['Comptroller']);
  
  if(!configs.Liquidator) {
    await deployer.deploy(Liquidator, accounts[0], tokenList.address);
    var liquidator = await Liquidator.deployed();
    dataParse['Liquidator'] = liquidator.address;
  }
  else {
    var liquidator = await Liquidator.at(configs.Liquidator);
    dataParse['Liquidator'] = configs.Liquidator;
  }
  console.log("Liquidator deployed at: ", dataParse['Liquidator']);

  if(!configs.Deposit) {
    await deployer.deploy(
      Deposit, 
      accounts[0],
      dataParse['TokenList'],
      dataParse['Comptroller']
    );
    var deposit = await Deposit.deployed();
    dataParse['Deposit'] = deposit.address;
  }
  else {
    var deposit = await Deposit.at(configs.Deposit);
    dataParse['Deposit'] = configs.Deposit;
  }
  console.log("Deposit deployed at: ", dataParse['Deposit']);

  if(!configs.Reserve) {
    await deployer.deploy(Reserve, accounts[0], deposit.address);
    var reserve = await Reserve.deployed();
    dataParse['Reserve'] = reserve.address;
  }
  else {
    var reserve = await Reserve.at(configs.Reserve);
    dataParse['Reserve'] = configs.Reserve;
  }
  console.log("Reserve deployed at: ", dataParse['Reserve']);

  await deposit.setReserveAddress(reserve.address);

  if(!configs.OracleOpen) {
    await deployer.deploy(OracleOpen, accounts[0]);
    var oracleOpen = await OracleOpen.deployed();
    dataParse['OracleOpen'] = oracleOpen.address;  
  }
  else {
    var oracleOpen = await OracleOpen.at(configs.OracleOpen);
    dataParse['OracleOpen'] = configs.OracleOpen;
  }
  console.log("OracleOpen deployed at: ", dataParse['OracleOpen']);

  if(!configs.Loan) {
    await deployer.deploy(Loan, accounts[0], tokenList, comptroller, reserve, liquidator, oracleOpen);
    var loan = await Loan.deployed();
    dataParse['Loan'] = loan.address;  
  }
  else {
    var loan = await Loan.at(configs.Loan);
    dataParse['Loan'] = configs.Loan;
  }
  console.log("Loan deployed at: ", dataParse['Loan']);

  await reserve.setLoanAddress(loan.address);

  await oracleOpen.setLoanAddress(loan.address);

  if(!configs.AccessRegistry) {
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
    var accessRegistry = await AccessRegistry.deployed();
    dataParse['AccessRegistry'] = accessRegistry.address;
  }
  else {
    var accessRegistry = await AccessRegistry.at(configs.AccessRegistry);
    dataParse['AccessRegistry'] = configs.AccessRegistry;
  }
  console.log("AccessRegistry deployed at: ", dataParse['AccessRegistry']);

  const updatedData = JSON.stringify(dataParse);
  await fs.promises.writeFile('contracts.json', updatedData);

};
