// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./TokenList.sol";
import "./util/Address.sol";

// import "./Library/OpenLibrary.sol";

contract Deposit {
  using Address for address;
  function deposit() external returns (bool) {}

  function _deposit() internal {}

  function withdrawDeposit() external returns (bool) {}

  function _withdrawDeposit() internal returns (bool) {}

  function switchDepositType() external {}

  function _switchDepositType() internal {}

  function convertDepositToCollateral() external {}
  function _convertDepositToCollateral() internal {}
}
