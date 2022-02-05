// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Pausable.sol";
import "../libraries/LibOpen.sol";

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
	event AddCollateral(
		address indexed account,
		uint256 indexed id,
		uint256 amount,
		uint256 timestamp
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

	event WithdrawPartialLoan(
		address indexed account,
		uint256 indexed id,
		uint256 indexed amount,
		bytes32 market,
		uint256 timestamp
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
		loanState.state = ILoan.STATE.ACTIVE;

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

  function addCollateral(      
		bytes32 _loanMarket,
		bytes32 _commitment,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) external override returns (bool success) {
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
    	LoanAccount storage loanAccount = ds.loanPassbook[msg.sender];
		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_loanMarket][_commitment];
		LoanState storage loanState = ds.indLoanState[msg.sender][_loanMarket][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[msg.sender][_loanMarket][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[msg.sender][_loanMarket][_commitment];

		preAddCollateralProcess(_collateralMarket, _collateralAmount /* loanAccount */, loan,loanState, collateral);

		ds.collateralToken = IBEP20(LibOpen._connectMarket(_collateralMarket));
		// _quantifyAmount(_collateralMarket, _collateralAmount);
		ds.collateralToken.transferFrom(msg.sender, address(this), _collateralAmount);
		LibOpen._updateReservesLoan(_collateralMarket, _collateralAmount, 0);
		
		updateCollateral(loanAccount, collateral, _collateralAmount, loan.id-1);
		LibOpen._accruedInterest(msg.sender, _loanMarket, _commitment);

		if (collateral.isCollateralisedDeposit) LibOpen._accruedYield(loanAccount, collateral, cYield);

		emit AddCollateral(msg.sender, loan.id, _collateralAmount, block.timestamp);
		return success = true;
	}

	function ensureLoanAccount(address _account) private {
		
		AppStorageOpen storage ds = LibOpen.diamondStorage();
		
		LoanAccount storage loanAccount = ds.loanPassbook[_account];
		if (loanAccount.accOpenTime == 0) {
			loanAccount.accOpenTime = block.timestamp;
			loanAccount.account = _account;
		}
	}

	function updateCollateral(
		LoanAccount storage loanAccount,
		CollateralRecords storage collateral,
		uint256 _collateralAmount,
		uint256 num
	) private {
		collateral.amount += _collateralAmount;
		loanAccount.collaterals[num].amount = _collateralAmount;
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
		require (usdLoan/usdCollateral <=3, "ERROR: Exceeds permissible CDR");

		// calculating cdrPermissible.
		if (LibOpen._avblMarketReserves(_loanMarket) >= amount + 3*LibOpen._avblMarketReserves(_loanMarket)/4)    {
				loanByCollateral = 3;
		} else     {
				loanByCollateral = 2;
		}
		require (usdLoan/usdCollateral <= loanByCollateral, "ERROR: Exceeds permissible CDR");
	}


	function liquidation(address _account, uint256 _id) external override authLoanExt() nonReentrant() returns (bool success) {
		
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
        
		bytes32 _commitment = ds.loanPassbook[_account].loans[_id-1].commitment;
		bytes32 _loanMarket = ds.loanPassbook[_account].loans[_id-1].market;

		LoanRecords storage loan = ds.indLoanRecords[_account][_loanMarket][_commitment];
		LoanState storage loanState = ds.indLoanState[_account][_loanMarket][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_account][_loanMarket][_commitment];
		// uint deductAccruedInterest = ds.indAccruedAPR[_account][_loanMarket][_commitment].accruedInterest;
		// CollateralYield storage cYield = ds.indAccruedAPY[_account][_loanMarket][_commitment];

		// emit FairPriceCall(ds.requestEventId++, collateral.market, collateral.amount);
		// emit FairPriceCall(ds.requestEventId++, loanState.currentMarket, loanState.currentAmount);

		require(loan.id == _id, "ERROR: Mismatch LoanID");

		LibOpen._accruedInterest(_account, _loanMarket, _commitment);
		
		if (loan.commitment == LibOpen._getCommitment(2))
			collateral.amount += ds.indAccruedAPY[_account][_loanMarket][_commitment].accruedYield - ds.indAccruedAPR[_account][_loanMarket][_commitment].accruedInterest;
		else if (loan.commitment != LibOpen._getCommitment(2))
			collateral.amount -= ds.indAccruedAPR[_account][_loanMarket][_commitment].accruedInterest;

		delete ds.indAccruedAPY[_account][_loanMarket][_commitment];
		delete ds.indAccruedAPR[_account][_loanMarket][_commitment];

		delete ds.loanPassbook[_account].accruedAPY[loan.id - 1];
		delete ds.loanPassbook[_account].accruedAPR[loan.id - 1];

		// uint256 cAmount = LibOpen._getLatestPrice(collateral.market)*collateral.amount;
		// uint256 lAmountCurrent = LibOpen._getLatestPrice(loanState.currentMarket)*loanState.currentAmount;
		// convert collateral & loanCurrent into loanActual
		uint256 _repaymentAmount = LibOpen._swap(_account, collateral.market, loan.market, LibOpen._getLatestPrice(collateral.market)*collateral.amount, 2);
		_repaymentAmount += LibOpen._swap(_account, loanState.currentMarket, loan.market, LibOpen._getLatestPrice(loanState.currentMarket)*loanState.currentAmount, 1);

		delete ds.indLoanState[_account][_loanMarket][_commitment];
		delete ds.indLoanRecords[_account][_loanMarket][_commitment];
		delete ds.indCollateralRecords[_account][_loanMarket][_commitment];

		delete ds.loanPassbook[_account].loanState[_id - 1];
		delete ds.loanPassbook[_account].loans[_id - 1];
		delete ds.loanPassbook[_account].collaterals[_id - 1];
		LibOpen._updateUtilisationLoan(loan.market, loan.amount, 1);

		emit LoanRepaid(_account, _id, loan.market, block.timestamp);
		emit Liquidation(_account,_loanMarket, _commitment, loan.amount, block.timestamp);
		return success = true;
	}

	function preAddCollateralProcess(
		bytes32 _collateralMarket,
		uint256 _collateralAmount,
		// LoanAccount storage loanAccount,
		LoanRecords storage loan,
		LoanState storage loanState,
		CollateralRecords storage collateral
	) private view {
		// require(loanAccount.accOpenTime != 0, "ERROR: No Loan account"); // redundant
		require(loan.id != 0, "ERROR: No loan");
		require(loanState.state == ILoan.STATE.ACTIVE, "ERROR: Inactive loan");
		require(collateral.market == _collateralMarket, "ERROR: Mismatch collateral market");

		LibOpen._isMarketSupported(_collateralMarket);
		LibOpen._minAmountCheck(_collateralMarket, _collateralAmount);
	}

	
	function withdrawPartialLoan(bytes32 _loanMarket,bytes32 _commitment, bytes32 _collateralMarket, uint256 _amount) external returns (bool success) {
    
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		LibOpen._hasLoanAccount(msg.sender);

		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_loanMarket][_commitment];
		LoanState storage loanState = ds.indLoanState[msg.sender][_loanMarket][_commitment];
		
		checkPermissibleWithdrawal(msg.sender, _loanMarket, _commitment, _collateralMarket, _amount);
		
		ds.withdrawToken = IBEP20(LibOpen._connectMarket(loanState.currentMarket));
		ds.withdrawToken.transfer(msg.sender,_amount);

		emit WithdrawPartialLoan(msg.sender, loan.id, _amount, loanState.currentMarket, block.timestamp);
		return success = true;
  }

	function checkPermissibleWithdrawal(address _sender,bytes32 _loanMarket,bytes32 _commitment, bytes32 _collateralMarket, uint256 _amount) private /*authContract(LOAN_ID)*/ {
		
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		// LoanRecords storage loan = ds.indLoanRecords[_sender][_loanMarket][_commitment];
		LoanState storage loanState = ds.indLoanState[_sender][_loanMarket][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_sender][_loanMarket][_commitment];
		// DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_sender][_loanMarket][_commitment];
		// emit FairPriceCall(ds.requestEventId++, _collateralMarket, _amount);
		// emit FairPriceCall(ds.requestEventId++, _loanMarket, _amount);
		// emit FairPriceCall(ds.requestEventId++, loanState.currentMarket, loanState.currentAmount);		
		// _quantifyAmount(loanState.currentMarket, _amount);
		require(_amount <= loanState.currentAmount, "ERROR: Exceeds available loan");
		
		LibOpen._accruedInterest(_sender, _loanMarket, _commitment);
		uint256 collateralAvbl = collateral.amount - ds.indAccruedAPR[_sender][_loanMarket][_commitment].accruedInterest;

		// fetch usdPrices
		uint256 usdCollateral = LibOpen._getLatestPrice(_collateralMarket);
		uint256 usdLoan = LibOpen._getLatestPrice(_loanMarket);
		uint256 usdLoanCurrent = LibOpen._getLatestPrice(loanState.currentMarket);

		// Quantification of the assets
		// uint256 cAmount = usdCollateral*collateral.amount;
		// uint256 cAmountAvbl = usdCollateral*collateralAvbl;

		// uint256 lAmountCurrent = usdLoanCurrent*loanState.currentAmount;
		uint256 permissibleAmount = ((usdCollateral*collateralAvbl - (30*usdCollateral*collateral.amount/100))/usdLoanCurrent);

		require(permissibleAmount > 0, "ERROR: Can not withdraw zero funds");
		require(permissibleAmount > (_amount), "ERROR:Request exceeds funds");
		
		// calcualted in usdterms
		require(((usdCollateral*collateralAvbl) + (usdLoanCurrent*loanState.currentAmount) - (_amount*usdLoanCurrent)) >= (11*(usdLoan*ds.indLoanRecords[_sender][_loanMarket][_commitment].amount)/10), "ERROR: Liquidation risk");
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