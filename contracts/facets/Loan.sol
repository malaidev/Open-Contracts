// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Pausable.sol";
import "../libraries/LibOpen.sol";

contract Loan is Pausable, ILoan {
	
	constructor() {
    	// AppStorage storage ds = LibOpen.diamondStorage(); 
		// ds.adminLoanAddress = msg.sender;
		// ds.loan = ILoan(msg.sender);
	}

	// receive() external payable {
    // 	AppStorage storage ds = LibOpen.diamondStorage(); 
	// 	 payable(ds.contractOwner).transfer(_msgValue());
	// }
	
	// fallback() external payable {
    // 	AppStorage storage ds = LibOpen.diamondStorage(); 
	// 	payable(ds.contractOwner).transfer(_msgValue());
	// }

	// External view functions

	/// Swap loan to a secondary market.
	function swapLoan(
		bytes32 _market,
		bytes32 _commitment,
		bytes32 _swapMarket
	) external override nonReentrant() returns (bool) {
		LibOpen._swapLoan(msg.sender, _market, _commitment, _swapMarket);
		return true;
	}

/// SwapToLoan
	function swapToLoan(
		bytes32 _swapMarket,
		bytes32 _commitment,
		bytes32 _market
	) external override nonReentrant() returns (bool) {
		uint256 _swappedAmount;
		LibOpen._swapToLoan(msg.sender, _swapMarket,_commitment, _market, _swappedAmount);
		return true;
	}

	function withdrawCollateral(bytes32 _market, bytes32 _commitment) external override returns (bool) {
		LibOpen._withdrawCollateral(msg.sender, _market, _commitment);
		return true;
	}

	function repayLoan(bytes32 _market,bytes32 _commitment,uint256 _repayAmount) external override returns (bool success) {
		LibOpen._repayLoan(_market, _commitment, _repayAmount, msg.sender);
		return true;
	}

    function getFairPriceLoan(uint _requestId) external view override returns (uint price){
		price = LibOpen._getFairPrice(_requestId);
	}

	function collateralPointer(address _account, bytes32 _market, bytes32 _commitment, bytes32 collateralMarket, uint collateralAmount) external view override returns (bool) {
    	LibOpen._collateralPointer(_account, _market, _commitment, collateralMarket, collateralAmount);
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
    	AppStorageOpen storage ds = LibOpen.diamondStorage();
		require(LibOpen._hasAdminRole(ds.superAdmin, ds.superAdminAddress) || LibOpen._hasAdminRole(ds.adminLoan, ds.adminLoanAddress), "Admin role does not exist.");
		_;
	}
}
