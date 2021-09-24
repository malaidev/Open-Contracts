// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;
import "./util/Address.sol";

contract Comptroller  {
  using Address for address;

  bytes32 adminComptroller;
  address adminComptrollerAddress;

  uint apr;
  uint apy;

  struct APY  {
    uint timestamp;
    uint apy;
  }

  struct APR  {
    uint timestamp;
    uint apr;
  }

  APY[] apyRegistry; // stores a record of all the apr. the latest one being the last
  APR[] aprRegistry; // stores a record of all the apr. the latest one being the last
  
  // [N2S] 
  // 1. Whenever someone is taking a loan, record the position of the current
  //    apr in the apr registry. This will mitigate unnecessary loops inside
  //    this array
  //  Implement the same aproach with the deposits.

  event Deposit (address indexed account, uint indexed amount, bytes32 indexed symbol, uint timestamp);
  event Withdrawl (address indexed account, uint indexed amount, bytes32 indexed symbol, uint timestamp);
  event APRupdated(address indexed admin, uint indexed newAPR, uint oldAPR, uint indexed timestamp);
  event APYupdated(address indexed admin, uint indexed newAPY, uint oldAPY, uint indexed timestamp);
  
  constructor(uint apy_, uint apr_) {
    adminComptrollerAddress = msg.sender;

    _updateAPY(apy_);
    _updateAPR(apr_);
  }

  function getAPR() public view returns (uint) {
    return apr;
  }
  function getAPY() public view returns (uint) {
    return apy;
  }

  function liquidationTrigger() external {}

  // SETTERS


  function updateAPY(uint apy_) external onlyAdmin() {
    // pre process checks

    _updateAPY(apy_);
    uint index = apyRegistry.length-1;
    uint oldAPY = apyRegistry[index].apy;

    emit APYupdated(msg.sender, apy_, oldAPY, block.number);
  }
  function updateAPR(uint apr_) external onlyAdmin() {
    // pre process checks
    _updateAPR(apr_);
    uint index = aprRegistry.length-1;
    uint oldAPR = aprRegistry[index].apr;
    emit APRupdated(msg.sender, apr_, oldAPR, block.number);
  }

  function _updateAPY(uint apy_) internal  {
    apr = apy_;
    apyRegistry.push(APY(block.number, apy_));
  }
  function _updateAPR(uint apr_) internal {
    apr = apr_;
    aprRegistry.push(APR(block.number, apr_));
  }


  function updateLoanIssuanceFees() external onlyAdmin() {}
  function updateLoanClosureFees() external onlyAdmin() {}
  function updateLoanpreClosureFees() external onlyAdmin() {}
  function updateDepositPreclosureFees() external onlyAdmin() {}
  function updateSwitchDepositTypeFee() external onlyAdmin() {}

  function updateReserveFactor() external  onlyAdmin() {} // sets a factor from 0 ot 1. This factor is the minimum reserves in the system.
  function updateMaxWithdrawal() external  onlyAdmin() {} // this function sets a maximum permissible amount that can be moved in a single transaction without the admin permissions.
  

  modifier onlyAdmin() {
    require(msg.sender == adminComptrollerAddress, "Only the comptroller admin can modify this function" );
    _;
  }

}


// calcYield()
// calcInterest()
// struct Passbook()
// struct InterestRates()
// struct ApyLedger()
// struct APRLedger()
// struct SupportedAssets {}
// updateCdr()
// updateApy()
// updateAPR()
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



// [N2S]  Friday  10pm.
  // 1. Whenever someone is taking a loan, record the position of the current
  //    apr in the apr registry. This will mitigate unnecessary loops inside
  //    this array
  //  Implement the same aproach with the deposits.