// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;
import "./util/Address.sol";
import "./Passbook.sol";

contract Comptroller  {
  using Address for address;

  Passbook passbook = Passbook(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);

  bytes32 adminComptroller;
  address adminComptrollerAddress;

  uint apr;
  uint apy;

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

  // ledger of APY/APR changes
  
  // Latest Individual apy/apr data
  mapping(bytes32 => APY) indAPYRecords; // commitment => APY struc
  mapping(bytes32 => APR) indAPRRecords; // commitment => APR struct.


  event Deposit (address indexed account, uint indexed amount, bytes32 indexed symbol, uint timestamp); // block.number;
  event Withdrawl (address indexed account, uint indexed amount, bytes32 indexed symbol, uint timestamp); // block.number;
  event APRupdated(address indexed admin, uint indexed newAPR, uint oldAPR, uint indexed timestamp); // block.number;
  event APYupdated(address indexed admin, uint indexed newAPY, uint oldAPY, uint indexed timestamp); // block.number;
  
  constructor(uint apy_, uint apr_) {
    adminComptrollerAddress = msg.sender;

    _updateAPY(apy_);
    _updateAPR(apr_);
  }

  function getAPR() public view returns (uint) {
    return apr;
  }
  function getAPY(bytes32 commitment_) public view returns (uint) {
    _getAPY(commitment_);
  }


  function _getAPY(bytes32 commitment_) internal  {
    return indAPYRecords.commitment_.apy;
  }

  function liquidationTrigger() external {}

  // SETTERS
  function _updateAPY(bytes32 commitment_, uint apy_) internal returns (bool) {

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