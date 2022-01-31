// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Pausable.sol";
import "../libraries/LibOpen.sol";

contract Loan1 is Pausable, ILoan1 {
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
		
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		require(LibOpen._avblMarketReserves(_market) >= _loanAmount, "ERROR: Borrow amount exceeds reserves");
    preLoanRequestProcess(_market,_loanAmount,_collateralMarket,_collateralAmount);

		// LoanAccount storage loanAccount = ds.loanPassbook[_sender];
		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_market][_commitment];

		require(loan.id == 0, "ERROR: Active loan");
		ds.collateralToken.approveFrom(msg.sender, address(this), _collateralAmount);
		ds.collateralToken.transferFrom(msg.sender, ds.reserveAddress, _collateralAmount);

		LibOpen._updateReservesLoan(_collateralMarket,_collateralAmount, 0);
		LibOpen._ensureLoanAccount(msg.sender);

		processNewLoan(_market,_commitment,_loanAmount,_collateralMarket,_collateralAmount);

		emit NewLoan(msg.sender, _market, _commitment, _loanAmount, _collateralMarket, _collateralAmount, ds.loanPassbook[msg.sender].loans.length+1);

		return true;
	}

	function processNewLoan(
		bytes32 _market,
		bytes32 _commitment,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) private {
    AppStorageOpen storage ds = LibOpen.diamondStorage();
		// uint256 id;

		LoanAccount storage loanAccount = ds.loanPassbook[msg.sender];
		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_market][_commitment];
		LoanState storage loanState = ds.indLoanState[msg.sender][_market][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[msg.sender][_market][_commitment];
		DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[msg.sender][_market][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[msg.sender][_market][_commitment];

		// if (loanAccount.loans.length == 0) {
		// 	id = 1;
		// } else if (loanAccount.loans.length != 0) {
			// id = loanAccount.loans.length + 1;
		// }

		
		// Updating loanRecords
		loan.id = loanAccount.loans.length + 1;
		loan.market = _market;
		loan.commitment = _commitment;
		loan.amount = _loanAmount;
		loan.isSwapped = false;
		loan.lastUpdate = block.timestamp;
		
		// Updating deductibleInterest
		deductibleInterest.id = loanAccount.loans.length + 1;
		deductibleInterest.market = _collateralMarket;
		deductibleInterest.oldTime= block.timestamp;
		deductibleInterest.accruedInterest = 0;

		// Updating loanState
		loanState.id = loanAccount.loans.length + 1;
		loanState.loanMarket = _market;
		loanState.actualLoanAmount = _loanAmount;
		loanState.currentMarket = _market;
		loanState.currentAmount = _loanAmount;
		loanState.state = ILoan.STATE.ACTIVE;

		collateral.id= loanAccount.loans.length + 1;
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
		LibOpen._updateUtilisationLoan(_market, _loanAmount, 0);
	}

	function preLoanRequestProcess(
		bytes32 _market,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) private {
        AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		require(
			_loanAmount != 0 && _collateralAmount != 0,
			"Loan or collateral cannot be zero"
		);

		LibOpen._permissibleCDR(_market,_collateralMarket,_loanAmount,_collateralAmount);

		// Check for amrket support
		LibOpen._isMarketSupported(_market);
		LibOpen._isMarketSupported(_collateralMarket);

		// _quantifyAmount(_market, _loanAmount);
		// _quantifyAmount(_collateralMarket, _collateralAmount);

		// check for minimum permissible amount
		LibOpen._minAmountCheck(_market, _loanAmount);
		LibOpen._minAmountCheck(_collateralMarket, _collateralAmount);

		// Connect
		ds.loanToken = IBEP20(LibOpen._connectMarket(_market));
		ds.collateralToken = IBEP20(LibOpen._connectMarket(_collateralMarket));	
	}

  function addCollateral(      
		bytes32 _market,
		bytes32 _commitment,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) external override returns (bool) {
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
    LoanAccount storage loanAccount = ds.loanPassbook[msg.sender];
		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_market][_commitment];
		LoanState storage loanState = ds.indLoanState[msg.sender][_market][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[msg.sender][_market][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[msg.sender][_market][_commitment];

		LibOpen._preAddCollateralProcess(_collateralMarket, _collateralAmount, loanAccount, loan,loanState, collateral);

		ds.collateralToken = IBEP20(LibOpen._connectMarket(_collateralMarket));
		// _quantifyAmount(_collateralMarket, _collateralAmount);
		ds.collateralToken.approveFrom(msg.sender, address(this), _collateralAmount);
		ds.collateralToken.transferFrom(msg.sender, ds.reserveAddress, _collateralAmount);
		LibOpen._updateReservesLoan(_collateralMarket, _collateralAmount, 0);
		
		LibOpen._addCollateralAmount(loanAccount, collateral, _collateralAmount, loan.id-1);
		LibOpen._accruedInterest(msg.sender, _market, _commitment);

		if (collateral.isCollateralisedDeposit) LibOpen._accruedYieldSt(loanAccount, collateral, cYield);

		emit AddCollateral(msg.sender, loan.id, _collateralAmount, block.timestamp);
		return true;
	}

	function liquidation(address _account, uint256 _id) external override nonReentrant() authLoan1() returns (bool success) {
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
        bytes32 _commitment = ds.loanPassbook[_account].loans[_id-1].commitment;
		bytes32 _market = ds.loanPassbook[_account].loans[_id-1].market;

		LoanRecords storage loan = ds.indLoanRecords[_account][_market][_commitment];
		LoanState storage loanState = ds.indLoanState[_account][_market][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_account][_market][_commitment];
		DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_account][_market][_commitment];
		// CollateralYield storage cYield = ds.indAccruedAPY[_account][_market][_commitment];

		// emit FairPriceCall(ds.requestEventId++, collateral.market, collateral.amount);
		// emit FairPriceCall(ds.requestEventId++, loanState.currentMarket, loanState.currentAmount);

		require(loan.id == _id, "ERROR: id mismatch");

		LibOpen._accruedInterest(_account, _market, _commitment);
		
		if (loan.commitment == LibOpen._getCommitment(2))
			collateral.amount += ds.indAccruedAPY[_account][_market][_commitment].accruedYield - deductibleInterest.accruedInterest;
		else if (loan.commitment == LibOpen._getCommitment(2))
			collateral.amount -= deductibleInterest.accruedInterest;

		delete ds.indAccruedAPY[_account][_market][_commitment];
		delete ds.indAccruedAPR[_account][_market][_commitment];
		delete ds.loanPassbook[_account].accruedAPR[loan.id - 1];
		delete ds.loanPassbook[_account].accruedAPY[loan.id - 1];

		uint256 cAmount = LibOpen._getLatestPrice(collateral.market)*collateral.amount;
		uint256 lAmountCurrent = LibOpen._getLatestPrice(loanState.currentMarket)*loanState.currentAmount;
		// convert collateral & loanCurrent into loanActual
		uint256 _repaymentAmount = LibOpen._swap(collateral.market, loan.market, cAmount, 2);
		_repaymentAmount += LibOpen._swap(loanState.currentMarket, loan.market, lAmountCurrent, 1);

		delete ds.indLoanState[_account][_market][_commitment];
		delete ds.indLoanRecords[_account][_market][_commitment];
		delete ds.indCollateralRecords[_account][_market][_commitment];

		delete ds.loanPassbook[_account].loanState[_id - 1];
		delete ds.loanPassbook[_account].loans[_id - 1];
		delete ds.loanPassbook[_account].collaterals[_id - 1];
		LibOpen._updateUtilisationLoan(loan.market, loan.amount, 1);

		emit LoanRepaid(_account, _id, loan.market, block.timestamp);
		emit Liquidation(_account,_market, _commitment, loan.amount, block.timestamp);
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
    	AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		console.log("superadminaddress is %s", ds.superAdminAddress);
		require(LibOpen._hasAdminRole(ds.superAdmin, ds.superAdminAddress) || LibOpen._hasAdminRole(ds.adminLoan1, ds.adminLoan1Address), "ERROR: Not an admin");

		_;
	}


}