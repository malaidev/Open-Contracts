// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;
import "./util/Address.sol";
import "./Library/OpenLibrary.sol";

contract Comptroller  {
  using Address for address;

  enum STATE {DEPOSIT, LOAN}
  enum TYPE {FIXED, FLEXIBLE}

  STATE state;
  TYPE _type;

  bytes32[] validity; // zeroweeks, twoweeks, onemonth, three months.

  struct Passbook {
    address account;
    mapping(STATE => mapping(TYPE => bytes32)) transaction; // DEPOSIT => FIXED => ZERO
  }
  struct TxRecord  {
    bytes32 _token;
    uint amount;
    uint interestRate; // applicable interest. Positive for deposits, negative for withdrawals.
    uint initialTimestamp;// blockNumber
    bool _dividend; // true of false.
    bool 
  }

  event Deposit (address indexed account, uint indexed amount, bytes32 indexed symbol, uint timestamp);
  event Withdrawl (address indexed account, uint indexed amount, bytes32 indexed symbol, uint timestamp);
  
// **Deposit**
// - symbol
//   - token address
//   - decimals
// - amount
// - type & validity (fixed/flexible, validity)
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






  constructor () {
    validity.push('NO');
    validity.push('TWOWEEKS');
    validity.push('ONEMONTH');
    validity.push('THREEMONTHS');
  }

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




// create a passbook struct to store everything(deposits, debts, collaterals),
// along with the blocknumber. create a function that calculates the accrued apy
// for each individual deposit records since the last yield release. When the
// yield is released, the remnant depost amount becomes the deposit & the yield
// begins to be accrued from there.

//  If a deposit is withdrawn, then the sub-struct entry must be removed from
//  the passbook, and forwarded to the archived struct


//  Whatever remains in the passbook struct earns/pays interest.

