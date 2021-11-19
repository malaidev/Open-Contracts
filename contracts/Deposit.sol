// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./util/Pausable.sol";
// import "./mockup/IMockBep20.sol";
import "./libraries/LibDiamond.sol";


contract Deposit is Pausable, IDeposit{
	
	event NewDeposit(address indexed account,bytes32 indexed market,bytes32 commmitment,uint256 indexed amount);
	event DepositAdded(address indexed account,bytes32 indexed market,bytes32 commmitment,uint256 indexed amount);
	event YieldDeposited(address indexed account,bytes32 indexed market,bytes32 commmitment,uint256 indexed amount);
	event Withdrawal(address indexed account, bytes32 indexed market, uint indexed amount, bytes32 commitment, uint timestamp);
	
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

	function hasAccount(address _account) external view returns (bool)	{
		LibDiamond._hasAccount(_account);
		return true;
	}

	function savingsBalance(bytes32 _market, bytes32 _commitment) external returns (uint) {
		return LibDiamond._accountBalance(msg.sender, _market, _commitment, SAVINGSTYPE.BOTH);
	}

	function convertYield(bytes32 _market, bytes32 _commitment) external nonReentrant() returns (bool success) {
		
		uint _amount;
		LibDiamond._convertYield(msg.sender, _market,_commitment, _amount);

		emit YieldDeposited(msg.sender, _market, _commitment, _amount);
		return success;
	}

	function hasYield(bytes32 _market, bytes32 _commitment) external view returns (bool) {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		LibDiamond.YieldLedger storage yield = ds.indYieldRecord[msg.sender][_market][_commitment];
		
		LibDiamond._hasYield(yield);
		return true;
	}

	function avblReservesDeposit(bytes32 _market) external view returns (uint) {
		return LibDiamond._avblReservesDeposit(_market);
	}

	function utilisedReservesDeposit(bytes32 _market) external view returns(uint) {
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

	function hasDeposit(bytes32 _market, bytes32 _commitment) external view returns (bool) {
		LibDiamond._hasDeposit(msg.sender,_market, _commitment);
		return true;
	}

	function createDeposit(
		bytes32 _market,
		bytes32 _commitment,
		uint256 _amount
	) external nonReentrant(){
		
		LibDiamond._createNewDeposit(_market,_commitment, _amount, msg.sender);

		emit NewDeposit(msg.sender, _market, _commitment, _amount);
	}

	function withdrawDeposit (
		bytes32 _market, 
		bytes32 _commitment,
		uint _amount,
		SAVINGSTYPE _request
	) external nonReentrant() returns (bool success) 
	{
		LibDiamond._withdrawDeposit(msg.sender, _market, _commitment, _amount, _request);
		emit Withdrawal(msg.sender,_market, _amount, _commitment, block.timestamp);
		success = true;	
	}

	function addToDeposit(bytes32 _market, bytes32 _commitment, uint _amount) external nonReentrant() returns(bool success) {
		if (!LibDiamond._hasDeposit(msg.sender, _market, _commitment))	{
			LibDiamond._createNewDeposit(_market, _commitment, _amount, msg.sender);
		} 
		
		LibDiamond._processDeposit(msg.sender, _market, _commitment, _amount);
		LibDiamond._updateReservesDeposit(_market, _amount, 0);

		emit DepositAdded(msg.sender, _market, _commitment, _amount);
		success = true;
	}

	function pauseDeposit() external authDeposit() nonReentrant() {
		_pause();
	}
	
	function unpauseDeposit() external authDeposit() nonReentrant() {
		_unpause();   
	}

	function isPausedDeposit() external view virtual returns (bool) {
		return _paused();
	}

	modifier authDeposit() {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 

		require(
			msg.sender == ds.contractOwner,
			"Only an admin can call this function"
		);
		_;
	}
}