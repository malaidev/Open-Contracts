// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Pausable.sol";
import "../libraries/LibOpen.sol";
import "hardhat/console.sol";

contract Loan1 is Pausable, ILoan1 {

	constructor() {
    	// AppStorage storage ds = LibOpen.diamondStorage(); 
		// ds.adminLoan1Address = msg.sender;
		// ds.loan1 = ILoan1(msg.sender);
	}

    function hasLoanAccount(address _account) external view override returns (bool) {
		return LibOpen._hasLoanAccount(_account);
	}

			function avblReservesLoan(bytes32 _market) external view override returns(uint) {
		return LibOpen._avblReservesLoan(_market);
	}

	function utilisedReservesLoan(bytes32 _market) external view override returns(uint) {
    	return LibOpen._utilisedReservesLoan(_market);
	}

	function loanRequest(
		bytes32 _market,
		bytes32 _commitment,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) external override nonReentrant() returns (bool) {
		LibOpen._loanRequest(
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
		LibOpen._addCollateral(_market, _commitment, _collateralMarket, _collateralAmount, msg.sender);
		return true;
	}

	function liquidation(address _account, uint256 _id) external override nonReentrant() authLoan1() returns (bool success) {
		LibOpen._liquidation(_account, _id);
		return true;
	}
	
	function permissibleWithdrawal(bytes32 _market,bytes32 _commitment, bytes32 _collateralMarket, uint256 _amount) external override returns (bool success) {
		return LibOpen._permissibleWithdrawal(_market, _commitment, _collateralMarket, _amount, msg.sender);
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
    	AppStorage storage ds = LibOpen.diamondStorage(); 
		console.log("superadminaddress is %s", ds.superAdminAddress);
		require(LibOpen._hasAdminRole(ds.superAdmin, ds.superAdminAddress) || LibOpen._hasAdminRole(ds.adminLoan1, ds.adminLoan1Address), "Admin role does not exist.");

		_;
	}


}