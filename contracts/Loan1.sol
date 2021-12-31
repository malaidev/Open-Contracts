// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./util/Pausable.sol";
import "./libraries/LibDiamond.sol";


contract Loan1 is Pausable, ILoan1 {

	constructor() {
    	// LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		// ds.adminLoan1Address = msg.sender;
		// ds.loan1 = ILoan1(msg.sender);
	}

    function hasLoanAccount(address _account) external view override returns (bool) {
		return LibDiamond._hasLoanAccount(_account);
	}

			function avblReservesLoan(bytes32 _market) external view override returns(uint) {
		return LibDiamond._avblReservesLoan(_market);
	}

	function utilisedReservesLoan(bytes32 _market) external view override returns(uint) {
    	return LibDiamond._utilisedReservesLoan(_market);
	}

	function loanRequest(
		bytes32 _market,
		bytes32 _commitment,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) external override nonReentrant() returns (bool) {
		LibDiamond._loanRequest(
			_market,
			_commitment,
			_loanAmount,
			_collateralMarket,
			_collateralAmount,
			msg.sender
		);
		return true;
	}

    function addCollateral(      
		bytes32 _market,
		bytes32 _commitment,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) external override returns (bool) {
		LibDiamond._addCollateral(_market, _commitment, _collateralMarket, _collateralAmount, msg.sender);
		return true;
	}

	function liquidation(address _account, uint256 _id) external override nonReentrant() authLoan1() returns (bool success) {
		LibDiamond._liquidation(_account, _id);
		return true;
	}
	
	function permissibleWithdrawal(bytes32 _market,bytes32 _commitment, bytes32 _collateralMarket, uint256 _amount) external override returns (bool success) {
		return LibDiamond._permissibleWithdrawal(_market, _commitment, _collateralMarket, _amount, msg.sender);
	}
	
	function pauseLoan1() external override authLoan1() nonReentrant() {
		_pause();
	}
	
	function unpauseLoan1() external override authLoan1() nonReentrant() {
		_unpause();   
	}

	function isPausedLoan1() external view virtual override returns (bool) {
		return _paused();
	}

    modifier authLoan1() {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		require(LibDiamond._hasAdminRole(ds.superAdmin, ds.contractOwner) || LibDiamond._hasAdminRole(ds.adminLoan1, ds.adminLoan1Address), "Admin role does not exist.");

		_;
	}


}