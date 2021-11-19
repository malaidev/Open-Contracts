// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./util/Pausable.sol";
import "./libraries/LibDiamond.sol";

contract Loan is Pausable, ILoan {
	
	/// Constructor
	constructor() {
    	// LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		// ds.adminLoanAddress = msg.sender;
		// ds.loan = ILoan(msg.sender);
	}

	// receive() external payable {
    // 	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
	// 	 payable(ds.contractOwner).transfer(_msgValue());
	// }
	
	// fallback() external payable {
    // 	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
	// 	payable(ds.contractOwner).transfer(_msgValue());
	// }

	// External view functions

	/// Swap loan to a secondary market.
	function swapLoan(
		bytes32 _market,
		bytes32 _commitment,
		bytes32 _swapMarket
	) external nonReentrant() returns (bool success) {
		return LibDiamond._swapLoan(msg.sender, _market, _commitment, _swapMarket);
	}

/// SwapToLoan
	function swapToLoan(
		bytes32 _swapMarket,
		bytes32 _commitment,
		bytes32 _market
	) external nonReentrant() returns (bool success) {
		uint256 _swappedAmount;
		LibDiamond._swapToLoan(msg.sender, _swapMarket,_commitment, _market, _swappedAmount);
		return success;
	}

	function withdrawCollateral(bytes32 _market, bytes32 _commitment) external returns (bool success) {
		return LibDiamond._withdrawCollateral(msg.sender, _market, _commitment);
	}

	function collateralPointer(address _account, bytes32 _market, bytes32 _commitment, bytes32 collateralMarket, uint collateralAmount) external view{
    	LibDiamond._collateralPointer(_account, _market, _commitment, collateralMarket, collateralAmount);
	}

	function repayLoan(bytes32 _market,bytes32 _commitment,uint256 _repayAmount) external  returns (bool success) {
		return LibDiamond._repayLoan(_market, _commitment, _repayAmount, msg.sender);
	}

	function pauseLoan() external authLoan() nonReentrant() {
		_pause();
	}
	
	function unpauseLoan() external authLoan() nonReentrant() {
		_unpause();   
	}

	function isPausedLoan() external view virtual returns (bool) {
		return _paused();
	}

	modifier authLoan() {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		require(
			msg.sender == ds.contractOwner,
			"ERROR: Require Admin access"
		);
		_;
	}
}