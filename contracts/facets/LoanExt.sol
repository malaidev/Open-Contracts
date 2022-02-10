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
		uint256 indexed loanId,
		uint256 time
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
		
		require(LibOpen._avblMarketReserves(_loanMarket) >= _loanAmount, "ERROR: Borrow amount exceeds reserves");		
		_preLoanRequestProcess(_loanMarket,_loanAmount,_collateralMarket,_collateralAmount);

		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_loanMarket][_commitment];
		require(loan.id == 0, "ERROR: Active loan");
		
		/// CONNECT MARKETS
		ds.loanToken = IBEP20(LibOpen._connectMarket(_loanMarket));
		ds.collateralToken = IBEP20(LibOpen._connectMarket(_collateralMarket));	

		/// TRIGGER approve() from the Web3 client
		ds.collateralToken.transferFrom(msg.sender, address(this), _collateralAmount);

		_ensureLoanAccount(msg.sender); // CHECK LOANACCOUNT
		_processNewLoan(_loanMarket,_commitment,_loanAmount,_collateralMarket,_collateralAmount);
		
		LibOpen._updateReservesLoan(_collateralMarket,_collateralAmount, 0);
		emit NewLoan(msg.sender, _loanMarket, _commitment, _loanAmount, _collateralMarket, _collateralAmount, loan.id, block.timestamp);

		return true;
	}

	function _processNewLoan(
		bytes32 _loanMarket,
		bytes32 _commitment,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) private {
		
		AppStorageOpen storage ds = LibOpen.diamondStorage();
		LoanAccount storage loanAccount = ds.loanPassbook[msg.sender];
		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_loanMarket][_commitment];
		LoanState storage loanState = ds.indLoanState[msg.sender][_loanMarket][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[msg.sender][_loanMarket][_commitment];
		DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[msg.sender][_loanMarket][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[msg.sender][_loanMarket][_commitment];
		
		/// UPDATING LoanRecords
		loan.id = loanAccount.loans.length + 1;
		loan.market = _loanMarket;
		loan.commitment = _commitment;
		loan.amount = _loanAmount;
		loan.isSwapped = false;
		loan.lastUpdate = block.timestamp;
		
		/// UPDATING DeductibleInterest
		deductibleInterest.id = loan.id;
		deductibleInterest.market = _collateralMarket;
		deductibleInterest.oldLengthAccruedInterest = 0;
		deductibleInterest.oldTime= block.timestamp;
		deductibleInterest.accruedInterest = 0;
		
		/// UPDATING LoanState
		loanState.id = loan.id;
		loanState.loanMarket = _loanMarket;
		loanState.actualLoanAmount = _loanAmount;
		loanState.currentMarket = _loanMarket;
		loanState.currentAmount = _loanAmount;
		loanState.state = STATE.ACTIVE;

		/// UPDATING CollateralRecords
		collateral.id= loan.id;
		collateral.market= _collateralMarket;
		collateral.commitment= _commitment;
		collateral.amount = _collateralAmount;
		
		/// UPDATING LoanAccount
		loanAccount.loans.push(loan);
		loanAccount.loanState.push(loanState);

		if (_commitment == LibOpen._getCommitment(0)) {
			
			collateral.isCollateralisedDeposit = false;
			collateral.timelockValidity = 0;
			collateral.isTimelockActivated = true;
			collateral.activationTime = 0;

			/// pays 18% APR
			deductibleInterest.oldLengthAccruedInterest = LibOpen._getAprTimeLength(_commitment);
			
			/// UPDATING LoanAccount 
			loanAccount.collaterals.push(collateral);
			loanAccount.accruedAPR.push(deductibleInterest);
			// loanAccount.accruedAPY.push(accruedYield); - no yield because it is
			// a flexible loan
		} else if (_commitment == LibOpen._getCommitment(2)) {
			
			collateral.isCollateralisedDeposit = true;
			collateral.timelockValidity = 86400;
			collateral.isTimelockActivated = false;
			collateral.activationTime = 0;

			/// 15% APR
			deductibleInterest.oldLengthAccruedInterest = LibOpen._getAprTimeLength(_commitment);
			
			/// 10% APY ON COLLATERALISED DEPOSIT
			cYield.id = loanAccount.loans.length + 1;
			cYield.market = _collateralMarket;
			cYield.commitment = LibOpen._getCommitment(1);
			cYield.oldLengthAccruedYield = LibOpen._getApyTimeLength(_commitment);
			cYield.oldTime = block.timestamp;
			cYield.accruedYield =0;
			
			/// UPDATING LoanAccount 
			loanAccount.collaterals.push(collateral);
			loanAccount.accruedAPY.push(cYield);
			loanAccount.accruedAPR.push(deductibleInterest);
		}
		LibOpen._updateUtilisationLoan(_loanMarket, _loanAmount, 0);
	}

	function _preLoanRequestProcess(
		bytes32 _loanMarket,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) private view {
		// AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		
		require(_loanAmount != 0,"ERROR: Zero Loan amount");
		require(_collateralAmount != 0,"ERROR: Zero collateral");
		
		/// CHECK MARKETSUPPORT
		LibOpen._isMarketSupported(_loanMarket);
		LibOpen._isMarketSupported(_collateralMarket);
		
		/// CHECK CDR PERMISSIBLE
		permissibleCDR(_loanMarket,_collateralMarket,_loanAmount,_collateralAmount);

		/// CHECK MINAMOUNT FOR DEPOSITS/LOANS.
		LibOpen._minAmountCheck(_loanMarket, _loanAmount);
		LibOpen._minAmountCheck(_collateralMarket, _collateralAmount);
	}

	function _ensureLoanAccount(address _account) private {
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

		uint256 loanToCollateral;
		uint256 amount = LibOpen._avblMarketReserves(_loanMarket) - _loanAmount ;
		require(amount > 0, "ERROR: Loan exceeds reserves");
		
		uint rF = LibOpen._getReserveFactor()*LibOpen._avblMarketReserves(_loanMarket);

		uint256 usdLoan = (LibOpen._getLatestPrice(_loanMarket)) * _loanAmount;
		uint256 usdCollateral = (LibOpen._getLatestPrice(_collateralMarket)) * _collateralAmount;

		require(LibOpen._avblMarketReserves(_loanMarket) >= rF + amount, "ERROR: Minimum reserve exeception");
		require (usdLoan * 100 / usdCollateral <=300, "ERROR: Insufficient collateral");

		/// DETERMIING  cdrPermissible.
		if (LibOpen._avblMarketReserves(_loanMarket) >= amount + 3*LibOpen._avblMarketReserves(_loanMarket)/4)    {
				loanToCollateral = 3;
		} else     {
				loanToCollateral = 2;
		}
		require (usdLoan/usdCollateral <= loanToCollateral, "ERROR: Loan exceeds permissible CDR");
	}

	function liquidation(address account, bytes32 _market, bytes32 _commitment) external override authLoanExt() nonReentrant() returns (bool success) {
		
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 

		LoanAccount storage loanAccount = ds.loanPassbook[account];
		LoanState storage loanState = ds.indLoanState[account][_market][_commitment];
		LoanRecords storage loan = ds.indLoanRecords[account][_market][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[account][_market][_commitment];
		DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[account][_market][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[account][_market][_commitment];

		uint num = loan.id;

		uint256 remnantAmount= LibOpen._repaymentProcess(
			loan.id - 1,
			0, 
			loanAccount,
			loan,
			loanState,
			collateral,
			deductibleInterest,
			cYield
		);

		/// UPDATING THE RESERVES
		LibOpen._updateReservesLoan(loan.market, remnantAmount,0);
		LibOpen._updateReservesDeposit(collateral.market, collateral.amount,1);
		emit Liquidation(account,_market, _commitment, loan.amount, block.timestamp);

		/// DELETING THE LOAN ENTRIES
		/// COLLATERAL RECORDS
		delete collateral.id;
		delete collateral.market;
		delete collateral.commitment;
		delete collateral.amount;
		delete collateral.isCollateralisedDeposit;
		delete collateral.timelockValidity;
		delete collateral.isTimelockActivated;
		delete collateral.activationTime;

		/// LOAN RECORDS
		delete loan.id;
		delete loan.market;
		delete loan.commitment;
		delete loan.amount;
		delete loan.isSwapped;
		delete loan.lastUpdate;

		/// LOAN STATE
		delete loanState.id;
		delete loanState.loanMarket;
		delete loanState.actualLoanAmount;
		delete loanState.currentMarket;
		delete loanState.currentAmount;
		delete loanState.state;

		/// LOAN ACCOUNT
		delete loanAccount.loans[num];
		delete loanAccount.collaterals[num];
		delete loanAccount.loanState[num];

		return success=true;
	}


	// function liquidation(address account, uint256 id) external override authLoanExt() nonReentrant() returns (bool) {
		
	// 	AppStorageOpen storage ds = LibOpen.diamondStorage(); 
        
	// 	bytes32 commitment = ds.loanPassbook[account].loans[id-1].commitment;
	// 	bytes32 loanMarket = ds.loanPassbook[account].loans[id-1].market;

	// 	LoanRecords storage loan = ds.indLoanRecords[account][loanMarket][commitment];
		
	// 	LibOpen._repayLoan(account, loanMarket, commitment, 0);

	// 	emit Liquidation(account,loanMarket, commitment, loan.amount, block.timestamp);
	// 	return true;
	// }


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