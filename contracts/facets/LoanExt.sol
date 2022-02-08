// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Pausable.sol";
import "../libraries/LibOpen.sol";
import "../interfaces/ILoan.sol";

import "hardhat/console.sol";

contract LoanExt is Pausable, ILoanExt {
	event NewLoan(
		address indexed account,
		bytes32 loanMarket,
		bytes32 commitment,
		uint256 loanAmount,
		bytes32 collateralMarket,
		uint256 collateralAmount,
		uint256 indexed loanId
	);
	
	event LoanRepaid(
		address indexed account,
		uint256 indexed id,
		bytes32 indexed market,
		uint256 timestamp
	);
	
	event Liquidation(
		address indexed account,
		bytes32 indexed market,
		bytes32 indexed commitment,
		uint256 amount,
		uint256 time
	);


	constructor() {
		
	}

	receive() external payable {
		payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}
	
	fallback() external payable {
		payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}


	function hasLoanAccount(address _account) external view override returns (bool) {
		return LibOpen._hasLoanAccount(_account);
	}

	function avblReservesLoan(bytes32 _loanMarket) external view override returns(uint) {
		return LibOpen._avblReservesLoan(_loanMarket);
	}

	function utilisedReservesLoan(bytes32 _loanMarket) external view override returns(uint) {
    	return LibOpen._utilisedReservesLoan(_loanMarket);
	}

	function loanRequest(
		bytes32 _loanMarket,
		bytes32 _commitment,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) external override nonReentrant() returns (bool) {
		
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		
		require(LibOpen._avblMarketReserves(_loanMarket) >= _loanAmount, "ERROR: Borrow amount exceeds reserves");
		preLoanRequestProcess(_loanMarket,_loanAmount,_collateralMarket,_collateralAmount);

		// LoanAccount storage loanAccount = ds.loanPassbook[msg.sender];
		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_loanMarket][_commitment];
		require(loan.id == 0, "ERROR: Active loan");

		ds.collateralToken.transferFrom(msg.sender, address(this), _collateralAmount);
		// ds.collateralToken.approveFrom(msg.sender, address(this), _collateralAmount);

		ensureLoanAccount(msg.sender);
		processNewLoan(_loanMarket,_commitment,_loanAmount,_collateralMarket,_collateralAmount);
		
		LibOpen._updateReservesLoan(_collateralMarket,_collateralAmount, 0);
		emit NewLoan(msg.sender, _loanMarket, _commitment, _loanAmount, _collateralMarket, _collateralAmount, ds.loanPassbook[msg.sender].loans.length+1);

		return true;
	}

	function processNewLoan(
		bytes32 _loanMarket,
		bytes32 _commitment,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) private {
		AppStorageOpen storage ds = LibOpen.diamondStorage();
		// uint256 id;
		LoanAccount storage loanAccount = ds.loanPassbook[msg.sender];
		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_loanMarket][_commitment];
		LoanState storage loanState = ds.indLoanState[msg.sender][_loanMarket][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[msg.sender][_loanMarket][_commitment];
		DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[msg.sender][_loanMarket][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[msg.sender][_loanMarket][_commitment];

		// Updating loanRecords
		loan.id = loanAccount.loans.length + 1;
		loan.market = _loanMarket;
		loan.commitment = _commitment;
		loan.amount = _loanAmount;
		loan.isSwapped = false;
		loan.lastUpdate = block.timestamp;
		
		// Updating deductibleInterest
		deductibleInterest.id = loan.id;
		deductibleInterest.market = _collateralMarket;
		deductibleInterest.oldTime= block.timestamp;
		deductibleInterest.accruedInterest = 0;

		// Updating loanState
		loanState.id = loan.id;
		loanState.loanMarket = _loanMarket;
		loanState.actualLoanAmount = _loanAmount;
		loanState.currentMarket = _loanMarket;
		loanState.currentAmount = _loanAmount;
		loanState.state = uint(STATE.ACTIVE);

		collateral.id= loan.id;
		collateral.market= _collateralMarket;
		collateral.commitment= _commitment;
		collateral.amount = _collateralAmount;

		loanAccount.loans.push(loan);
		loanAccount.loanState.push(loanState);

		if (_commitment == LibOpen._getCommitment(0)) {
			
			collateral.isCollateralisedDeposit = false;
			collateral.timelockValidity = 0;
			collateral.isTimelockActivated = true;
			collateral.activationTime = 0;

			// pays 18% APR
			deductibleInterest.oldLengthAccruedInterest = LibOpen._getAprTimeLength(_commitment);

			loanAccount.collaterals.push(collateral);
			loanAccount.accruedAPR.push(deductibleInterest);
			// loanAccount.accruedAPY.push(accruedYield); - no yield because it is
			// a flexible loan
		} else if (_commitment == LibOpen._getCommitment(2)) {
			
			collateral.isCollateralisedDeposit = true;
			collateral.timelockValidity = 86400;
			collateral.isTimelockActivated = false;
			collateral.activationTime = 0;

			// 15% APR
			deductibleInterest.oldLengthAccruedInterest = LibOpen._getAprTimeLength(_commitment);
			
			cYield.id = loanAccount.loans.length + 1;
			cYield.market = _collateralMarket;
			cYield.commitment = LibOpen._getCommitment(1);
			cYield.oldLengthAccruedYield = LibOpen._getApyTimeLength(_commitment);
			cYield.oldTime = block.timestamp;
			cYield.accruedYield =0;

			loanAccount.collaterals.push(collateral);
			loanAccount.accruedAPY.push(cYield);
			loanAccount.accruedAPR.push(deductibleInterest);
		}
		LibOpen._updateUtilisationLoan(_loanMarket, _loanAmount, 0);
	}

	function preLoanRequestProcess(
		bytes32 _loanMarket,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) private {
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		require(_loanAmount != 0,"ERROR: Loan amount can not be zero");
		require(_collateralAmount != 0,"ERROR: Collateral can not be zero");

		permissibleCDR(_loanMarket,_collateralMarket,_loanAmount,_collateralAmount);

		// Check for amrket support
		LibOpen._isMarketSupported(_loanMarket);
		LibOpen._isMarketSupported(_collateralMarket);

		// _quantifyAmount(_loanMarket, _loanAmount);
		// _quantifyAmount(_collateralMarket, _collateralAmount);

		// check for minimum permissible amount
		LibOpen._minAmountCheck(_loanMarket, _loanAmount);
		LibOpen._minAmountCheck(_collateralMarket, _collateralAmount);

		// Connect
		ds.loanToken = IBEP20(LibOpen._connectMarket(_loanMarket));
		ds.collateralToken = IBEP20(LibOpen._connectMarket(_collateralMarket));	
	}

  	

	function ensureLoanAccount(address _account) private {
		
		AppStorageOpen storage ds = LibOpen.diamondStorage();
		
		LoanAccount storage loanAccount = ds.loanPassbook[_account];
		if (loanAccount.accOpenTime == 0) {
			loanAccount.accOpenTime = block.timestamp;
			loanAccount.account = _account;
		}
	}

	function permissibleCDR (
		bytes32 _loanMarket,
		bytes32 _collateralMarket,
		uint256 _loanAmount,
		uint256 _collateralAmount
	) private view{
	// emit FairPriceCall(ds.requestEventId++, _loanMarket, _loanAmount);
	// emit FairPriceCall(ds.requestEventId++, _collateralMarket, _collateralAmount);

		uint256 loanByCollateral;
		uint256 amount = LibOpen._avblMarketReserves(_loanMarket) - _loanAmount ;
		uint rF = LibOpen._getReserveFactor()* LibOpen._avblMarketReserves(_loanMarket);

		uint256 usdLoan = (LibOpen._getLatestPrice(_loanMarket)) * _loanAmount;
		uint256 usdCollateral = (LibOpen._getLatestPrice(_collateralMarket)) * _collateralAmount;

		require(amount > 0, "ERROR: Loan exceeds reserves");
		require(LibOpen._avblMarketReserves(_loanMarket) >= rF + amount, "ERROR: Minimum reserve exeception");
		require (usdLoan * 100 / usdCollateral <=300, "ERROR: Exceeds permissible CDR");

		// calculating cdrPermissible.
		if (LibOpen._avblMarketReserves(_loanMarket) >= amount + 3*LibOpen._avblMarketReserves(_loanMarket)/4)    {
				loanByCollateral = 3;
		} else     {
				loanByCollateral = 2;
		}
		require (usdLoan/usdCollateral <= loanByCollateral, "ERROR: Exceeds permissible CDR");
	}

	function liquidation(address _account, uint256 _id) external override authLoanExt() nonReentrant() returns (bool) {
		
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
        
		bytes32 _commitment = ds.loanPassbook[_account].loans[_id-1].commitment;
		bytes32 _loanMarket = ds.loanPassbook[_account].loans[_id-1].market;

		LoanRecords storage loan = ds.indLoanRecords[_account][_loanMarket][_commitment];
		
		LibOpen._repayLoan(_account, _loanMarket, _commitment, 0);
		emit Liquidation(_account,_loanMarket, _commitment, loan.amount, block.timestamp);
		return true;
	}


function repayLoan(bytes32 _loanMarket,bytes32 _commitment,uint256 _repayAmount) external override nonReentrant() returns (bool) {
		LibOpen._repayLoan(msg.sender, _loanMarket, _commitment, _repayAmount);
		return true;
	}
	function pauseLoanExt() external override authLoanExt() nonReentrant() {
		_pause();
	}
	
function unpauseLoanExt() external override authLoanExt() nonReentrant() {
		_unpause();   
	}

	function isPausedLoanExt() external view virtual override returns (bool) {
		return _paused();
	}

    modifier authLoanExt() {
    	AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		require(IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.superAdmin, msg.sender) || IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.adminLoanExt, msg.sender), "ERROR: Not an admin");

		_;
	}
}