// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;
import "./util/Address.sol";
import "./Library/OpenLibrary.sol";

contract Passbook  {
  
  using Address for address;

  // enum ENTRY {DEPOSIT, LOAN}
  enum ENTRYTYPE {FIXED, FLEXIBLE}

  // ENTRY entry;
  bytes32[] validity; // zeroweeks, twoweeks, onemonth, three months. Fed during the contract construction.
  
  // struct AccountPassbook {
  //   uint initialBlock; // blockNUmber when the passbook was created.
  //   bytes32[] records; //records of individual deposits & withdrwals. When a deposit is withdrawN, remove it from the AccountPassbook
  //   mapping(address => uint) checkRecord; //checks if the entry exists. AccountPassbook.checkRecord.msg.sender != 0.
  //   // mapping(ENTRY => mapping(ENTRYTYPE => bytes32)) entryType;
  //   mapping(ENTRYTYPE => bytes32) entryType; 
  //   Entry[] entries;
  // }

  struct AccountPassbook  {
    uint initialBlock; // Block number when the account was created.
    Entry[] _entries; // A struct of all the deposits.
    Dividends[] _dividends; // A struct
  }
  
  // hasAccount; if (AccountPassbook._entries.length == 0)  { return 'No
  // account';} 
  

  mapping(address => AccountPassbook) passbook;

  struct Record  {
    uint id; // id  == AccountPassbook._entries.length;
    uint entryBlock; // blockNUmber when the this Record was created.
    bytes32 symbol; // based on the symbol, we can fetch the contractAddress & decimals from the TokenRegistry struct in TokenList contract.
    uint amount;
    mapping(ENTRYTYPE => bytes32) _depositTypeWValidity;
    bool dividend; // true or false. If true, you look for an entry inside the dividend struct. If false, you move on.
    bool withDrawalTimelock; // applicable or not.
  }

  //  Fixed deposits with dividends as true calculate their dividends indiivduall
  struct Dividends  {
    uint id; // id  == AccountPassbook.entries.length;
    uint entryBlock; 
    bytes32 symbol;
    uint amount;
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


  mapping(address => AccountPassbook) hasAccountPassbook; // checks if the account has an account with Open protocol.
  mapping(address => LoanAccount) hasLoanAccount; // checks if there is any outstanding loan against the account

//  Loan account is same as Account passbook, but is a separate account
  struct LoanAccount {
    uint initialBlock; // blockNUmber when the first loan was created
    bytes32[] records; //records of borrow & repayments.
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
  
  function hasAccount(address account_) external view returns(bytes32) {
    _hasAccount(account_);
    return "Account Exists";
  }

  function _hasAccount(address account_) internal view  {
    require(passbook[account_]._entries.length!=0, "Account does not exist.");
    return this;
  }



  // struct passbookFilters {
  //   mapping(address => mapping(ENTRY => ENTRYTYPE)) _ENTRYTYPERecords; // deposit/fixed etc.
  // }

  mapping(address => AccountPassbook) accountENTRYment; // maps an addres to its struct.

  struct Collateral   {
    uint initTimestamp; // conversion blocknumber
    uint amount;
    uint loanId;
  }



  constructor () {
    validity.push('NO');
    validity.push('TWOWEEKS');
    validity.push('ONEMONTH');
    validity.push('THREEMONTHS');
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