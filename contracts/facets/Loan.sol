// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Pausable.sol";
import "../libraries/LibOpen.sol";

contract Loan is Pausable, ILoan {
	
	event CollateralReleased(
		address indexed account,
		uint256 indexed amount,
		bytes32 indexed market,
		uint256 timestamp
	);

	event LoanRepaid(
		address indexed account,
		uint256 indexed id,
		bytes32 indexed market,
		uint256 timestamp
	);
	event MarketSwapped(
		address indexed account,
		uint256 indexed loanid,
		bytes32 marketFrom,
		bytes32 marketTo,
		uint256 amount
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
		AppStorageOpen storage ds = LibOpen.diamondStorage();
		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_loanMarket][_commitment];
		LibOpen._swapLoan(msg.sender, _loanMarket, _commitment, _swapMarket);
		emit MarketSwapped(msg.sender,loan.id,_loanMarket,_swapMarket, loan.amount);
		return true;
	}

/// SwapToLoan
	function swapToLoan(
		bytes32 _swapMarket,
		bytes32 _commitment,
		bytes32 _loanMarket
	) external override nonReentrant() returns (bool) {
		
		AppStorageOpen storage ds = LibOpen.diamondStorage();
		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_loanMarket][_commitment];
		
		uint _swappedAmount = LibOpen._swapToLoan(msg.sender, _swapMarket, _commitment, _loanMarket);
		
		emit MarketSwapped(msg.sender,loan.id,_swapMarket,_loanMarket,_swappedAmount);
		return true;
	}

	function withdrawCollateral(bytes32 _loanMarket, bytes32 _commitment) external override nonReentrant() returns (bool) {
		
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_loanMarket][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[msg.sender][_loanMarket][_commitment];
		// LoanState storage loanState = ds.indLoanState[msg.sender][_loanMarket][_commitment];
		
		LibOpen._isMarketSupported(_loanMarket);
		require(ds.marketReservesLoan[collateral.market] >= collateral.amount, "ERROR: Amount exceeds balance");
		//Below are checked in _collateralPointer

		// _hasLoanAccount(msg.sender);
		// require(loan.id !=0, "ERROR: No Loan");
		// require(loanState.state == ILoan.STATE.REPAID, "ERROR: Active loan");
		// if (_commitment != _getCommitment(0)) {
		// 	require((collateral.timelockValidity + collateral.activationTime) >= block.timestamp, "ERROR: Timelock in progress");
		// }

//		_collateralTransfer(msg.sender, loan.market, loan.commitment);

        uint collateralAmount;

		(, collateralAmount) = LibOpen._collateralPointer(msg.sender,_loanMarket,_commitment);
		ds.token = IBEP20(LibOpen._connectMarket(collateral.market));
		// ds.token.approveFrom(ds.reserveAddress, address(this), collateralAmount);
    	// ds.token.transferFrom(ds.reserveAddress, msg.sender, collateralAmount);
		ds.token.transfer(msg.sender, collateralAmount);

		delete ds.indCollateralRecords[msg.sender][loan.market][loan.commitment];
		delete ds.indLoanState[msg.sender][loan.market][loan.commitment];
		delete ds.indLoanRecords[msg.sender][loan.market][loan.commitment];

		// delete loanAccount.loanState[loan.id-1];
		// delete loanAccount.loans[loan.id-1];
		// delete loanAccount.collaterals[loan.id-1];
    	LibOpen._updateReservesLoan(collateral.market, collateral.amount, 1);

		emit CollateralReleased(msg.sender, collateral.amount, collateral.market, block.timestamp);

		return true;
	}

	function repayLoan(bytes32 _loanMarket,bytes32 _commitment,uint256 _repayAmount) external override nonReentrant() returns (bool) {
		// AppStorageOpen storage ds = diamondStorage(); 
        LibOpen._hasLoanAccount(msg.sender);
		// LoanRecords storage loan = ds.indLoanRecords[msg.sender][_loanMarket][_commitment];
		// LoanState storage loanState = ds.indLoanState[msg.sender][_loanMarket][_commitment];
		// CollateralRecords storage collateral = ds.indCollateralRecords[msg.sender][_loanMarket][_commitment];
		// DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[msg.sender][_loanMarket][_commitment];
		// CollateralYield storage cYield = ds.indAccruedAPY[msg.sender][_loanMarket][_commitment];		
		
		require(LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].id != 0,"ERROR: No Loan");
		LibOpen._isMarketSupported(_loanMarket);
		
		LibOpen._accruedInterest(msg.sender, _loanMarket, _commitment);
		LibOpen._accruedYield(LibOpen.diamondStorage().loanPassbook[msg.sender], LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment], LibOpen.diamondStorage().indAccruedAPY[msg.sender][_loanMarket][_commitment]);

		if (_repayAmount == 0) {
			// converting the current market into loanMarket for repayment.
			if (LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment].currentMarket == _loanMarket)	_repayAmount = LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment].currentAmount;
			else if (LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment].currentMarket != _loanMarket)	_repayAmount = LibOpen._swap(msg.sender, LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment].currentMarket, _loanMarket, LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment].currentAmount, 1);
			
			repaymentProcess(
				msg.sender,
				_repayAmount, 
				LibOpen.diamondStorage().loanPassbook[msg.sender],
				LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment],
				LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment],
				LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment],
				LibOpen.diamondStorage().indAccruedAPR[msg.sender][_loanMarket][_commitment], 
				LibOpen.diamondStorage().indAccruedAPY[msg.sender][_loanMarket][_commitment]);
			
			// if (loanState.currentMarket == _loanMarket) {
			// 	_repayAmount = loanState.currentAmount;
			// 	_repaymentProcess(msg.sender,_repayAmount,loanPassbook[msg.sender],loan,loanState,collateral,deductibleInterest,cYield);
				
			// } else if (loanState.currentMarket != _loanMarket) {
			// 	_repayAmount = liquidator.swap(loanState.currentMarket,_loanMarket,loanState.currentAmount, 1);
			// 	_repaymentProcess(msg.sender,_repayAmount,loanPassbook[msg.sender],loan,loanState,collateral,deductibleInterest,cYield);
			// }
		}
		else if (_repayAmount > 0) {
			/// transfering the repayAmount to the reserve contract.
			LibOpen.diamondStorage().loanToken = IBEP20(LibOpen._connectMarket(_loanMarket));
			// _quantifyAmount(_loanMarket, _repayAmount);

			LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].amount += (LibOpen.diamondStorage().indAccruedAPY[msg.sender][_loanMarket][_commitment].accruedYield - LibOpen.diamondStorage().indAccruedAPR[msg.sender][_loanMarket][_commitment].accruedInterest);
			
			uint256 _swappedAmount;
			uint256 _remnantAmount;

			if (_repayAmount >= LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].amount) {
				_remnantAmount = _repayAmount - LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].amount;
				if (LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment].currentMarket == _loanMarket){
					_remnantAmount += LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment].currentAmount;
				}
				else {
					_swappedAmount = LibOpen._swapToLoan(msg.sender, LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment].currentMarket, _commitment, _loanMarket);
					_repayAmount += _swappedAmount;
				}

				updateDebtRecords(LibOpen.diamondStorage().loanPassbook[msg.sender], LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment], LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment], LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment]/*, deductibleInterest, cYield*/);
				// LibOpen.diamondStorage().loanToken.approveFrom(LibOpen.diamondStorage().reserveAddress, address(this), _remnantAmount);
				// LibOpen.diamondStorage().loanToken.transferFrom(LibOpen.diamondStorage().reserveAddress, LibOpen.diamondStorage().loanPassbook[msg.sender].account, _remnantAmount);
				LibOpen.diamondStorage().loanToken.transfer(LibOpen.diamondStorage().loanPassbook[msg.sender].account, _remnantAmount);

				emit LoanRepaid(msg.sender, LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].id, LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].market, block.timestamp);
				
				if (_commitment == LibOpen._getCommitment(0)) {
					/// transfer collateral.amount from reserve contract to the msg.sender
					// collateralToken = IBEP20(markets.connectMarket(collateral.market));
					LibOpen._transferAnyBEP20(LibOpen._connectMarket(LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].market), msg.sender, LibOpen.diamondStorage().loanPassbook[msg.sender].account, LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].amount);

			/// delete loan Entries, loanRecord, loanstate, collateralrecords
					// delete loanState;
					// delete loan;
					// delete collateral;

					delete LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment];
					delete LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment];
					delete LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment];

					delete LibOpen.diamondStorage().loanPassbook[msg.sender].loanState[LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].id - 1];
					delete LibOpen.diamondStorage().loanPassbook[msg.sender].loans[LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].id - 1];
					delete LibOpen.diamondStorage().loanPassbook[msg.sender].collaterals[LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].id - 1];
					
					LibOpen._updateReservesLoan(LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].market, LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].amount, 1);
					emit CollateralReleased(msg.sender, LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].amount, LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].market,block.timestamp);
				}
			} else if (_repayAmount < LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].amount) {

				if (LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment].currentMarket == _loanMarket)	_repayAmount += LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment].currentAmount;
				else if (LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment].currentMarket != _loanMarket) {
					_swappedAmount = LibOpen._swapToLoan(msg.sender, LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment].currentMarket, _commitment, _loanMarket);
					_repayAmount += _swappedAmount;
				}
				
				if (_repayAmount > LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].amount) {
					_remnantAmount = _repayAmount - LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].amount;
					// LibOpen.diamondStorage().loanToken.approveFrom(LibOpen.diamondStorage().reserveAddress, address(this), _remnantAmount);
					// LibOpen.diamondStorage().loanToken.transferFrom(LibOpen.diamondStorage().reserveAddress, LibOpen.diamondStorage().loanPassbook[msg.sender].account, _remnantAmount);
					LibOpen.diamondStorage().loanToken.transfer(LibOpen.diamondStorage().loanPassbook[msg.sender].account, _remnantAmount);
				} else if (_repayAmount <= LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].amount) {
					
					_repayAmount += LibOpen._swap(msg.sender, LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].market,_loanMarket, LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].amount, 1);
					// _repayAmount += _swapToLoan(loanState.currentMarket, _commitment, _loanMarket);
					_remnantAmount = _repayAmount - LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].amount;
					LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].amount += LibOpen._swap(msg.sender, LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].market, LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].market,_remnantAmount, 2);
				}
				updateDebtRecords(LibOpen.diamondStorage().loanPassbook[msg.sender], LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment], LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment], LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment]/*, deductibleInterest, cYield*/);
				
				if (_commitment == LibOpen._getCommitment(0)) {
					
					// collateralToken = IBEP20(markets.connectMarket(collateral.market));
					LibOpen._transferAnyBEP20(LibOpen._connectMarket(LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].market), msg.sender, LibOpen.diamondStorage().loanPassbook[msg.sender].account, LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].amount);


				/// delete loan Entries, loanRecord, loanstate, collateralrecords
					// delete loanState;
					// delete loan;
					// delete collateral;
					delete LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment];
					delete LibOpen.diamondStorage().indLoanState[msg.sender][_loanMarket][_commitment];
					delete LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment];

					delete LibOpen.diamondStorage().loanPassbook[msg.sender].loanState[LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].id - 1];
					delete LibOpen.diamondStorage().loanPassbook[msg.sender].loans[LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].id - 1];
					delete LibOpen.diamondStorage().loanPassbook[msg.sender].collaterals[LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].id - 1];
					
					LibOpen._updateReservesLoan(LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].market, LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].amount, 1);
					emit CollateralReleased(msg.sender, LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].amount, LibOpen.diamondStorage().indCollateralRecords[msg.sender][_loanMarket][_commitment].market,block.timestamp);
				}
			}
		}
		
		LibOpen._updateUtilisationLoan(LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].market, LibOpen.diamondStorage().indLoanRecords[msg.sender][_loanMarket][_commitment].amount, 1);

		return true;
	}

	function repaymentProcess(
		address _account,
		uint256 _repayAmount,
		LoanAccount storage loanAccount,
		LoanRecords storage loan,
		LoanState storage loanState,
		CollateralRecords storage collateral,
		DeductibleInterest storage deductibleInterest,
		CollateralYield storage cYield
	) private {
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		
		bytes32 _commitment = loan.commitment;
		
		// convert collateral into loan market to add to the repayAmount
		// uint256 collateralAmount = collateral.amount - (deductibleInterest.accruedInterest + cYield.accruedYield);
		_repayAmount += LibOpen._swap(_account, collateral.market,loan.market, collateral.amount - (deductibleInterest.accruedInterest + cYield.accruedYield), 2);

		require(_repayAmount > loan.amount, "Repay Amount is smaller than loan Amount");

		// Excess amount is tranferred back to the collateral record
		uint256 _remnantAmount = _repayAmount - loan.amount;
		collateral.amount = LibOpen._swap(_account, loan.market,collateral.market,_remnantAmount,2);

		/// updating LoanRecords
		loan.amount = 0;
		loan.isSwapped = false;
		loan.lastUpdate = block.timestamp;
		/// updating LoanState
		loanState.actualLoanAmount = 0;
		loanState.currentAmount = 0;
		loanState.state = ILoan.STATE.REPAID;

		delete ds.indAccruedAPR[_account][loan.market][loan.commitment];
		delete ds.indAccruedAPY[_account][loan.market][loan.commitment];

		delete loanAccount.accruedAPR[loan.id - 1];
		delete loanAccount.accruedAPY[loan.id - 1];
		
		emit LoanRepaid(_account, loan.id, loan.market, block.timestamp);

		if (_commitment == LibOpen._getCommitment(2)) {
			/// updating CollateralRecords
			collateral.isCollateralisedDeposit = false;
			collateral.isTimelockActivated = true;
			collateral.activationTime = block.timestamp;

		} else if (_commitment == LibOpen._getCommitment(0)) {
			/// transfer collateral.amount from reserve contract to the msg.sender
			ds.collateralToken = IBEP20(LibOpen._connectMarket(collateral.market));
			// reserveAddress.transferAnyBEP20(collateralToken, loanAccount.account, collateral.amount);

			/// delete loan Entries, loanRecord, loanstate, collateralrecords
			// delete loanState;
			// delete loan;
			// delete collateral;
			delete ds.indCollateralRecords[_account][loan.market][loan.commitment];
			delete ds.indLoanState[_account][loan.market][loan.commitment];
			delete ds.indLoanRecords[_account][loan.market][loan.commitment];

			delete loanAccount.collaterals[loan.id - 1];
			delete loanAccount.loanState[loan.id - 1];
			delete loanAccount.loans[loan.id - 1];

			LibOpen._updateReservesLoan(collateral.market, collateral.amount, 1);
			emit CollateralReleased(_account,collateral.amount,collateral.market,block.timestamp);
		}
	}

	function updateDebtRecords(LoanAccount storage loanAccount,LoanRecords storage loan, LoanState storage loanState, CollateralRecords storage collateral/*, DeductibleInterest storage deductibleInterest, CollateralYield storage cYield*/) private {
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		uint256 num = loan.id - 1;
		bytes32 _loanMarket = loan.market;

		loan.amount = 0;
		loan.isSwapped = false;
		loan.lastUpdate = block.timestamp;
		
		loanState.currentMarket = _loanMarket;
		loanState.currentAmount = 0;
		loanState.actualLoanAmount = 0;
		loanState.state = ILoan.STATE.REPAID;

		collateral.isCollateralisedDeposit = false;
		collateral.isTimelockActivated = true;
		collateral.activationTime = block.timestamp;

		// delete cYield;
		// delete deductibleInterest;
		delete ds.indAccruedAPY[loanAccount.account][loan.market][loan.commitment];
		delete ds.indAccruedAPR[loanAccount.account][loan.market][loan.commitment];

		// Updating LoanPassbook
		loanAccount.loans[num].amount = 0;
		loanAccount.loans[num].isSwapped = false;
		loanAccount.loans[num].lastUpdate = block.timestamp;

		loanAccount.loanState[num].currentMarket = _loanMarket;
		loanAccount.loanState[num].currentAmount = 0;
		loanAccount.loanState[num].actualLoanAmount = 0;
		loanAccount.loanState[num].state = ILoan.STATE.REPAID;
		
		loanAccount.collaterals[num].isCollateralisedDeposit = false;
		loanAccount.collaterals[num].isTimelockActivated = true;
		loanAccount.collaterals[num].activationTime = block.timestamp;

		delete loanAccount.accruedAPY[num];
		delete loanAccount.accruedAPR[num];
	}

	function getFairPriceLoan(uint _requestId) external view override returns (uint){
		return LibOpen._getFairPrice(_requestId);
	}

	function collateralPointer(address _account, bytes32 _loanMarket, bytes32 _commitment) external view override returns (bool) {
    	LibOpen._collateralPointer(_account, _loanMarket, _commitment);
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
