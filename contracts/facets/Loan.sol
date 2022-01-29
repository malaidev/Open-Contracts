// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./util/Pausable.sol";
import "./libraries/LibDiamond.sol";


contract Loan is Pausable, ILoan {
	
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
	) external override nonReentrant() returns (bool) {
		LibDiamond._swapLoan(msg.sender, _market, _commitment, _swapMarket);
		return true;
	}

/// SwapToLoan
	function swapToLoan(
		bytes32 _swapMarket,
		bytes32 _commitment,
		bytes32 _market
	) external override nonReentrant() returns (bool) {
		uint256 _swappedAmount;
		LibDiamond._swapToLoan(msg.sender, _swapMarket,_commitment, _market, _swappedAmount);
		return true;
	}

	function withdrawCollateral(bytes32 _market, bytes32 _commitment) external override returns (bool) {
		LibDiamond._withdrawCollateral(msg.sender, _market, _commitment);
		return true;
	}

	function repayLoan(bytes32 _market,bytes32 _commitment,uint256 _repayAmount) external override returns (bool success) {
		LibDiamond._repayLoan(_market, _commitment, _repayAmount, msg.sender);
		return true;
	}

    function getFairPriceLoan(uint _requestId) external view override returns (uint price){
		price = LibDiamond._getFairPrice(_requestId);
	}

	function collateralPointer(address _account, bytes32 _market, bytes32 _commitment, bytes32 collateralMarket, uint collateralAmount) external view override returns (bool) {
    	LibDiamond._collateralPointer(_account, _market, _commitment, collateralMarket, collateralAmount);
		return true;
	}

	function pauseLoan() external override authLoan() nonReentrant() {
		_pause();
	}
	
	function unpauseLoan() external override authLoan() nonReentrant() {
		_unpause();   
	}

	function isPausedLoan() external view virtual override returns (bool) {
		return _paused();
	}

	modifier authLoan() {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
		require(LibDiamond._hasAdminRole(ds.superAdmin, ds.contractOwner) || LibDiamond._hasAdminRole(ds.adminLoan, ds.adminLoanAddress), "Admin role does not exist.");
		_;
	}
}
