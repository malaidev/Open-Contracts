// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
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

	constructor() {
    // 	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
	// 	ds.comptroller = IComptroller(msg.sender);
	}
	
	receive() external payable {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		 payable(ds.contractOwner).transfer(_msgValue());
	}
	
	fallback() external payable {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		payable(ds.contractOwner).transfer(_msgValue());
	}
	
	function getAPR(bytes32 _commitment) external view override returns (uint) {
    	return LibDiamond._getAPR(_commitment);
	}
	function getAPRInd(bytes32 _commitment, uint _index) external view override returns (uint) {
    	return LibDiamond._getAPRInd(_commitment, _index);
	}

	function getAPY(bytes32 _commitment) external view override returns (uint) {
    	return LibDiamond._getAPY(_commitment);
	}

	function getAPYInd(bytes32 _commitment, uint _index) external view override returns (uint) {
    	return LibDiamond._getAPYInd(_commitment, _index);
	}

	function getApytime(bytes32 _commitment, uint _index) external view override returns (uint) {
    	return LibDiamond._getApytime(_commitment, _index);
	}

	function getAprtime(bytes32 _commitment, uint _index) external view override returns (uint) {
    	return LibDiamond._getAprtime(_commitment, _index);
	}

	function getApyLastTime(bytes32 _commitment) external view override returns (uint) {
    	return LibDiamond._getApyLastTime(_commitment);
	}

	function getAprLastTime(bytes32 _commitment) external view override returns (uint) {
    	return LibDiamond._getAprLastTime(_commitment);
	}

	function getApyTimeLength(bytes32 _commitment) external view override returns (uint) {
    	return LibDiamond._getApyTimeLength(_commitment);
	}

	function getAprTimeLength(bytes32 _commitment) external view override returns (uint) {
    	return LibDiamond._getAprTimeLength(_commitment);
	}

	function getCommitment(uint _index) external view override returns (bytes32) {
    	return LibDiamond._getCommitment(_index);
	}

	function setCommitment(bytes32 _commitment) external override authComptroller {
    	LibDiamond._setCommitment(_commitment);
	}

	function liquidationTrigger(uint loanID) external override {}

	// SETTERS
	function updateAPY(bytes32 _commitment, uint _apy) external override authComptroller() nonReentrant() returns (bool) {
		return LibDiamond._updateApy(_commitment, _apy);
	}

	function updateAPR(bytes32 _commitment, uint _apr) external override authComptroller() nonReentrant() returns (bool ) {
		return LibDiamond._updateApr(_commitment, _apr);
	}

	function calcAPR(bytes32 _commitment, uint oldLengthAccruedInterest, uint oldTime, uint aggregateInterest) external view override returns (uint, uint){
    	return LibDiamond._calcAPR(_commitment, oldLengthAccruedInterest, oldTime, aggregateInterest);
	}

	function calcAPY(bytes32 _commitment, uint oldLengthAccruedYield, uint oldTime, uint aggregateYield) external view override returns (uint, uint) {
		return LibDiamond._calcAPY(_commitment, oldLengthAccruedYield, oldTime, aggregateYield);
	}

	function updateLoanIssuanceFees(uint fees) external override authComptroller() returns(bool) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.loanIssuanceFees;
		ds.loanIssuanceFees = fees;

		emit LoanIssuanceFeesUpdated(msg.sender, oldFees, ds.loanIssuanceFees, block.timestamp);
		return true;
	}

	function updateLoanClosureFees(uint fees) external override authComptroller() returns(bool) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.loanClosureFees;
		ds.loanClosureFees = fees;

		emit LoanClosureFeesUpdated(msg.sender, oldFees, ds.loanClosureFees, block.timestamp);
		return true;
	}

	function updateLoanPreClosureFees(uint fees) external override authComptroller() returns(bool) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.loanPreClosureFees;
		ds.loanPreClosureFees = fees;

		emit LoanPreClosureFeesUpdated(msg.sender, oldFees, ds.loanPreClosureFees, block.timestamp);
		return true;
	}

	function depositPreClosureFees() external view override returns (uint) {
		return LibDiamond.diamondStorage().depositPreClosureFees;
	}

	function updateDepositPreclosureFees(uint fees) external override authComptroller() returns(bool) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.depositPreClosureFees;
		ds.depositPreClosureFees = fees;

		emit DepositPreClosureFeesUpdated(msg.sender, oldFees, ds.depositPreClosureFees, block.timestamp);
		return true;
	}

	function depositWithdrawalFees() external view override returns (uint) {
		return LibDiamond.diamondStorage().depositWithdrawalFees;
	}

	function updateWithdrawalFees(uint fees) external override authComptroller() returns(bool) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.depositWithdrawalFees;
		ds.depositWithdrawalFees = fees;

		emit DepositWithdrawalFeesUpdated(msg.sender, oldFees, ds.depositWithdrawalFees, block.timestamp);
		return true;
	}

	function collateralReleaseFees() external view override returns (uint) {
		return LibDiamond.diamondStorage().collateralReleaseFees;
	}

	function updateCollateralReleaseFees(uint fees) external override authComptroller() returns(bool) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.collateralReleaseFees;
		ds.collateralReleaseFees = fees;

		emit CollateralReleaseFeesUpdated(msg.sender, oldFees, ds.collateralReleaseFees, block.timestamp);
		return true;
	}
	
	function updateYieldConversion(uint fees) external override authComptroller() returns(bool) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.yieldConversionFees;
		ds.yieldConversionFees = fees;

		emit YieldConversionFeesUpdated(msg.sender, oldFees, ds.yieldConversionFees, block.timestamp);
		return true;
	}

	function updateMarketSwapFees(uint fees) external override authComptroller() returns(bool) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFees = ds.marketSwapFees;
		ds.marketSwapFees = fees;

		emit MarketSwapFeesUpdated(msg.sender, oldFees, ds.marketSwapFees, block.timestamp);
		return true;
	}

	function updateReserveFactor(uint _reserveFactor) external override authComptroller() returns (bool) {
	 	// implementing the barebones version for testnet. 
		//  if cdr >= reserveFactor, 1:3 possible, else 1:2 possible.
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldReserveFactor = ds.reserveFactor;
		ds.reserveFactor = _reserveFactor;
		 
		emit ReserveFactorUpdated(msg.sender,oldReserveFactor, ds.reserveFactor, block.timestamp);
		return true;
	} 

// this function sets a maximum permissible amount that can be moved in a single transaction without the admin permissions.
	function updateMaxWithdrawal(uint factor, uint blockLimit) external override authComptroller() returns(bool) {
		
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		uint oldFactor = ds.maxWithdrawalFactor; 
		uint oldBlockLimit = blockLimit;

		ds.maxWithdrawalFactor = factor;
		ds.maxWithdrawalBlockLimit = blockLimit;

		emit MaxWithdrawalUpdated(msg.sender, ds.maxWithdrawalFactor, ds.maxWithdrawalBlockLimit, oldFactor, oldBlockLimit, block.timestamp);
		return true;
	}

	function getReserveFactor() external view override returns (uint256) {
    	return LibDiamond._getReserveFactor();
	}

	modifier authComptroller() {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		require(LibDiamond._hasAdminRole(ds.superAdmin, ds.contractOwner) || LibDiamond._hasAdminRole(ds.adminComptroller, ds.adminComptrollerAddress), "Admin role does not exist.");
		_;
	}

	function pauseComptroller() external override authComptroller() nonReentrant() {
		_pause();
	}
	
	function unpauseComptroller() external override authComptroller() nonReentrant() {
		_unpause(); 
	}

	function isPausedComptroller() external view virtual override returns (bool) {
		return _paused();
	}
}
