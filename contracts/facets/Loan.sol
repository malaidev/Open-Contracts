// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Pausable.sol";
import "../libraries/LibOpen.sol";

contract Loan is Pausable, ILoan {

	event AddCollateral(
		address indexed account,
		uint256 indexed id,
		uint256 amount,
		uint256 timestamp
	);
	
	event WithdrawPartialLoan(
		address indexed account,
		uint256 indexed id,
		uint256 indexed amount,
		bytes32 market,
		uint256 timestamp
	);
	constructor() {
    	// AppStorage storage ds = LibOpen.diamondStorage(); 
		// ds.adminLoanAddress = msg.sender;
		// ds.loan = ILoan(msg.sender);
	}

	receive() external payable {
		payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}
	
	fallback() external payable {
		payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}

	/// Swap loan to a secondary market.
	function swapLoan(
		bytes32 _loanMarket,
		bytes32 _commitment,
		bytes32 _swapMarket
	) external override nonReentrant() returns (bool) {
		LibOpen._swapLoan(msg.sender, _loanMarket, _commitment, _swapMarket);
		return true;
	}

/// SwapToLoan
	function swapToLoan(
		bytes32 _commitment,
		bytes32 _loanMarket
	) external override nonReentrant() returns (bool success) {
		LibOpen._swapToLoan(msg.sender, _commitment, _loanMarket);
		return success = true;
	}

	function withdrawCollateral(bytes32 _market, bytes32 _commitment) external override nonReentrant() returns (bool) {
		LibOpen._withdrawCollateral(msg.sender, _market, _commitment);
		return true;
	}
	

	// function getFairPriceLoan(uint _requestId) external view override returns (uint){
	// 	return LibOpen._getFairPrice(_requestId);
	// }

	// function collateralPointer(address _account, bytes32 _loanMarket, bytes32 _commitment) external view override returns (bool) {
    // 	LibOpen._collateralPointer(_account, _loanMarket, _commitment);
	// 	return true;
	// }

	function _preAddCollateralProcess(
		bytes32 _collateralMarket,
		uint256 _collateralAmount,
		LoanRecords storage loan,
		LoanState storage loanState,
		CollateralRecords storage collateral
	) private view {

		require(loan.id != 0, "ERROR: No loan");
		require(loanState.state == STATE.ACTIVE, "ERROR: Inactive loan");
		require(collateral.market == _collateralMarket, "ERROR: Mismatch collateral market");

		LibOpen._isMarketSupported(_collateralMarket);
		LibOpen._minAmountCheck(_collateralMarket, _collateralAmount);
	}

	function addCollateral(      
		bytes32 _loanMarket,
		bytes32 _commitment,
		uint256 _collateralAmount
	) external override returns (bool) {

		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
    	LoanAccount storage loanAccount = ds.loanPassbook[msg.sender];
		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_loanMarket][_commitment];
		LoanState storage loanState = ds.indLoanState[msg.sender][_loanMarket][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[msg.sender][_loanMarket][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[msg.sender][_loanMarket][_commitment];

		_preAddCollateralProcess(collateral.market, _collateralAmount, loan,loanState, collateral);

		ds.collateralToken = IBEP20(LibOpen._connectMarket(collateral.market));
		
		/// TRIGGER: ds.collateralToken.approve() on the client.
		ds.collateralToken.transferFrom(msg.sender, address(this), _collateralAmount);
		LibOpen._updateReservesLoan(collateral.market, _collateralAmount, 0);

		/// UPDATE COLLATERAL IN STORAGE
		collateral.amount += _collateralAmount;
		loanAccount.collaterals[loan.id-1].amount += _collateralAmount;

		LibOpen._accruedInterest(msg.sender, _loanMarket, _commitment);
		if (collateral.isCollateralisedDeposit) LibOpen._accruedYield(loanAccount, collateral, cYield);

		emit AddCollateral(msg.sender, loan.id, _collateralAmount, block.timestamp);
		return true;
	}
		
	function withdrawPartialLoan(bytes32 _loanMarket,bytes32 _commitment, uint256 _amount) external nonReentrant()	returns (bool) {
		
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		LibOpen._hasLoanAccount(msg.sender);

		LoanAccount storage loanAccount = ds.loanPassbook[msg.sender];
		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_loanMarket][_commitment];
		LoanState storage loanState = ds.indLoanState[msg.sender][_loanMarket][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[msg.sender][_loanMarket][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[msg.sender][_loanMarket][_commitment];
		
		LibOpen._checkPermissibleWithdrawal(msg.sender, _amount, loanAccount, loan, loanState, collateral, cYield);
		
		ds.loanToken = IBEP20(LibOpen._connectMarket(loan.market));
		ds.loanToken.transfer(msg.sender,_amount);

		emit WithdrawPartialLoan(msg.sender, loan.id, _amount, loan.market, block.timestamp);
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
		require(IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.superAdmin, msg.sender) || IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.adminLoan, msg.sender), "ERROR: Not an admin");
		_;
	}
}
