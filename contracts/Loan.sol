// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./interfaces/ITokenList.sol";
import "./util/Pausable.sol";
// import "./mockup/IMockBep20.sol";
import "./util/IBEP20.sol";
import "./interfaces/IComptroller.sol";
import "./interfaces/IOracleOpen.sol";
import "./interfaces/IReserve.sol";
import "./interfaces/ILiquidator.sol";

contract Loan is Pausable {
	bytes32 adminLoan;
	address adminLoanAddress;
	address reserveAddress;
	address superAdminAddress;
	
	ITokenList markets;
	IComptroller comptroller;
	IOracleOpen oracle;
	ILiquidator liquidator;
	IReserve reserve;

	IBEP20 loanToken;
	IBEP20 collateralToken;
	IBEP20 withdrawToken;

	enum STATE {ACTIVE,REPAID}
	STATE state;

	struct LoanAccount {
		uint256 accOpenTime;
		address account;
		LoanRecords[] loans; // 2 types of loans. 3 markets intially. So, a maximum o f6 records.
		CollateralRecords[] collaterals;
		DeductibleInterest[] accruedAPR;
		CollateralYield[] accruedAPY;
		LoanState[] loanState;
	}
	struct LoanRecords {
		uint256 id;
		bytes32 market;
		bytes32 commitment;
		uint256 amount;
		bool isSwapped; //true or false. Update when a loan is swapped
		uint256 lastUpdate; // block.timestamp
	}

	struct LoanState {
		uint256 id; // loan.id
		bytes32 loanMarket;
		uint256 actualLoanAmount;
		bytes32 currentMarket;
		uint256 currentAmount;
		STATE state;
	}
	struct CollateralRecords {
		uint256 id;
		bytes32 market;
		bytes32 commitment;
		uint256 amount;
		bool isCollateralisedDeposit;
		uint256 timelockValidity;
		bool isTimelockActivated; // timelock duration
		uint256 activationTime; // blocknumber when yield withdrawal request was placed.
	}
	struct CollateralYield {
		uint256 id;
		bytes32 market;
		bytes32 commitment;
		uint256 oldLengthAccruedYield; // length of the APY time array.
		uint256 oldTime; // last recorded block num
		uint256 accruedYield; // accruedYield in
	}
	// DeductibleInterest{} stores the amount_ of interest deducted.
	struct DeductibleInterest {
		uint256 id; // Id of the loan the interest is being deducted for.
		bytes32 market; // market_ this yield is calculated for
		uint256 oldLengthAccruedInterest; // length of the APY time array.
		uint256 oldTime; // length of the APY time array.
		uint256 accruedInterest;
	}
	
	/// STRUCT Mapping
	mapping(address => LoanAccount) loanPassbook;
	mapping(address => mapping(bytes32 => mapping(bytes32 => LoanRecords))) indLoanRecords;
	mapping(address => mapping(bytes32 => mapping(bytes32 => CollateralRecords))) indCollateralRecords;
	mapping(address => mapping(bytes32 => mapping(bytes32 => DeductibleInterest))) indAccruedAPR;
	mapping(address => mapping(bytes32 => mapping(bytes32 => CollateralYield))) indAccruedAPY;
	mapping(address => mapping(bytes32 => mapping(bytes32 => LoanState))) indLoanState;

	///  Balance monitoring  - Loan
	mapping(bytes32 => uint) marketReserves; // mapping(market => marketBalance)
	mapping(bytes32 => uint) marketUtilisation; // mapping(market => marketBalance)

	/// EVENTS
	event NewLoan(
		address indexed _account,
		bytes32 indexed market,
		uint256 indexed amount,
		bytes32 loanCommitment,
		uint256 timestamp
	);
	event LoanRepaid(
		address indexed _account,
		uint256 indexed id,
		bytes32 indexed market,
		uint256 timestamp
	);
	event AddCollateral(
		address indexed _account,
		uint256 indexed id,
		uint256 amount,
		uint256 timestamp
	);
	event WithdrawalProcessed(
		address indexed _account,
		uint256 indexed id,
		uint256 indexed amount,
		bytes32 market,
		uint256 timestamp
	);
	event MarketSwapped(
		address indexed _account,
		uint256 indexed id,
		bytes32 marketFrom,
		bytes32 marketTo,
		uint256 timestamp
	);
	event CollateralReleased(
		address indexed _account,
		uint256 indexed amount,
		bytes32 indexed market,
		uint256 timestamp
	);

	event Liquidation(
		address indexed _account,
		bytes32 indexed market,
		bytes32 indexed commitment,
		uint256 amount,
		uint256 time
	);

	/// Constructor
	constructor(
		address _superAdminAddr,
		address _tokenListAddr,
		address _comptrollerAddr,
		address _reserveAddr,
		address _liquidatorAddr,
		address _oracleAddr
	) {
		adminLoanAddress = msg.sender;
		superAdminAddress = _superAdminAddr;
		markets = ITokenList(_tokenListAddr);
		comptroller = IComptroller(_comptrollerAddr);
		reserve = IReserve(_reserveAddr);
		liquidator = ILiquidator(_liquidatorAddr);
		oracle = IOracleOpen(_oracleAddr);
	}

	receive() external payable {
		 payable(adminLoanAddress).transfer(_msgValue());
	}
	
	fallback() external payable {
		payable(adminLoanAddress).transfer(_msgValue());
	}
	
	function transferAnyBEP20(address token_,address recipient_,uint256 value_) external authLoan returns(bool) {
		IBEP20(token_).transfer(recipient_, value_);
		return true;
	}

	// External view functions
	function hasLoanAccount(address _account) external view returns (bool) {
		_hasLoanAccount(_account);
		return true;
	}

	function _hasLoanAccount(address _account) internal view {
		require(loanPassbook[_account].accOpenTime !=0, "ERROR: No Loan Account");
	}

	function avblReserves(bytes32 _market) external view returns(uint) {
		return marketReserves[_market];
	}

	function utilisedReserves(bytes32 _market) external view returns(uint) {
		return marketUtilisation[_market];
	}

	function _updateReserves(bytes32 _market, uint256 _amount, uint256 _num) private
	{
		if (_num == 0)	{
			marketReserves[_market] += _amount;
		} else if (_num == 1)	{
			marketReserves[_market] -= _amount;
		}
	}

	function _updateUtilisation(bytes32 _market, uint256 _amount, uint256 _num) private 
	{
		if (_num == 0)	{
			marketUtilisation[_market] += _amount;
		} else if (_num == 1)	{
			marketUtilisation[_market] -= _amount;
		}
	}
	
	/// NEW LOAN REQUEST
	function loanRequest(
		bytes32 _market,
		bytes32 _commitment,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) external nonReentrant() returns (bool success) {
		_preLoanRequestProcess(_market,_loanAmount,_collateralMarket,_collateralAmount);

		LoanAccount storage loanAccount = loanPassbook[msg.sender];
		LoanRecords storage loan = indLoanRecords[msg.sender][_market][_commitment];

		require(loan.id == 0, "ERROR: Active loan");

		collateralToken.transfer(reserveAddress, _collateralAmount);
		_updateReserves(_collateralMarket,_collateralAmount, 0);
		_ensureLoanAccount(msg.sender, loanAccount);

		_processNewLoan(msg.sender,_market,_commitment,_loanAmount,_collateralMarket,_collateralAmount);

		emit NewLoan(msg.sender, _market, _loanAmount, _commitment, block.timestamp);
		return success;
	}

	function addCollateral(
		bytes32 _market,
		bytes32 _commitment,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) external returns (bool success) {

		LoanAccount storage loanAccount = loanPassbook[msg.sender];
		LoanRecords storage loan = indLoanRecords[msg.sender][_market][_commitment];
		LoanState storage loanState = indLoanState[msg.sender][_market][_commitment];
		CollateralRecords storage collateral = indCollateralRecords[msg.sender][_market][_commitment];
		CollateralYield storage cYield = indAccruedAPY[msg.sender][_market][_commitment];

		_preAddCollateralProcess(_collateralMarket, _collateralAmount, loanAccount, loan,loanState, collateral);
		
		uint256 num = loan.id-1;

		collateralToken = IBEP20(markets.connectMarket(_collateralMarket));
		markets.quantifyAmount(_collateralMarket, _collateralAmount);
		collateralToken.transfer(reserveAddress, _collateralAmount);
		_updateReserves(_collateralMarket, _collateralAmount, 0);

		_addCollateral(loanAccount, collateral, _collateralAmount,num);
		_accruedInterest(msg.sender, _market, _commitment);

		if (collateral.isCollateralisedDeposit) _accruedYield(loanAccount, collateral, cYield);

		emit AddCollateral(msg.sender, loan.id, _collateralAmount, block.timestamp);
		return success;
	}

	/// Swap loan to a secondary market.
	function swapLoan(
		bytes32 _market,
		bytes32 _commitment,
		bytes32 _swapMarket
	) external nonReentrant() returns (bool success) {
		_hasLoanAccount(msg.sender);
		
		markets.isMarketSupported(_market);
		markets.isMarket2Supported(_swapMarket);

		LoanAccount storage loanAccount = loanPassbook[msg.sender];
		LoanRecords storage loan = indLoanRecords[msg.sender][_market][_commitment];
		LoanState storage loanState = indLoanState[msg.sender][_market][_commitment];
		CollateralRecords storage collateral = indCollateralRecords[msg.sender][_market][_commitment];
		CollateralYield storage cYield = indAccruedAPY[msg.sender][_market][_commitment];

		require(loan.id != 0, "ERROR: No loan");
		require(loan.isSwapped == false && loanState.currentMarket == _market, "ERROR: Already swapped");
		
		uint256 _swappedAmount;
		uint256 num = loan.id - 1;

		_swappedAmount = liquidator.swap(_market, _swapMarket, loan.amount, 0);

		/// Updating LoanRecord
		loan.isSwapped = true;
		loan.lastUpdate = block.timestamp;
		/// Updating LoanState
		loanState.currentMarket = _swapMarket;
		loanState.currentAmount = _swappedAmount;

		/// Updating LoanAccount
		loanAccount.loans[num].isSwapped = true;
		loanAccount.loans[num].lastUpdate = block.timestamp;
		loanAccount.loanState[num].currentMarket = _swapMarket;
		loanAccount.loanState[num].currentAmount = _swappedAmount;

		_accruedInterest(msg.sender, _market, _commitment);
		if (collateral.isCollateralisedDeposit) _accruedYield(loanAccount, collateral, cYield);

		emit MarketSwapped(msg.sender,loan.id,_market,_swapMarket,block.timestamp);
		return success;
	}

	/// SwapToLoan
	function swapToLoan(
		bytes32 _swapMarket,
		bytes32 _commitment,
		bytes32 _market
	) external nonReentrant() returns (bool success) {

		uint256 _swappedAmount;
		_swapToLoan(msg.sender, _swapMarket,_commitment, _market, _swappedAmount);
		
		return success;
	}

	function _swapToLoan(
		address _account,
		bytes32 _swapMarket,
		bytes32 _commitment,
		bytes32 _market,
		uint256 _swappedAmount
	) private	{
		_hasLoanAccount(msg.sender);
		
		markets.isMarketSupported(_market);
		markets.isMarket2Supported(_swapMarket);

		LoanRecords storage loan = indLoanRecords[_account][_market][_commitment];
		LoanState storage loanState = indLoanState[_account][_market][_commitment];
		CollateralRecords storage collateral = indCollateralRecords[_account][_market][_commitment];
		CollateralYield storage cYield = indAccruedAPY[_account][_market][_commitment];

		require(loan.id != 0, "ERROR: No loan");
		require(loan.isSwapped == true && loanState.currentMarket == _swapMarket, "ERROR: Swapped market does not exist");
		// require(loan.isSwapped == true, "Swapped market does not exist");

		uint256 num = loan.id - 1;

		_swappedAmount = liquidator.swap(_swapMarket,_market,loanState.currentAmount, 1);

		/// Updating LoanRecord
		loan.isSwapped = false;
		loan.lastUpdate = block.timestamp;

		/// updating the LoanState
		loanState.currentMarket = _market;
		loanState.currentAmount = _swappedAmount;

		/// Updating LoanAccount
		loanPassbook[_account].loans[num].isSwapped = false;
		loanPassbook[_account].loans[num].lastUpdate = block.timestamp;
		loanPassbook[_account].loanState[num].currentMarket = _market;
		loanPassbook[_account].loanState[num].currentAmount = _swappedAmount;

		_accruedInterest(msg.sender, _market, _commitment);
		_accruedYield(loanPassbook[_account], collateral, cYield);

		emit MarketSwapped(msg.sender,loan.id,_swapMarket,_market,block.timestamp);
	}

	function withdrawCollateral(bytes32 _market, bytes32 _commitment) external returns (bool success) {

		LoanAccount storage loanAccount = loanPassbook[msg.sender];
		LoanRecords storage loan = indLoanRecords[msg.sender][_market][_commitment];
		CollateralRecords storage collateral = indCollateralRecords[msg.sender][_market][_commitment];
		
		_withdrawCollateral(msg.sender, loanAccount, loan);
		_updateReserves(collateral.market, collateral.amount, 1);

		emit CollateralReleased(msg.sender, collateral.amount, collateral.market, block.timestamp);
		return success;
	}

	function _withdrawCollateral(address _account, LoanAccount storage loanAccount,LoanRecords storage loan) private	{

		reserve.collateralTransfer(_account, loan.market, loan.commitment);

		delete indCollateralRecords[_account][loan.market][loan.commitment];
		delete indLoanState[_account][loan.market][loan.commitment];
		delete indLoanRecords[_account][loan.market][loan.commitment];

		delete loanAccount.loanState[loan.id-1];
		delete loanAccount.loans[loan.id-1];		
		delete loanAccount.collaterals[loan.id-1];
	}

	function collateralPointer(address _account, bytes32 _market, bytes32 _commitment, bytes32 collateralMarket, uint collateralAmount) external view{
		
		_hasLoanAccount(_account);

		LoanRecords storage loan = indLoanRecords[_account][_market][_commitment];
		LoanState storage loanState = indLoanState[_account][_market][_commitment];
		CollateralRecords storage collateral = indCollateralRecords[_account][_market][_commitment];

		require(loan.id !=0, "ERROR: No Loan");
		require(loanState.state == STATE.REPAID, "ERROR: Active loan");
		require((collateral.timelockValidity + collateral.activationTime) >= block.timestamp, "ERROR: Timelock in progress");
		
		collateralMarket = collateral.market;
		collateralAmount = collateral.amount;
	}


	function repayLoan(bytes32 _market,bytes32 _commitment,uint256 _repayAmount) external  returns (bool success) {
		
		_hasLoanAccount(msg.sender);
		LoanRecords storage loan = indLoanRecords[msg.sender][_market][_commitment];
		LoanState storage loanState = indLoanState[msg.sender][_market][_commitment];
		CollateralRecords storage collateral = indCollateralRecords[msg.sender][_market][_commitment];
		DeductibleInterest storage deductibleInterest = indAccruedAPR[msg.sender][_market][_commitment];
		CollateralYield storage cYield = indAccruedAPY[msg.sender][_market][_commitment];
		
		require(loan.id != 0,"ERROR: No Loan");

		uint256 _remnantAmount;
		uint256 num = loan.id - 1;

		_accruedInterest(msg.sender, _market, _commitment);
		_accruedYield(loanPassbook[msg.sender], collateral, cYield);

		if (_repayAmount == 0) {
			// converting the current market into loanMarket for repayment.
			if (loanState.currentMarket == _market)	_repayAmount = loanState.currentAmount;
			else if (loanState.currentMarket != _market)	_repayAmount = liquidator.swap(loanState.currentMarket,_market,loanState.currentAmount, 1);
			
			_repaymentProcess(msg.sender,_repayAmount,loanPassbook[msg.sender],loan,loanState,collateral,deductibleInterest,cYield);
			
			// if (loanState.currentMarket == _market) {
			// 	_repayAmount = loanState.currentAmount;
			// 	_repaymentProcess(msg.sender,_repayAmount,loanPassbook[msg.sender],loan,loanState,collateral,deductibleInterest,cYield);
				
			// } else if (loanState.currentMarket != _market) {
			// 	_repayAmount = liquidator.swap(loanState.currentMarket,_market,loanState.currentAmount, 1);
			// 	_repaymentProcess(msg.sender,_repayAmount,loanPassbook[msg.sender],loan,loanState,collateral,deductibleInterest,cYield);
			// }
		}
		else if (_repayAmount > 0) {
			/// transfering the repayAmount to the reserve contract.
			loanToken = IBEP20(markets.connectMarket(_market));
			markets.quantifyAmount(_market, _repayAmount);

			collateral.amount += (cYield.accruedYield - deductibleInterest.accruedInterest);
			
			uint256 _swappedAmount;

			if (_repayAmount >= loan.amount) {
				_remnantAmount = _repayAmount - loan.amount;

				if (loanState.currentMarket == _market){
					_remnantAmount += loanState.currentAmount;
				}
				else {
					_swapToLoan(msg.sender, loanState.currentMarket, _commitment, _market, _swappedAmount);
					_repayAmount += _swappedAmount;
				}	

				_updateDebtRecords(loanPassbook[msg.sender],loan,loanState,collateral/*, deductibleInterest, cYield*/);
				loanToken.transferFrom(reserveAddress,loanPassbook[msg.sender].account,_remnantAmount);

				emit LoanRepaid(msg.sender, loan.id, loan.market, block.timestamp);
				
				if (_commitment == comptroller.getCommitment(0)) {
					/// transfer collateral.amount from reserve contract to the msg.sender
					// collateralToken = IBEP20(markets.connectMarket(collateral.market));
					reserve.transferAnyBEP20(markets.connectMarket(collateral.market), loanPassbook[msg.sender].account,collateral.amount);

			/// delete loan Entries, loanRecord, loanstate, collateralrecords
					// delete loanState;
					// delete loan;
					// delete collateral;

					delete indLoanRecords[msg.sender][_market][_commitment];
					delete indLoanState[msg.sender][_market][_commitment];
					delete indCollateralRecords[msg.sender][_market][_commitment];


					delete loanPassbook[msg.sender].loanState[num];
					delete loanPassbook[msg.sender].loans[num];
					delete loanPassbook[msg.sender].collaterals[num];
					
					_updateReserves(collateral.market, collateral.amount, 1);
					emit CollateralReleased(msg.sender,collateral.amount,collateral.market,block.timestamp);
				}
			} else if (_repayAmount < loan.amount) {

				if (loanState.currentMarket == _market)	_repayAmount += loanState.currentAmount;
				else if (loanState.currentMarket != _market) {
					_swapToLoan(msg.sender, loanState.currentMarket, _commitment, _market, _swappedAmount);
					_repayAmount += _swappedAmount;
				}
				
				if (_repayAmount > loan.amount) {
					_remnantAmount = _repayAmount - loan.amount;
					loanToken.transferFrom(reserveAddress, loanPassbook[msg.sender].account, _remnantAmount);
				} else if (_repayAmount <= loan.amount) {
					
					_repayAmount += liquidator.swap(collateral.market,_market,collateral.amount, 1);
					// _repayAmount += _swapToLoan(loanState.currentMarket, _commitment, _market);
					_remnantAmount = _repayAmount - loan.amount;
					collateral.amount += liquidator.swap(loan.market,collateral.market,_remnantAmount, 2);
				}
				_updateDebtRecords(loanPassbook[msg.sender],loan,loanState,collateral/*, deductibleInterest, cYield*/);
				
				if (_commitment == comptroller.getCommitment(0)) {
					
					// collateralToken = IBEP20(markets.connectMarket(collateral.market));
					reserve.transferAnyBEP20(markets.connectMarket(collateral.market), loanPassbook[msg.sender].account, collateral.amount);


				/// delete loan Entries, loanRecord, loanstate, collateralrecords
					// delete loanState;
					// delete loan;
					// delete collateral;
					delete indLoanRecords[msg.sender][_market][_commitment];
					delete indLoanState[msg.sender][_market][_commitment];
					delete indCollateralRecords[msg.sender][_market][_commitment];

					delete loanPassbook[msg.sender].loanState[num];
					delete loanPassbook[msg.sender].loans[num];
					delete loanPassbook[msg.sender].collaterals[num];
					
					_updateReserves(collateral.market, collateral.amount, 1);
					emit CollateralReleased(msg.sender,collateral.amount,collateral.market,block.timestamp);
				}
			}
		}
		
		_updateUtilisation(loan.market, loan.amount, 1);
		return success;
	}

	function _accruedYield(LoanAccount storage loanAccount, CollateralRecords storage collateral, CollateralYield storage cYield) private {

		bytes32 _commitment = cYield.commitment;
		uint256 aggregateYield;
		uint256 num = collateral.id-1;
		
		comptroller.calcAPY(_commitment, cYield.oldLengthAccruedYield, cYield.oldTime, aggregateYield);

		aggregateYield *= collateral.amount;

		cYield.accruedYield += aggregateYield;
		loanAccount.accruedAPY[num].accruedYield += aggregateYield;
	}

	function _addCollateral(
		LoanAccount storage loanAccount,
		CollateralRecords storage collateral,
		uint256 _collateralAmount,
		uint256 num
	) internal {
		collateral.amount += _collateralAmount;
		loanAccount.collaterals[num].amount = collateral.amount;
	}

	function _updateDebtRecords(LoanAccount storage loanAccount,LoanRecords storage loan, LoanState storage loanState, CollateralRecords storage collateral/*, DeductibleInterest storage deductibleInterest, CollateralYield storage cYield*/) private {
		uint256 num = loan.id - 1;
		bytes32 _market = loan.market;

		loan.amount = 0;
		loan.isSwapped = false;
		loan.lastUpdate = block.timestamp;
		
		loanState.currentMarket = _market;
		loanState.currentAmount = 0;
		loanState.actualLoanAmount = 0;
		loanState.state = STATE.REPAID;

		collateral.isCollateralisedDeposit = false;
		collateral.isTimelockActivated = true;
		collateral.activationTime = block.timestamp;

		// delete cYield;
		// delete deductibleInterest;
		delete indAccruedAPY[loanAccount.account][loan.market][loan.commitment];
		delete indAccruedAPR[loanAccount.account][loan.market][loan.commitment];

		// Updating LoanPassbook
		loanAccount.loans[num].amount = 0;
		loanAccount.loans[num].isSwapped = false;
		loanAccount.loans[num].lastUpdate = block.timestamp;

		loanAccount.loanState[num].currentMarket = _market;
		loanAccount.loanState[num].currentAmount = 0;
		loanAccount.loanState[num].actualLoanAmount = 0;
		loanAccount.loanState[num].state = STATE.REPAID;
		
		loanAccount.collaterals[num].isCollateralisedDeposit = false;
		loanAccount.collaterals[num].isTimelockActivated = true;
		loanAccount.collaterals[num].activationTime = block.timestamp;

		
		delete loanAccount.accruedAPY[num];
		delete loanAccount.accruedAPR[num];
	}

	function _accruedInterest(address _account, bytes32 _loanMarket, bytes32 _commitment) internal {

		LoanAccount storage loanAccount = loanPassbook[_account];
		LoanRecords storage loan = indLoanRecords[_account][_loanMarket][_commitment];
		DeductibleInterest storage deductibleInterest = indAccruedAPR[_account][_loanMarket][_commitment];

		require(indLoanState[_account][_loanMarket][_commitment].state == STATE.ACTIVE, "ERROR: INACTIVE LOAN");
		require(deductibleInterest.id != 0, "ERROR: APR does not exist");

		uint256 aggregateYield;
		uint256 deductibleUSDValue;
		uint256 oldLengthAccruedInterest;
		uint256 oldTime;

		comptroller.calcAPR(loan.commitment, oldLengthAccruedInterest,oldTime, aggregateYield);

		deductibleUSDValue = ((loan.amount) * oracle.getLatestPrice(markets.getMarketAddress(_loanMarket))) * aggregateYield;
		deductibleInterest.accruedInterest +=deductibleUSDValue / oracle.getLatestPrice(markets.getMarketAddress(indCollateralRecords[_account][_loanMarket][_commitment].market));
		deductibleInterest.oldLengthAccruedInterest = oldLengthAccruedInterest;
		deductibleInterest.oldTime = oldTime;

		loanAccount.accruedAPR[loan.id - 1].accruedInterest = deductibleInterest.accruedInterest;
		loanAccount.accruedAPR[loan.id - 1].oldLengthAccruedInterest = oldLengthAccruedInterest;
		loanAccount.accruedAPR[loan.id - 1].oldTime = oldTime;
	}

	function permissibleWithdrawal(bytes32 _market,bytes32 _commitment, bytes32 _collateralMarket, uint256 _amount) external returns (bool success) {
		
		_hasLoanAccount(msg.sender);

		LoanRecords storage loan = indLoanRecords[msg.sender][_market][_commitment];
		LoanState storage loanState = indLoanState[msg.sender][_market][_commitment];
		
		_checkPermissibleWithdrawal(_market, _commitment, _collateralMarket, _amount);
		
		withdrawToken = IBEP20(markets.connectMarket(loanState.currentMarket));
		withdrawToken.transfer(msg.sender,_amount);

		emit WithdrawalProcessed(msg.sender, loan.id, _amount, loanState.currentMarket, block.timestamp);

		success = true;
	}

	function _checkPermissibleWithdrawal(bytes32 _market,bytes32 _commitment, bytes32 _collateralMarket, uint256 _amount) internal {
		LoanRecords storage loan = indLoanRecords[msg.sender][_market][_commitment];
		LoanState storage loanState = indLoanState[msg.sender][_market][_commitment];
		CollateralRecords storage collateral = indCollateralRecords[msg.sender][_market][_commitment];
		DeductibleInterest storage deductibleInterest = indAccruedAPR[msg.sender][_market][_commitment];
		
		markets.quantifyAmount(loanState.currentMarket, _amount);
		require(_amount <= loanState.currentAmount, "ERROR: Exceeds available loan");
		
		_accruedInterest(msg.sender, _market, _commitment);
		uint256 collateralAvbl = collateral.amount - deductibleInterest.accruedInterest;

		// fetch usdPrices
		uint256 usdCollateral = oracle.getLatestPrice(markets.getMarketAddress(_collateralMarket));
		uint256 usdLoan = oracle.getLatestPrice(markets.getMarketAddress(_market));
		uint256 usdLoanCurrent = oracle.getLatestPrice(markets.getMarketAddress(loanState.currentMarket));

		// Quantification of the assets
		uint256 cAmount = usdCollateral*collateral.amount;
		uint256 cAmountAvbl = usdCollateral*collateralAvbl;

		uint256 lAmountCurrent = usdLoanCurrent*loanState.currentAmount;
		uint256 permissibleAmount = ((cAmountAvbl - (30*cAmount/100))/usdLoanCurrent);

		require(permissibleAmount > 0, "ERROR: Can not withdraw zero funds");
		require(permissibleAmount > (_amount), "ERROR:Request exceeds funds");
		
		// calcualted in usdterms
		require((cAmountAvbl + lAmountCurrent - (_amount*usdLoanCurrent)) >= (11*(usdLoan*loan.amount)/10), "ERROR: Risks liquidation");
	}

	function _repaymentProcess(
		address _account,
		uint256 _repayAmount,
		LoanAccount storage loanAccount,
		LoanRecords storage loan,
		LoanState storage loanState,
		CollateralRecords storage collateral,
		DeductibleInterest storage deductibleInterest,
		CollateralYield storage cYield
	) internal {
		
		bytes32 _commitment = loan.commitment;
		uint256 num = loan.id - 1;
		
		// convert collateral into loan market to add to the repayAmount
		uint256 collateralAmount = collateral.amount - (deductibleInterest.accruedInterest + cYield.accruedYield);
		_repayAmount += liquidator.swap(collateral.market,loan.market,collateralAmount,2);

		// Excess amount is tranferred back to the collateral record
		uint256 _remnantAmount = _repayAmount - loan.amount;
		collateral.amount = liquidator.swap(loan.market,collateral.market,_remnantAmount,2);

		/// updating LoanRecords
		loan.amount = 0;
		loan.isSwapped = false;
		loan.lastUpdate = block.timestamp;
		/// updating LoanState
		loanState.actualLoanAmount = 0;
		loanState.currentAmount = 0;
		loanState.state = STATE.REPAID;

		delete indAccruedAPR[_account][loan.market][loan.commitment];
		delete indAccruedAPY[_account][loan.market][loan.commitment];

		delete loanAccount.accruedAPR[num];
		delete loanAccount.accruedAPY[num];
		
		emit LoanRepaid(msg.sender, loan.id, loan.market, block.timestamp);

		if (_commitment == comptroller.getCommitment(2)) {
			/// updating CollateralRecords
			collateral.isCollateralisedDeposit = false;
			collateral.isTimelockActivated = true;
			collateral.activationTime = block.timestamp;

		} else if (_commitment == comptroller.getCommitment(0)) {
			/// transfer collateral.amount from reserve contract to the msg.sender
			collateralToken = IBEP20(markets.connectMarket(collateral.market));
			// reserveAddress.transferAnyBEP20(collateralToken, loanAccount.account, collateral.amount);

			/// delete loan Entries, loanRecord, loanstate, collateralrecords
			// delete loanState;
			// delete loan;
			// delete collateral;
			delete indCollateralRecords[_account][loan.market][loan.commitment];
			delete indLoanState[_account][loan.market][loan.commitment];
			delete indLoanRecords[_account][loan.market][loan.commitment];

			delete loanAccount.collaterals[num];
			delete loanAccount.loanState[num];
			delete loanAccount.loans[num];

			_updateReserves(collateral.market, collateral.amount, 1);
			emit CollateralReleased(_account,collateral.amount,collateral.market,block.timestamp);
		}

	}

	function liquidation(address _account, uint256 id) external nonReentrant()	authLoan() returns (bool success) {
		
		bytes32 _commitment = loanPassbook[_account].loans[id-1].commitment;
		bytes32 _market = loanPassbook[_account].loans[id-1].market;

		LoanRecords storage loan = indLoanRecords[_account][_market][_commitment];
		LoanState storage loanState = indLoanState[_account][_market][_commitment];
		CollateralRecords storage collateral = indCollateralRecords[_account][_market][_commitment];
		DeductibleInterest storage deductibleInterest = indAccruedAPR[_account][_market][_commitment];
		CollateralYield storage cYield = indAccruedAPY[_account][_market][_commitment];

		require(loan.id == id, "ERROR: id mismatch");

		_accruedInterest(_account, _market, _commitment);
		
		if (loan.commitment == comptroller.getCommitment(2))
			collateral.amount += cYield.accruedYield - deductibleInterest.accruedInterest;
		else if (loan.commitment == comptroller.getCommitment(2))
			collateral.amount -= deductibleInterest.accruedInterest;

		// delete cYield;
		// delete deductibleInterest;
		// delete loanPassbook[_account].accruedAPR[loan.id - 1];
		// delete loanPassbook[_account].accruedAPY[loan.id - 1];

		// Convert to USD.
		// uint256 usdCollateral = oracle.getLatestPrice(collateral.market);
		// uint256 usdLoanCurrent = oracle.getLatestPrice(loanState.currentMarket);
		// uint256 usdLoanActual = oracle.getLatestPrice(loan.market);
		uint256 cAmount = oracle.getLatestPrice(markets.getMarketAddress(collateral.market))*collateral.amount;
		uint256 lAmountCurrent = oracle.getLatestPrice(markets.getMarketAddress(loanState.currentMarket))*loanState.currentAmount;
		// convert collateral & loanCurrent into loanActual
		uint256 _repaymentAmount = liquidator.swap(collateral.market, loan.market, cAmount, 2);
		_repaymentAmount += liquidator.swap(loanState.currentMarket, loan.market, lAmountCurrent, 1);
		// uint256 _remnantAmount = _repaymentAmount - lAmount;

		// uint256 num = id - 1;
		// delete loanState;
		// delete loan;
		// delete collateral;

		// delete loanPassbook[_account].loanState[num];
		// delete loanPassbook[_account].loans[num];
		// delete loanPassbook[_account].collaterals[num];
		_updateUtilisation(loan.market, loan.amount, 1);

		emit LoanRepaid(_account, id, loan.market, block.timestamp);
		emit Liquidation(_account,_market, _commitment, loan.amount, block.timestamp);
		
		return success;
	}

	function _preLoanRequestProcess(
		bytes32 _market,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) internal {
		require(
			_loanAmount != 0 && _collateralAmount != 0,
			"Loan or collateral cannot be zero"
		);

		_permissibleCDR(_market,_collateralMarket,_loanAmount,_collateralAmount);

		// Check for amrket support
		markets.isMarketSupported(_market);
		markets.isMarketSupported(_collateralMarket);

		markets.quantifyAmount(_market, _loanAmount);
		markets.quantifyAmount(_collateralMarket, _collateralAmount);

		// check for minimum permissible amount
		markets.minAmountCheck(_market, _loanAmount);
		markets.minAmountCheck(_collateralMarket, _collateralAmount);

		// Connect
		loanToken = IBEP20(markets.connectMarket(_market));
		collateralToken = IBEP20(markets.connectMarket(_collateralMarket));	
	}

	function _processNewLoan(
		address _account,
		bytes32 _market,
		bytes32 _commitment,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) internal {
		uint256 id;

		LoanAccount storage loanAccount = loanPassbook[_account];
		LoanRecords storage loan = indLoanRecords[_account][_market][_commitment];
		LoanState storage loanState = indLoanState[_account][_market][_commitment];
		CollateralRecords storage collateral = indCollateralRecords[_account][_market][_commitment];
		DeductibleInterest storage deductibleInterest = indAccruedAPR[_account][_market][_commitment];
		CollateralYield storage cYield = indAccruedAPY[_account][_market][_commitment];

		if (loanAccount.loans.length == 0) {
			id = 1;
		} else if (loanAccount.loans.length != 0) {
			id = loanAccount.loans.length + 1;
		}

		// Updating loanRecords
		loan.id = id;
		loan.market = _market;
		loan.commitment = _commitment;
		loan.amount = _loanAmount;
		loan.isSwapped = false;
		loan.lastUpdate = block.timestamp;

		// Updating deductibleInterest
		deductibleInterest.id = id;
		deductibleInterest.market = _collateralMarket;
		deductibleInterest.oldTime= block.timestamp;
		deductibleInterest.accruedInterest = 0;

		// Updating loanState
		loanState.id = id;
		loanState.loanMarket = _market;
		loanState.actualLoanAmount = _loanAmount;
		loanState.currentMarket = _market;
		loanState.currentAmount = _loanAmount;
		loanState.state = STATE.ACTIVE;
					
		collateral.id= id;
		collateral.market= _collateralMarket;
		collateral.commitment= _commitment;
		collateral.amount = _collateralAmount;

		loanAccount.loans.push(loan);
		loanAccount.loanState.push(loanState);

		if (_commitment == comptroller.getCommitment(0)) {
			
			collateral.isCollateralisedDeposit = false;
			collateral.timelockValidity = 0;
			collateral.isTimelockActivated = true;
			collateral.activationTime = 0;

			// pays 18% APR
			deductibleInterest.oldLengthAccruedInterest = comptroller.getAprTimeLength(_commitment);

			loanAccount.collaterals.push(collateral);
			loanAccount.accruedAPR.push(deductibleInterest);
			// loanAccount.accruedAPY.push(accruedYield); - no yield because it is
			// a flexible loan
		} else if (_commitment == comptroller.getCommitment(2)) {
			
			collateral.isCollateralisedDeposit = true;
			collateral.timelockValidity = 86400;
			collateral.isTimelockActivated = false;
			collateral.activationTime = 0;

			// 15% APR
			deductibleInterest.oldLengthAccruedInterest = comptroller.getAprTimeLength(_commitment);
			
			cYield.id = id;
			cYield.market = _collateralMarket;
			cYield.commitment = comptroller.getCommitment(1);
			cYield.oldLengthAccruedYield = comptroller.getApyTimeLength(_commitment);
			cYield.oldTime = block.timestamp;
			cYield.accruedYield =0;

			loanAccount.collaterals.push(collateral);
			loanAccount.accruedAPY.push(cYield);
			loanAccount.accruedAPR.push(deductibleInterest);
		}
		_updateUtilisation(_market, _loanAmount, 0);

	}

	function _preAddCollateralProcess(
		bytes32 _collateralMarket,
		uint256 _collateralAmount,
		LoanAccount memory loanAccount,
		LoanRecords memory loan,
		LoanState memory loanState,
		CollateralRecords memory collateral
	) internal view {

		require(loanAccount.accOpenTime != 0, "ERROR: No Loan _account");
		require(loan.id != 0, "ERROR: No loan");
		require(loanState.state == STATE.ACTIVE, "ERROR: Inactive loan");
		require(collateral.market == _collateralMarket, "ERROR: Mismatch collateral market");

		markets.isMarketSupported(_collateralMarket);
		markets.minAmountCheck(_collateralMarket, _collateralAmount);
	}

	function _ensureLoanAccount(address _account, LoanAccount storage loanAccount)
		private
	{
		if (loanAccount.accOpenTime == 0) {
			loanAccount.accOpenTime = block.timestamp;
			loanAccount.account = _account;
		}
	}

	function _permissibleCDR (
		bytes32 _market,
		bytes32 _collateralMarket,
		uint256 _loanAmount,
		uint256 _collateralAmount
	) internal view {
		//  check if the
		
		uint256 loanByCollateral;
		uint256 amount = reserve.avblMarketReserves(_market) - _loanAmount ;

		uint256 usdLoan = (oracle.getLatestPrice(markets.getMarketAddress(_market)))*_loanAmount;
		uint256 usdCollateral = (oracle.getLatestPrice(markets.getMarketAddress(_collateralMarket)))*_collateralAmount;

		require(amount > 0, "ERROR: Loan exceeds reserves");
		require(reserve.marketReserves(_market) / amount >= 10, "ERROR: Minimum reserve exeception");
		require (usdLoan/usdCollateral <=3, "ERROR: Exceeds permissible CDR");

		// calculating cdrPermissible.
		if (reserve.marketReserves(_market) / amount >= comptroller.getReserveFactor())	{
			loanByCollateral = 3;
		} else 	{
			loanByCollateral = 2;
		}
		require (usdLoan/usdCollateral <= loanByCollateral, "ERROR: Exceeds permissible CDR");
	}

	function pause() external authLoan() nonReentrant() {
		_pause();
	}
	
	function unpause() external authLoan() nonReentrant() {
		_unpause();   
	}

	modifier authLoan() {
		require(
			msg.sender == adminLoanAddress,
			"ERROR: Require Admin access"
		);
		_;
	}
}