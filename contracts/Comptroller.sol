// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;
import "./util/Address.sol";
import "./Library/OpenLibrary.sol";

contract Comptroller  {
  using Address for address;
  // struct SupportedAssets  {
  //   bytes32 symbol;
  //   uint160 decimals;
  //   address contractAddress;
  // }

  // mapping(bytes32 => bool) isTokenSupported;

  function liquidationTrigger() external {}



  // SETTERS
  function updateApr() external {}
  function updateLoanIssuanceFees() external {}
  function updateLoanClosureFees() external {}
  function updateLoanpreClosureFees() external {}
  function updateDepositPreclosureFees() external {}
  function updateSwitchDepositTypeFee() external {}

  function setReserveFactor() external  {} // sets a factor from 0 ot 1. This factor is the minimum reserves in the system.
  function setMaxWithdrawal() external  {} // this function sets a maximum permissible amount that can be moved in a single transaction without the admin permissions.

}


// calcYield()
// calcInterest()
// struct Passbook()
// struct InterestRates()
// struct ApyLedger()
// struct AprLedger()
// struct SupportedAssets {}
// updateCdr()
// updateApy()
// updateApr()
// updatePreclosureCharges()
// updateLoanIssuanceFees()
// updateLoanClosureFees()
// priceOracle()
// balancingAccounts()
// liquidationTrigger()
// liquidationCall()



// fallback() / receive()
// transferAnyERC20()
// pause
// auth(superAdmin || adminComptroller)