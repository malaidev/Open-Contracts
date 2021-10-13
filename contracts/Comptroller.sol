// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import "./util/Address.sol";
import "./util/Pausable.sol";
import "./util/IBEP20.sol";

contract Comptroller is Pausable {
	using Address for address;

	bytes32 adminComptroller;
	address adminComptrollerAddress;
	address superAdminAddress;

	// uint public latestAPR;
	// uint public latestAPY;
	
	bytes32[] internal commitment;
	uint reserveFactor;

/// @notice each APY or APR struct holds the recorded changes in interest data & the
/// corresponding time for a particular commitment type.
	struct APY  {
		bytes32 commitment; 
		uint[] time; // ledger of time when the APY changes were made.
		uint[] apyChangeRecords; // ledger of APY changes.
	}

	struct APR  {
		bytes32 commitment; // validity
		uint[] time; // ledger of time when the APR changes were made.
		uint[] aprChangeRecords; // Per block.timestamp APR is tabulated in here.
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
	
	function getAPR(bytes32 commitment_) external view returns (uint) {
		return _getAPR(commitment_);
	}
	function getAPR(bytes32 commitment_, uint index) external view returns (uint) {
		return _getAPR(commitment_, index);
	}

	// function getAPY() external view returns (uint) {
	//   return apy;
	// }

	function getAPY(bytes32 commitment_) external view returns (uint) {
		return _getAPY(commitment_);
	}

	function getAPY(bytes32 commitment_, uint index_) external view returns (uint) {
		return _getAPY(commitment_, index_);
	}

	function getApytimeber(bytes32 commitment_, uint index_) external view returns (uint){
		return _getApytimeber(commitment_, index_);
	}

	function getAprtimeber(bytes32 commitment_, uint index_) external view returns (uint){
		return _getAprtimeber(commitment_, index_);
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

	function _getApytimeber(bytes32 commitment_, uint index_) internal view returns (uint) {
		return indAPYRecords[commitment_].time[index_];
	}

	function _getAprtimeber(bytes32 commitment_, uint index_) internal view returns (uint) {
		return indAPRRecords[commitment_].time[index_];
	}

	function liquidationTrigger(uint loanID) external {}

	// SETTERS
	function updateAPY(bytes32 commitment_, uint apy_) external authComptroller() returns (bool) {
		return _updateApy(commitment_, apy_);
	}

	function updateAPR(bytes32 commitment_, uint apr_) external authComptroller() returns (bool ){
		return _updateApr(commitment_, apr_);
	}

	function _updateApy(bytes32 commitment_, uint apy_) internal returns (bool) {
		APY storage apyUpdate = indAPYRecords[commitment_];

		if(apyUpdate.time.length != apyUpdate.apyChangeRecords.length) return false;

		apyUpdate.commitment = commitment_;
		apyUpdate.time.push(block.number);
		apyUpdate.apyChangeRecords.push(apy_);
		return true;
	}
	
	function _updateApr(bytes32 commitment_, uint apr_) internal returns (bool) {
		APR storage aprUpdate = indAPRRecords[commitment_];

		if(aprUpdate.time.length != aprUpdate.aprChangeRecords.length) return false;

		aprUpdate.commitment = commitment_;
		aprUpdate.time.push(block.number);
		aprUpdate.aprChangeRecords.push(apr_);
		return true;
	}

	function _calcAPR(address _account, bytes32 _commitment, uint oldLengthAccruedInterest, uint oldTime, uint aggregateInterest) internal view {
		
		APR storage apr = indAPRRecords[_commitment];

		uint256 index = oldLengthAccruedInterest - 1;
		uint256 time = oldTime;

		// 1. apr.time.length > oldLengthAccruedInterest => there is some change.

		if (apr.time.length > oldLengthAccruedInterest)  {

			if (apr.time[index] < time) {
				uint256 newIndex = index + 1;
				// Convert the aprChangeRecords to the lowest unit value.
				aggregateInterest = (((apr.time[newIndex] - time) *apr.aprChangeRecords[index])/100)*365/(100*1000);
			
				for (uint256 i = newIndex; i < apr.aprChangeRecords.length; i++) {
					uint256 timeDiff = apr.time[i + 1] - apr.time[i];
					aggregateInterest += (timeDiff*apr.aprChangeRecords[newIndex] / 100)*365/(100*1000);
				}
			}
			else if (apr.time[index] == time) {
				for (uint256 i = index; i < apr.aprChangeRecords.length; i++) {
					uint256 timeDiff = apr.time[i + 1] - apr.time[i];
					aggregateInterest += (timeDiff*apr.aprChangeRecords[index] / 100)*365/(100*1000);
				}
			}
		} else if (apr.time.length == oldLengthAccruedInterest && block.timestamp > oldLengthAccruedInterest) {
			if (apr.time[index] < time || apr.time[index] == time) {
				aggregateInterest += (block.timestamp - time)*apr.aprChangeRecords[index]/100;
				// Convert the aprChangeRecords to the lowest unit value.
				// aggregateYield = (((apr.time[newIndex] - time) *apr.aprChangeRecords[index])/100)*365/(100*1000);
			}
		}
		oldLengthAccruedInterest = apr.time.length;
		oldTime = block.timestamp;
	}


	function _calcAPY(address _account, bytes32 _commitment, uint oldLengthAccruedYield, uint oldTime, uint aggregateYield) internal  view {
		
		APY storage apy = indAPYRecords[_commitment];

		uint256 index = oldLengthAccruedYield - 1;
		uint256 time = oldTime;

		// 1. apr.time.length > oldLengthAccruedInterest => there is some change.

		if (apy.time.length > oldLengthAccruedYield)  {

			if (apy.time[index] < time) {
				uint256 newIndex = index + 1;
				// Convert the aprChangeRecords to the lowest unit value.
				aggregateYield = (((apy.time[newIndex] - time) *apy.apyChangeRecords[index])/100)*365/(100*1000);
			
				for (uint256 i = newIndex; i < apy.apyChangeRecords.length; i++) {
					uint256 timeDiff = apy.time[i + 1] - apy.time[i];
					aggregateYield += (timeDiff*apy.apyChangeRecords[newIndex] / 100)*365/(100*1000);
				}
			}
			else if (apy.time[index] == time) {
				for (uint256 i = index; i < apy.apyChangeRecords.length; i++) {
					uint256 timeDiff = apy.time[i + 1] - apy.time[i];
					aggregateYield += (timeDiff*apy.apyChangeRecords[index] / 100)*365/(100*1000);
				}
			}
		} else if (apy.time.length == oldLengthAccruedYield && block.timestamp > oldLengthAccruedYield) {
			if (apy.time[index] < time || apy.time[index] == time) {
				aggregateYield += (block.timestamp - time)*apy.apyChangeRecords[index]/100;
				// Convert the aprChangeRecords to the lowest unit value.
				// aggregateYield = (((apr.time[newIndex] - time) *apr.aprChangeRecords[index])/100)*365/(100*1000);
			}
		}
		oldLengthAccruedYield = apy.time.length;
		oldTime = block.timestamp;
	}

	function updateLoanIssuanceFees() external authComptroller() {}
	function updateLoanClosureFees() external authComptroller() {}
	function updateLoanpreClosureFees() external authComptroller() {}
	function updateDepositPreclosureFees() external authComptroller() {}
	function updateSwitchDepositTypeFee() external authComptroller() {}

	function updateReserveFactor(uint _reserveFactor) external  authComptroller() {
	 	// implementing the barebones version for testnet. 
		//  if cdr >= reserveFactor, 1:3 possible, else 1:2 possible.
		 reserveFactor = _reserveFactor;
	} 


	function updateMaxWithdrawal(uint factor, uint blockLimit) external  authComptroller() {} // this function sets a maximum permissible amount that can be moved in a single transaction without the admin permissions.


	modifier authComptroller() {
		require(msg.sender == adminComptrollerAddress,
			"Only the comptroller admin can modify this function" 
		);
		_;
	}

	function pause() external authComptroller() nonReentrant() {
			 _pause();
	}
	
	function unpause() external authComptroller() nonReentrant() {
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
