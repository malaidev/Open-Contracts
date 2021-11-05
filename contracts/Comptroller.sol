// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import "./util/Pausable.sol";
// import "./mockup/IMockBep20.sol";
import "./libraries/LibDiamond.sol";

contract Comptroller is Pausable, IComptroller {
	// using Address for address;

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

	// constructor() {
    // 	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
	// 	ds.comptroller = IComptroller(msg.sender);
	// }
	
	// receive() external payable {
    // 	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
	// 	 payable(ds.adminComptrollerAddress).transfer(_msgValue());
	// }
	
	// fallback() external payable {
    // 	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
	// 	payable(ds.adminComptrollerAddress).transfer(_msgValue());
	// }
	
	function getAPR(bytes32 _commitment) external view returns (uint) {
    	return LibDiamond._getAPR(_commitment);
	}
	function getAPRInd(bytes32 _commitment, uint _index) external view returns (uint) {
    	return LibDiamond._getAPRInd(_commitment, _index);
	}

	function getAPY(bytes32 _commitment) external view returns (uint) {
    	return LibDiamond._getAPY(_commitment);
	}

	function getAPYInd(bytes32 _commitment, uint _index) external view returns (uint) {
    	return LibDiamond._getAPYInd(_commitment, _index);
	}

	function getApytime(bytes32 _commitment, uint _index) external view returns (uint) {
    	return LibDiamond._getApytime(_commitment, _index);
	}

	function getAprtime(bytes32 _commitment, uint _index) external view returns (uint) {
    	return LibDiamond._getAprtime(_commitment, _index);
	}

	function getApyLastTime(bytes32 _commitment) external view returns (uint) {
    	return LibDiamond._getApyLastTime(_commitment);
	}

	function getAprLastTime(bytes32 _commitment) external view returns (uint) {
    	return LibDiamond._getAprLastTime(_commitment);
	}

	function getApyTimeLength(bytes32 _commitment) external view returns (uint) {
    	return LibDiamond._getApyTimeLength(_commitment);
	}

	function getAprTimeLength(bytes32 _commitment) external view returns (uint) {
    	return LibDiamond._getAprTimeLength(_commitment);
	}

	function getCommitment(uint _index) external view returns (bytes32) {
    	return LibDiamond._getCommitment(_index);
	}

	function setCommitment(bytes32 _commitment) external authComptroller {
    	LibDiamond._setCommitment(_commitment);
	}

	function liquidationTrigger(uint loanID) external {}

	// SETTERS
	function updateAPY(bytes32 _commitment, uint _apy) external authComptroller() nonReentrant() returns (bool) {
		return LibDiamond._updateApy(_commitment, _apy);
	}

	function updateAPR(bytes32 _commitment, uint _apr) external authComptroller() nonReentrant() returns (bool ) {
		return LibDiamond._updateApr(_commitment, _apr);
	}

	function calcAPR(bytes32 _commitment, uint oldLengthAccruedInterest, uint oldTime, uint aggregateInterest) external view returns (uint, uint){
    	return LibDiamond._calcAPR(_commitment, oldLengthAccruedInterest, oldTime, aggregateInterest);
	}

	function calcAPY(bytes32 _commitment, uint oldLengthAccruedYield, uint oldTime, uint aggregateYield) external view returns (uint, uint) {
		return LibDiamond._calcAPY(_commitment, oldLengthAccruedYield, oldTime, aggregateYield);
	}

	function updateLoanIssuanceFees(uint fees) external authComptroller() returns(bool success) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.loanIssuanceFees;
		ds.loanIssuanceFees = fees;

		emit LoanIssuanceFeesUpdated(msg.sender, oldFees, ds.loanIssuanceFees, block.timestamp);
		return success;
	}

	function updateLoanClosureFees(uint fees) external authComptroller() returns(bool success) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.loanClosureFees;
		ds.loanClosureFees = fees;

		emit LoanClosureFeesUpdated(msg.sender, oldFees, ds.loanClosureFees, block.timestamp);
		return success;
	}

	function updateLoanPreClosureFees(uint fees) external authComptroller() returns(bool success) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.loanPreClosureFees;
		ds.loanPreClosureFees = fees;

		emit LoanPreClosureFeesUpdated(msg.sender, oldFees, ds.loanPreClosureFees, block.timestamp);
		return success;
	}

	function depositPreClosureFees() external view returns (uint) {
		return LibDiamond.diamondStorage().depositPreClosureFees;
	}

	function updateDepositPreclosureFees(uint fees) external authComptroller() returns(bool success) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.depositPreClosureFees;
		ds.depositPreClosureFees = fees;

		emit DepositPreClosureFeesUpdated(msg.sender, oldFees, ds.depositPreClosureFees, block.timestamp);
		return success;
	}

	function depositWithdrawalFees() external view returns (uint) {
		return LibDiamond.diamondStorage().depositWithdrawalFees;
	}

	function updateWithdrawalFees(uint fees) external authComptroller() returns(bool success) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.depositWithdrawalFees;
		ds.depositWithdrawalFees = fees;

		emit DepositWithdrawalFeesUpdated(msg.sender, oldFees, ds.depositWithdrawalFees, block.timestamp);
		return success;
	}

	function collateralReleaseFees() external view returns (uint) {
		return LibDiamond.diamondStorage().collateralReleaseFees;
	}

	function updateCollateralReleaseFees(uint fees) external authComptroller() returns(bool success) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.collateralReleaseFees;
		ds.collateralReleaseFees = fees;

		emit CollateralReleaseFeesUpdated(msg.sender, oldFees, ds.collateralReleaseFees, block.timestamp);
		return success;
	}
	
	function updateYieldConversion(uint fees) external authComptroller() returns(bool success) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.yieldConversionFees;
		ds.yieldConversionFees = fees;

		emit YieldConversionFeesUpdated(msg.sender, oldFees, ds.yieldConversionFees, block.timestamp);
		return success;
	}

	function updateMarketSwapFees(uint fees) external authComptroller() returns(bool success) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.marketSwapFees;
		ds.marketSwapFees = fees;

		emit MarketSwapFeesUpdated(msg.sender, oldFees, ds.marketSwapFees, block.timestamp);
		return success;
	}

	function updateReserveFactor(uint _reserveFactor) external authComptroller() returns (bool success) {
	 	// implementing the barebones version for testnet. 
		//  if cdr >= reserveFactor, 1:3 possible, else 1:2 possible.
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldReserveFactor = ds.reserveFactor;
		ds.reserveFactor = _reserveFactor;
		 
		emit ReserveFactorUpdated(msg.sender,oldReserveFactor, ds.reserveFactor, block.timestamp);
		return success;
	} 

// this function sets a maximum permissible amount that can be moved in a single transaction without the admin permissions.
	function updateMaxWithdrawal(uint factor, uint blockLimit) external authComptroller() returns(bool success) {
		
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFactor = ds.maxWithdrawalFactor; 
		uint oldBlockLimit = blockLimit;

		ds.maxWithdrawalFactor = factor;
		ds.maxWithdrawalBlockLimit = blockLimit;

		emit MaxWithdrawalUpdated(msg.sender, ds.maxWithdrawalFactor, ds.maxWithdrawalBlockLimit, oldFactor, oldBlockLimit, block.timestamp);
		return success;
	}

	function getReserveFactor() external view returns (uint256) {
    	return LibDiamond._getReserveFactor();
	}

	modifier authComptroller() {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		require(msg.sender == ds.contractOwner,
			"Only the comptroller admin can modify this function" 
		);
		_;
	}

	function pauseComptroller() external authComptroller() nonReentrant() {
		_pause();
	}
	
	function unpauseComptroller() external authComptroller() nonReentrant() {
		_unpause();   
	}

	function isPausedComptroller() external view virtual returns (bool) {
		return _paused();
	}
}