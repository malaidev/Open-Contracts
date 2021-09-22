// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

contract Loan {
  function borrow() external {}
  function _borrow() internal {}

  function permissibleWithdrawal() external returns(bool) {}
  function _permissibleWithdrawal() internal returns(bool) {}

  function switchLoanType() external {}
  function _switchLoanType() internal {}

  function currentApr() public  {}

  function _calcCdr() internal {} // performs a cdr check internally
}