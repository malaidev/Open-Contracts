// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;
import "./util/Address.sol";
import "./Library/OpenLibrary.sol";

contract Passbook  {
  
  using Address for address;

  enum ENTRY {DEPOSIT, LOAN}
  enum ENTRYTYPE {FIXED, FLEXIBLE}
  
  bytes32[] validity; // zeroweeks, twoweeks, onemonth, three months. Fed during the contract construction.
  
  struct Savings  {
    uint initialBlock; // Block number when the account was created.
    uint[] logger;
    Deposit[] _deposits; // A struct of all the deposits.
    // Withdrawals[] _withdrawals;
    // Dividends[] _dividends; // A struct
  }
  struct Loans  {
    uint initialBlock; // Block number when the account was created.
    uint[] logger;
    Deposit[] _deposits; // A struct of all the deposits.
    Withdrawals[] _withdrawals;
    Dividends[] _dividends; // A struct
  }

  mapping(address => Savings) savingsPassbook;
  mapping(address => Loans) loansPassbook;

  struct Deposit  {
    uint id; // id  == Savings.logger.length;
    uint blockNumber; // blockNUmber when the this Record was created.
    bytes32 symbol; // based on the symbol, we can fetch the contractAddress & decimals from the TokenRegistry struct in TokenList contract.
    uint amount; // based on the symbol, we can fetch the contractAddress & decimals from the TokenRegistry struct in TokenList contract.
    mapping(ENTRYTYPE => mapping(bytes32 => uint)) depositEntry; // amount deposited against the specific deposit type.
    bool dividend; // true or false. If true, you look for an entry inside the dividend struct. If false, you move on.
  }
  struct Dividends  {
    uint id; // id  == Savings.logger.length;
    uint blockNumber; // blockNUmber when the this Record was created.
    bytes32 symbol; // based on the symbol, we can fetch the contractAddress & decimals from the TokenRegistry struct in TokenList contract.
    uint amount; // based on the symbol, we can fetch the contractAddress & decimals from the TokenRegistry struct in TokenList contract.
    mapping(ENTRYTYPE => mapping(bytes32 => uint)) depositEntry; // amount deposited against the specific deposit type.
    bool dividend; // true or false. If true, you look for an entry inside the dividend struct. If false, you move on.
  }

  struct Loan {
    uint id; // id  == Loans.logger.length;
    uint blockNumber; // blockNUmber when the this Record was created.
    bytes32 symbol; // based on the symbol, we can fetch the contractAddress & decimals from the TokenRegistry struct in TokenList contract.
    uint amount;
    mapping(ENTRYTYPE => bytes32) _depositTypeWValidity;
    bool dividend; // true or false. If true, you look for an entry inside the dividend struct. If false, you move on.
    bool withDrawalTimelock; // applicable or not.
  }

  struct Withdrawals  {
    uint initialBlock; // blockNUmber when the first loan was created
  }

  // Loan struct integrates with collateral struct in which, the collateral
  // receives dripped interest deductions per bsc block


// Collaterals struct has a correlation with deposits in which, a deposit is
// converted into a collateral, and a collateral corresponding to fixed loan
// earns APY as a sub struct of deposit struct. The APY earned frmo the
// collaterals si added to the yield of the deposits when calculating the final apy

  struct collaterals  {
    uint id; // LoanAccount.records.length

  }
  struct Dividends  {
    uint text;
  }


  constructor () {
    validity.push('NONE');
    validity.push('TWOWEEKS');
    validity.push('ONEMONTH');
    validity.push('THREEMONTHS');
  }


  // **Deposit**
// - symbol
//   - token address
//   - decimals
// - amount
// - ENTRYTYPE & validity (fixed/flexible, validity)
// - blocknumber
// - currentApy
// - dividend applicable(?) // if fixed deposit.



// **Withdrawal()**
// - symbol
// - amount
// - checkFlexibleDeposit()
// - checkFixedDeposit()
// - totalAssetValue() // includes the accrued yield and dividend
// - Restrictions
//   - deposit locked(?) as collateral
//   - fixed deposit (withdrawal timelock applicable?)


//  Loan account is same as Account passbook, but is a separate account
  
  
  function hasAccount(address account_) external view returns(bytes32) {
    _hasAccount(account_);
    return "Account Exists";
  }

  function _hasAccount(address account_) internal view  {
    require(savingsPassbook[account_].logger.length!=0 || loansPassbook[account_].logger.length!=0, "Account does not exist.");
    // Every loan account has a savings account. But, I am thinking of breaking
    // it into two different parts so that, i have a clear demarcation.
  }

}

// fallback() / receive()
// transferAnyERC20()
// pause
// auth(superAdmin || adminComptroller)




// create a passbook struct to store everything(deposits, debts, collaterals),
// along with the blocknumber. create a function that calculates the accrued apy
// for each individual deposit records since the last yield release. When the
// yield is released, the remnant depost amount becomes the deposit & the yield
// begins to be accrued from there.

//  If a deposit is withdrawn, then the sub-struct entry must be removed from
//  the passbook, and forwarded to the archived struct


//  Whatever remains in the passbook struct earns/pays interest.



// 