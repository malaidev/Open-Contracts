// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import "./util/Address.sol";
import "./util/Pausable.sol";
// import "./mockup/IMockBep20.sol";
import "./util/IBEP20.sol";

contract Comptroller is Pausable {
	using Address for address;

	bytes32 adminComptroller;
	address adminComptrollerAddress;
	address superAdminAddress;

	// uint public latestAPR;
	// uint public latestAPY;
	
	bytes32[] commitment; // NONE, TWOWEEKS, ONEMONTH, THREEMONTHS
	
	uint public reserveFactor;
	uint public loanIssuanceFees;
	uint public loanClosureFees;
	uint public loanPreClosureFees;
	uint public depositPreClosureFees;
	uint public maxWithdrawalFactor;
	uint public maxWithdrawalBlockLimit;
	uint public depositWithdrawalFees;
	uint public collateralReleaseFees;
	uint public yieldConversionFees;
	uint public marketSwapFees;

/// @notice each APY or APR struct holds the recorded changes in interest data & the
/// corresponding time for a particular commitment type.
	struct APY  {
		bytes32 commitment; 
		uint[] time; // ledger of time when the APY changes were made.
		uint[] apyChanges; // ledger of APY changes.
	}

	struct APR  {
		bytes32 commitment; // validity
		uint[] time; // ledger of time when the APR changes were made.
		uint[] aprChanges; // Per block.timestamp APR is tabulated in here.
	}	
	// Latest Individual apy/apr data
	mapping(bytes32 => APY) indAPYRecords;
	mapping(bytes32 => APR) indAPRRecords;

	event APRupdated(address indexed admin, uint indexed newAPR, uint oldAPR, uint indexed timestamp);
	event APYupdated(address indexed admin, uint indexed newAPY, uint oldAPY, uint indexed timestamp);
	
	event ReserveFactorUpdated(address indexed admin, uint oldReserveFactor, uint indexed newReserveFactor, uint indexed timestamp);
	event LoanIssuanceFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event LoanClosureFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event LoanPreClosureFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event DepositPreClosureFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event DepositWithdrawalFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event CollateralReleaseFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event YieldConversionFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event MarketSwapFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event MaxWithdrawalUpdated(address indexed admin, uint indexed newFactor, uint indexed newBlockLimit, uint oldFactor, uint oldBlockLimit, uint timestamp);
	
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
	
	function transferAnyBEP20(address token_,address recipient_,uint256 value_) external authComptroller returns(bool) {
		IBEP20(token_).transfer(recipient_, value_);
		return true;
	}
	
	function getAPR(bytes32 _commitment) external view returns (uint) {
		return indAPRRecords[_commitment].aprChanges[indAPRRecords[_commitment].aprChanges.length - 1];
	}
	function getAPRInd(bytes32 _commitment, uint _index) external view returns (uint) {
		return indAPRRecords[_commitment].aprChanges[_index];
	}

	function getAPY(bytes32 _commitment) external view returns (uint) {
		return indAPYRecords[_commitment].apyChanges[indAPYRecords[_commitment].apyChanges.length - 1];
	}

	function getAPYInd(bytes32 _commitment, uint _index) external view returns (uint) {
		return indAPYRecords[_commitment].apyChanges[_index];
	}

	function getApytimeber(bytes32 _commitment, uint _index) external view returns (uint) {
		return indAPYRecords[_commitment].time[_index];
	}

	function getAprtimeber(bytes32 _commitment, uint _index) external view returns (uint) {
		return indAPRRecords[_commitment].time[_index];
	}

	function getApyLastTime(bytes32 commitment_) external view returns (uint) {
		return indAPYRecords[commitment_].time[indAPYRecords[commitment_].time.length - 1];
	}

	function getAprLastTime(bytes32 commitment_) external view returns (uint) {
		return indAPRRecords[commitment_].time[indAPRRecords[commitment_].time.length - 1];
	}

	function getApyTimeLength(bytes32 commitment_) external view returns (uint) {
		return indAPYRecords[commitment_].time.length;
	}

	function getAprTimeLength(bytes32 commitment_) external view returns (uint) {
		return indAPRRecords[commitment_].time.length;
	}

	function getCommitment(uint index_) external view returns (bytes32) {
		require(index_ < commitment.length, "Commitment Index out of range");
		return commitment[index_];
	}

	function setCommitment(bytes32 _commitment) external {
		commitment.push(_commitment);
	}

	function liquidationTrigger(uint loanID) external {}

	// SETTERS
	function updateAPY(bytes32 _commitment, uint _apy) external authComptroller() returns (bool) {
		return _updateApy(_commitment, _apy);
	}

	function updateAPR(bytes32 _commitment, uint _apr) external authComptroller() returns (bool ) {
		return _updateApr(_commitment, _apr);
	}

	function _updateApy(bytes32 _commitment, uint _apy) internal returns (bool) {
		APY storage apyUpdate = indAPYRecords[_commitment];

		if(apyUpdate.time.length != apyUpdate.apyChanges.length) return false;

		apyUpdate.commitment = _commitment;
		apyUpdate.time.push(block.timestamp);
		apyUpdate.apyChanges.push(_apy);
		return true;
	}
	
	function _updateApr(bytes32 _commitment, uint _apr) internal returns (bool) {
		APR storage aprUpdate = indAPRRecords[_commitment];

		if(aprUpdate.time.length != aprUpdate.aprChanges.length) return false;

		aprUpdate.commitment = _commitment;
		aprUpdate.time.push(block.timestamp);
		aprUpdate.aprChanges.push(_apr);
		return true;
	}

	function calcAPR(bytes32 _commitment, uint oldLengthAccruedInterest, uint oldTime, uint aggregateInterest) external view {
		
		APR storage apr = indAPRRecords[_commitment];

		uint256 index = oldLengthAccruedInterest - 1;
		uint256 time = oldTime;

		// // 1. apr.time.length > oldLengthAccruedInterest => there is some change.

		if (apr.time.length > oldLengthAccruedInterest)  {

			if (apr.time[index] < time) {
				uint256 newIndex = index + 1;
				// Convert the aprChanges to the lowest unit value.
				aggregateInterest = (((apr.time[newIndex] - time) *apr.aprChanges[index])/100)*365/(100*1000);
			
				for (uint256 i = newIndex; i < apr.aprChanges.length; i++) {
					uint256 timeDiff = apr.time[i + 1] - apr.time[i];
					aggregateInterest += (timeDiff*apr.aprChanges[newIndex] / 100)*365/(100*1000);
				}
			}
			else if (apr.time[index] == time) {
				for (uint256 i = index; i < apr.aprChanges.length; i++) {
					uint256 timeDiff = apr.time[i + 1] - apr.time[i];
					aggregateInterest += (timeDiff*apr.aprChanges[index] / 100)*365/(100*1000);
				}
			}
		} else if (apr.time.length == oldLengthAccruedInterest && block.timestamp > oldLengthAccruedInterest) {
			if (apr.time[index] < time || apr.time[index] == time) {
				aggregateInterest += (block.timestamp - time)*apr.aprChanges[index]/100;
				// Convert the aprChanges to the lowest unit value.
				// aggregateYield = (((apr.time[newIndex] - time) *apr.aprChanges[index])/100)*365/(100*1000);
			}
		}
		oldLengthAccruedInterest = apr.time.length;
		oldTime = block.timestamp;
	}

	function calcAPY(bytes32 _commitment, uint oldLengthAccruedYield, uint oldTime, uint aggregateYield) external view {
		
		APY storage apy = indAPYRecords[_commitment];

		require(oldLengthAccruedYield>0, "ERROR : oldLengthAccruedYield < 1");
		
		uint256 index = oldLengthAccruedYield - 1;
		uint256 time = oldTime;

		// 1. apr.time.length > oldLengthAccruedInterest => there is some change.

		if (apy.time.length > oldLengthAccruedYield)  {

			if (apy.time[index] < time) {
				uint256 newIndex = index + 1;
				// Convert the aprChanges to the lowest unit value.
				aggregateYield = (((apy.time[newIndex] - time) *apy.apyChanges[index])/100)*365/(100*1000);
			
				for (uint256 i = newIndex; i < apy.apyChanges.length; i++) {
					uint256 timeDiff = apy.time[i + 1] - apy.time[i];
					aggregateYield += (timeDiff*apy.apyChanges[newIndex] / 100)*365/(100*1000);
				}
			}
			else if (apy.time[index] == time) {
				for (uint256 i = index; i < apy.apyChanges.length; i++) {
					uint256 timeDiff = apy.time[i + 1] - apy.time[i];
					aggregateYield += (timeDiff*apy.apyChanges[index] / 100)*365/(100*1000);
				}
			}
		} else if (apy.time.length == oldLengthAccruedYield && block.timestamp > oldLengthAccruedYield) {
			if (apy.time[index] < time || apy.time[index] == time) {
				aggregateYield += (block.timestamp - time)*apy.apyChanges[index]/100;
				// Convert the aprChanges to the lowest unit value.
				// aggregateYield = (((apr.time[newIndex] - time) *apr.aprChanges[index])/100)*365/(100*1000);
			}
		}
		oldLengthAccruedYield = apy.time.length;
		oldTime = block.timestamp;
	}

	function updateLoanIssuanceFees(uint fees) external authComptroller() returns(bool success) {
		uint oldFees = loanIssuanceFees;
		loanIssuanceFees = fees;

		emit LoanIssuanceFeesUpdated(msg.sender, oldFees, loanIssuanceFees, block.timestamp);
		return success;
	}

	function updateLoanClosureFees(uint fees) external authComptroller() returns(bool success) {
		uint oldFees = loanClosureFees;
		loanClosureFees = fees;

		emit LoanClosureFeesUpdated(msg.sender, oldFees, loanClosureFees, block.timestamp);
		return success;
	}

	function updateLoanPreClosureFees(uint fees) external authComptroller() returns(bool success) {
		uint oldFees = loanPreClosureFees;
		loanPreClosureFees = fees;

		emit LoanPreClosureFeesUpdated(msg.sender, oldFees, loanPreClosureFees, block.timestamp);
		return success;
	}

	function updateDepositPreclosureFees(uint fees) external authComptroller() returns(bool success) {
		uint oldFees = depositPreClosureFees;
		depositPreClosureFees = fees;

		emit DepositPreClosureFeesUpdated(msg.sender, oldFees, depositPreClosureFees, block.timestamp);
		return success;
	}

	function updateWithdrawalFees(uint fees) external authComptroller() returns(bool success) {
		uint oldFees = depositWithdrawalFees;
		depositWithdrawalFees = fees;

		emit DepositWithdrawalFeesUpdated(msg.sender, oldFees, depositWithdrawalFees, block.timestamp);
		return success;
	}

	function updateCollateralReleaseFees(uint fees) external authComptroller() returns(bool success) {
		uint oldFees = collateralReleaseFees;
		collateralReleaseFees = fees;

		emit CollateralReleaseFeesUpdated(msg.sender, oldFees, collateralReleaseFees, block.timestamp);
		return success;
	}
	
	function updateYieldConversion(uint fees) external authComptroller() returns(bool success) {
		uint oldFees = yieldConversionFees;
		yieldConversionFees = fees;

		emit YieldConversionFeesUpdated(msg.sender, oldFees, yieldConversionFees, block.timestamp);
		return success;
	}

	function updateMarketSwapFees(uint fees) external authComptroller() returns(bool success) {
		uint oldFees = marketSwapFees;
		marketSwapFees = fees;

		emit MarketSwapFeesUpdated(msg.sender, oldFees, marketSwapFees, block.timestamp);
		return success;
	}

	function updateReserveFactor(uint _reserveFactor) external authComptroller() returns (bool success) {
	 	// implementing the barebones version for testnet. 
		//  if cdr >= reserveFactor, 1:3 possible, else 1:2 possible.
		uint oldReserveFactor = reserveFactor;
		 reserveFactor = _reserveFactor;
		 
		 emit ReserveFactorUpdated(msg.sender,oldReserveFactor, reserveFactor, block.timestamp);
		 return success;
	} 

// this function sets a maximum permissible amount that can be moved in a single transaction without the admin permissions.
	function updateMaxWithdrawal(uint factor, uint blockLimit) external authComptroller() returns(bool success) {
		
		uint oldFactor = maxWithdrawalFactor; 
		uint oldBlockLimit = blockLimit;

		maxWithdrawalFactor = factor;
		maxWithdrawalBlockLimit = blockLimit;

		emit MaxWithdrawalUpdated(msg.sender, maxWithdrawalFactor, maxWithdrawalBlockLimit, oldFactor, oldBlockLimit, block.timestamp);
		return success;
	}

	function getReserveFactor() external view returns (uint256) {
		return reserveFactor;
	}

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