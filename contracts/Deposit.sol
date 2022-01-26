// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./util/Pausable.sol";
// import "./mockup/IMockBep20.sol";
import "./libraries/LibDiamond.sol";


contract Deposit is Pausable, IDeposit{
	
	constructor() 
	{
    	// LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		// ds.adminDepositAddress = msg.sender;
		// ds.deposit = IDeposit(msg.sender);
	}

	receive() external payable {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		 payable(ds.contractOwner).transfer(_msgValue());
	}
	
	fallback() external payable {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		payable(ds.contractOwner).transfer(_msgValue());
	}

	function hasAccount(address _account) external view override returns (bool)	{
		LibDiamond._hasAccount(_account);
		return true;
	}

	function savingsBalance(bytes32 _market, bytes32 _commitment) external override returns (uint) {
		return LibDiamond._accountBalance(msg.sender, _market, _commitment, SAVINGSTYPE.BOTH);
	}

	function convertYield(bytes32 _market, bytes32 _commitment) external override nonReentrant() returns (bool) {
		uint _amount;
		LibDiamond._convertYield(msg.sender, _market,_commitment, _amount);
		return true;
	}

	function hasYield(bytes32 _market, bytes32 _commitment) external view override returns (bool) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		LibDiamond.YieldLedger storage yield = ds.indYieldRecord[msg.sender][_market][_commitment];
		LibDiamond._hasYield(yield);
		return true;
	}
 
	function avblReservesDeposit(bytes32 _market) external view override returns (uint) {
		return LibDiamond._avblReservesDeposit(_market);
	}

	function utilisedReservesDeposit(bytes32 _market) external view override returns(uint) {
    	return LibDiamond._utilisedReservesDeposit(_market);
	}

	function _updateUtilisation(bytes32 _market, uint _amount, uint _num) private 
	{
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		if (_num == 0)	{
			ds.marketUtilisationDeposit[_market] += _amount;
		} else if (_num == 1)	{
			ds.marketUtilisationDeposit[_market] -= _amount;
		}
	}

	function hasDeposit(bytes32 _market, bytes32 _commitment) external view override returns (bool) {
		LibDiamond._hasDeposit(msg.sender,_market, _commitment);
		return true;
	}

	// function createDeposit(
	// 	bytes32 _market,
	// 	bytes32 _commitment,
	// 	uint256 _amount
	// ) external override nonReentrant() returns (bool) {
		
	// 	LibDiamond._createNewDeposit(_market,_commitment, _amount, msg.sender);
	// 	return true;
	// }

	function withdrawDeposit (
		bytes32 _market, 
		bytes32 _commitment,
		uint _amount,
		SAVINGSTYPE _request
	) external override nonReentrant() returns (bool) 
	{
		LibDiamond._withdrawDeposit(msg.sender, _market, _commitment, _amount, _request);
		return true;	
	}

	function addToDeposit(bytes32 _market, bytes32 _commitment, uint _amount) external override nonReentrant() returns(bool) {
		LibDiamond._addToDeposit(msg.sender, _market, _commitment, _amount);
		return true;
	}
    function getFairPriceDeposit(uint _requestId) external view override returns (uint price){
		price = LibDiamond._getFairPrice(_requestId);
	}

	function pauseDeposit() external override authDeposit() nonReentrant() {
		_pause();
	}
	
	function unpauseDeposit() external override authDeposit() nonReentrant() {
		_unpause();   
	}

	function isPausedDeposit() external view override virtual returns (bool) {
		return _paused();
	}

	//For upgradibility test
	function upgradeTestAccount(address _account) external view returns (bool success) {
    	LibDiamond._hasAccount(_account);
		LibDiamond._hasLoanAccount(_account);
		success = true;
	}

	modifier authDeposit() {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 

		require(LibDiamond._hasAdminRole(ds.superAdmin, ds.contractOwner) || LibDiamond._hasAdminRole(ds.adminDeposit, ds.adminDepositAddress), "Admin role does not exist.");
		_;
	}
}
