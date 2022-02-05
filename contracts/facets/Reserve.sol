// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Pausable.sol";
import "../libraries/LibOpen.sol";


contract Reserve is Pausable, IReserve {

	constructor() {
		// AppStorage storage ds = LibOpen.diamondStorage(); 
			// ds.adminReserveAddress = msg.sender;
			// ds.reserve = IReserve(msg.sender);
	}
	
	receive() external payable {
		payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}
    
	fallback() external payable {
		payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}

	function transferAnyBEP20(
		address _token,
		address _recipient,
		uint256 _value) external override authReserve() nonReentrant() returns(bool success)   
	{
		IBEP20(_token).transfer(_recipient, _value);
		return success = true;
	}

	// function transferMarket(address _token, address _recipient, uint256 _value, uint256 nFacetIndex)
	// 	public nonReentrant() authTransfer(nFacetIndex) returns (bool success) {

	// 	IBEP20(_token).transfer(_recipient, _value);
	// 	success = true;
	// }

	// function marketReserves(bytes32 _market) external view returns(uint) {
	//     _avblReserves(_market);
	// }
	// function _avblReserves(bytes32 _market) internal view returns(uint) {
	//     return loan.reserves(_market) + deposit.reserves(_market);
	// }

	function avblMarketReserves(bytes32 _market) external view override returns (uint) {
		return LibOpen._avblMarketReserves(_market);
	}

	function marketReserves(bytes32 _market) external view override returns(uint)	{
		return LibOpen._marketReserves(_market);
	}

	function marketUtilisation(bytes32 _market) external view override returns(uint)	{
		return LibOpen._marketUtilisation(_market);
	}

/// Duplicate: withdrawCollateral() in Loan.sol

// 	function collateralTransfer(address _account, bytes32 _market, bytes32 _commitment) external override returns (bool){
// 		AppStorageOpen storage ds = LibOpen.diamondStorage(); 

// 		bytes32 collateralMarket;
// 		uint collateralAmount;

// 		(collateralMarket, collateralAmount) = LibOpen._collateralPointer(_account,_market,_commitment);
// 		ds.token = IBEP20(LibOpen._connectMarket(collateralMarket));
// 		// ds.token.approveFrom(ds.reserveAddress, address(this), collateralAmount);
// 		// ds.token.transferFrom(ds.reserveAddress, _account, collateralAmount);
// 		ds.token.transfer(_account, collateralAmount);
// 		return true;
//   }

	modifier authReserve()  {
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		require(IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.superAdmin, msg.sender) || IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.adminReserve, msg.sender), "ERROR: Not an admin");
		_;
	}

	// modifier authTransfer(uint256 nFacetIndex) {
	// 	require(nFacetIndex == LibOpen.LOAN_ID || 
	// 		nFacetIndex == LibOpen.LOANEXT_ID || 
	// 		nFacetIndex == LibOpen.DEPOSIT_ID, "Not permitted facet");
	// 	_;
	// }

	function pauseReserve() external override authReserve() nonReentrant() {
			_pause();
	}
	
	function unpauseReserve() external override authReserve() nonReentrant() {
		_unpause();   
	}

	function isPausedReserve() external view virtual override returns (bool) {
		return _paused();
	}
}
