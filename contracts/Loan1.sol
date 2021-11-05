// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./util/Pausable.sol";
import "./libraries/LibDiamond.sol";

contract Loan1 is Pausable, ILoan1 {
    /// Constructor
	constructor() {
    	// LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		// ds.adminLoan1Address = msg.sender;
		// ds.loan1 = ILoan1(msg.sender);
	}

    function hasLoanAccount(address _account) external view returns (bool) {
		return LibDiamond._hasLoanAccount(_account);
	}

	function avblReservesLoan(bytes32 _market) external view returns(uint) {
		return LibDiamond._avblReservesLoan(_market);
	}

	function utilisedReservesLoan(bytes32 _market) external view returns(uint) {
    	return LibDiamond._utilisedReservesLoan(_market);
	}

    function loanRequest(
		bytes32 _market,
		bytes32 _commitment,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) external nonReentrant() returns (bool success) {
		return LibDiamond._loanRequest(
			_market,
			_commitment,
			_loanAmount,
			_collateralMarket,
			_collateralAmount
		);
	}

    function addCollateral(
		bytes32 _market,
		bytes32 _commitment,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) external returns (bool success) {
		return LibDiamond._addCollateral(_market, _commitment, _collateralMarket, _collateralAmount);
	}

    function pauseLoan1() external authLoan1() nonReentrant() {
		_pause();
	}
	
	function unpauseLoan1() external authLoan1() nonReentrant() {
		_unpause();   
	}

	function isPausedLoan1() external view virtual returns (bool) {
		return _paused();
	}

    modifier authLoan1() {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		require(
			msg.sender == ds.contractOwner,
			"ERROR: Require Admin access"
		);
		_;
	}


}