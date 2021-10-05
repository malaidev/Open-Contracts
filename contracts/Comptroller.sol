// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;
import "./util/Address.sol";
import "./Passbook.sol";

contract Comptroller  {
  using Address for address;

  bytes32 adminComptroller;
  address adminComptrollerAddress;

  uint public apr;
  uint public apy;

  struct APY  {
    bytes32 commitment; // validity
    uint[] blockNumbers; // when the apy changes were made
    uint[] apyChangeRecords; // the apy changes.
  }

  struct APR  {
    bytes32 commitment; // validity
    uint[] blockNumbers; // when the apy changes were made
    uint[] aprChangeRecords; // the apy changes.
  }

  
  
  // Latest Individual apy/apr data
  mapping(bytes32 => APY) indAPYRecords;
  mapping(bytes32 => APR) indAPRRecords;


  event APRupdated(address indexed admin, uint indexed newAPR, uint oldAPR, uint indexed timestamp);
  event APYupdated(address indexed admin, uint indexed newAPY, uint oldAPY, uint indexed timestamp);
  
  constructor() {
    adminComptrollerAddress = msg.sender;
  }

  function getAPR() public view returns (uint) {
    return apr;
  }
  function getAPY(bytes32 commitment_) public view returns (uint) {
    _getAPY(commitment_);
  }


  function _getAPY(bytes32 commitment_) internal  {
    // return indAPYRecords.commitment_.apy;
  }

  function liquidationTrigger() external {}

  // SETTERS
  function _updateAPY(bytes32 commitment_, uint apy_) internal returns (bool) {

  }
  function _updateAPR(bytes32 commitment_, uint apy_) internal returns (bool) {

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



// struct ApyLedger()
// struct APRLedger()
// permissibleCDR()
// reserveFactor() - ReserveFactor is an integer from 1 to 100. Here 1 means 1%.
// 100 means 100%. Reserve factor determines the minimum reserves that need
// maintaining. Minimum reserves against the total deposits.

// permissionlessWithdrawal(uint factor, uint blockLimit) - This function like reserve factor takes an input
// from 1 to 100. If 1, it means, upto 1% of total available reserves can be
// released within a defined block limit. Eg: factor = 10, blockLimit = 4800.
// This means, 10% of reserves can be withdrawn during a 4800 bsc block window.
// This check is implemented to mitigate excess loss of funds during exploits.

// updateApy()
// updateAPR()
// updatePreclosureCharges()
// updateLoanIssuanceFees()
// updateLoanClosureFees()
// updateConvertYieldFees()



// fallback() / receive()
// transferAnyERC20()
// pause
// auth(superAdmin || adminComptroller)