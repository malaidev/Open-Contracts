// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;
import "./util/Address.sol";
import "./util/Pausable.sol";
import "./util/IBEP20.sol";

contract Comptroller is Pausable {
  using Address for address;

  bytes32 adminComptroller;
  address adminComptrollerAddress;
  address superAdminAddress;

  uint public apr;
  uint public apy;


/// @notice each APY or APR struct holds the recorded changes in interest data & the
/// corresponding blocknumbers for a particular commitment type.

  struct APY  {
    bytes32 commitment; 
    uint[] blockNumbers; // ledger of blockNumbers when the APY changes were made.
    uint[] apyChangeRecords; // ledger of APY changes.
  }

  struct APR  {
    bytes32 commitment; // validity
    uint[] blockNumbers; // ledger of blockNumbers when the APR changes were made.
    uint[] aprChangeRecords; // ledger of APR changes.
  }

  
  // Latest Individual apy/apr data
  mapping(bytes32 => APY) indAPYRecords;
  mapping(bytes32 => APR) indAPRRecords;


  event APRupdated(address indexed admin, uint indexed newAPR, uint oldAPR, uint indexed timestamp);
  event APYupdated(address indexed admin, uint indexed newAPY, uint oldAPY, uint indexed timestamp);
  
  constructor(address superAdminAddr_) {
    superAdminAddress = superAdminAddr_;
    adminComptrollerAddress = msg.sender;
  }
  
  receive() external payable {
     payable(adminComptrollerAddress).transfer(_msgValue());
  }
  
  fallback() external payable {
    payable(adminComptrollerAddress).transfer(_msgValue());
  }
  
  function transferAnyERC20(address token_,address recipient_,uint256 value_) external returns(bool) {
    IBEP20(token_).transfer(recipient_, value_);
    return true;
  }

  function getAPR() external view returns (uint) {
    return apr;
  }

  function getAPR(bytes32 commitment_) external view returns (uint) {
    return _getAPR(commitment_);
  }

  function getAPR(bytes32 commitment_, uint index_) external view returns (uint) {
    return _getAPR(commitment_, index_);
  }

  function getAPY() external view returns (uint) {
    return apy;
  }

  function getAPY(bytes32 commitment_) external view returns (uint) {
    return _getAPY(commitment_);
  }

  function getAPY(bytes32 commitment_, uint index_) external view returns (uint) {
    return _getAPY(commitment_, index_);
  }

  function getApyBlockNumber(bytes32 commitment_, uint index_) external view returns (uint){
    return _getApyBlockNumber(commitment_, index_);
  }

  function getAprBlockNumber(bytes32 commitment_, uint index_) external view returns (uint){
    return _getAprBlockNumber(commitment_, index_);
  }

  function getApyRecordCount(bytes32 commitment_) external view returns (uint) {
    return indAPYRecords[commitment_].apyChangeRecords.length;
  }

  function getAprRecordCount(bytes32 commitment_) external view returns (uint) {
    return indAPRRecords[commitment_].aprChangeRecords.length;
  }

  function _getAPY(bytes32 commitment_) internal view returns (uint) {
    return indAPYRecords[commitment_].apyChangeRecords[indAPYRecords[commitment_].apyChangeRecords.length - 1];
  }

  function _getAPY(bytes32 commitment_, uint index_) internal view returns (uint) {
    return indAPYRecords[commitment_].apyChangeRecords[index_];
  }

  function _getAPR(bytes32 commitment_) internal view returns (uint){
    return indAPRRecords[commitment_].aprChangeRecords[indAPRRecords[commitment_].aprChangeRecords.length - 1];
  }

  function _getAPR(bytes32 commitment_, uint index_) internal view returns (uint) {
    return indAPRRecords[commitment_].aprChangeRecords[index_];
  }

  function _getApyBlockNumber(bytes32 commitment_, uint index_) internal view returns (uint) {
    return indAPYRecords[commitment_].blockNumbers[index_];
  }

  function _getAprBlockNumber(bytes32 commitment_, uint index_) internal view returns (uint) {
    return indAPRRecords[commitment_].blockNumbers[index_];
  }

  function liquidationTrigger() external {}

  // SETTERS
  function updateAPY(bytes32 commitment_, uint apy_) external onlyAdmin returns (bool) {
    return _updateApy(commitment_, apy_);
  }

  function updateAPR(bytes32 commitment_, uint apr_) external onlyAdmin returns (bool ){
    return _updateApr(commitment_, apr_);
  }

  function _updateApy(bytes32 commitment_, uint apy_) internal returns (bool) {
    APY storage apyUpdate = indAPYRecords[commitment_];

    if(apyUpdate.blockNumbers.length != apyUpdate.apyChangeRecords.length) return false;

    apyUpdate.commitment = commitment_;
    apyUpdate.blockNumbers.push(block.number);
    apyUpdate.apyChangeRecords.push(apy_);
    return true;
  }
  
  function _updateApr(bytes32 commitment_, uint apr_) internal returns (bool) {
    APR storage aprUpdate = indAPRRecords[commitment_];

    if(aprUpdate.blockNumbers.length != aprUpdate.aprChangeRecords.length) return false;

    aprUpdate.commitment = commitment_;
    aprUpdate.blockNumbers.push(block.number);
    aprUpdate.aprChangeRecords.push(apr_);
    return true;
  }
  function _updateAPR(bytes32 commitment_, uint apy_) internal returns (bool) {

  }


  function updateLoanIssuanceFees() external onlyAdmin() {}
  function updateLoanClosureFees() external onlyAdmin() {}
  function updateLoanpreClosureFees() external onlyAdmin() {}
  function updateDepositPreclosureFees() external onlyAdmin() {}
  function updateSwitchDepositTypeFee() external onlyAdmin() {}

  function updateReserveFactor(uint reserveFactor) external  onlyAdmin() {} // sets a factor from 0 ot 1. This factor is the minimum reserves in the system.
  function updateMaxWithdrawal(uint factor, uint blockLimit) external  onlyAdmin() {} // this function sets a maximum permissible amount that can be moved in a single transaction without the admin permissions.

  modifier onlyAdmin() {
    require(msg.sender == adminComptrollerAddress
      || msg.sender == superAdminAddress, 
      "Only the comptroller admin can modify this function" 
    );
    _;
  }

  function pause() external onlyAdmin() nonReentrant() {
       _pause();
	}
	
	function unpause() external onlyAdmin() nonReentrant() {
       _unpause();   
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