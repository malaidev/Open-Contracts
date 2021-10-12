// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./TokenList.sol";
import "./Comptroller.sol";
import "./Deposit.sol";
import "./Reserve.sol";
import "./OracleOpen.sol";
import "./Liquidator.sol";
import "./util/IBEP20.sol";

contract Loan {
  bytes32 adminLoan;
  address adminLoanAddress;

  bool isReentrant = false;

  TokenList markets = TokenList(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
  Comptroller comptroller = Comptroller(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
  Deposit deposit = Deposit(0xeAc61D9e3224B20104e7F0BAD6a6DB7CaF76659B);
  OracleOpen oracle = OracleOpen(0xeAc61D9e3224B20104e7F0BAD6a6DB7CaF76659B);
  Liquidator liquidator = Liquidator(0xeAc61D9e3224B20104e7F0BAD6a6DB7CaF76659B);
  Reserve reserve = Reserve(payable(0xeAc61D9e3224B20104e7F0BAD6a6DB7CaF76659B)); 
  
  IBEP20 loanToken;
  IBEP20 collateralToken;
  IBEP20 swapToken;

  enum STATE {ACTIVE, REPAID}
  STATE state;

  struct LoanAccount {
    uint256 accOpenTime;
    address account;
    LoanRecords[] loans; // 2 types of loans. 3 markets intially. So, a maximum o f6 records.
    CollateralRecords[] collaterals;
    DeductibleInterest[] accruedInterest;
    CollateralYield[] accruedYield;
    LoanState[] loanState;
  }
  struct LoanRecords {
    uint256 id;
    uint256 amount;
    bytes32 market;
    bytes32 commitment;
    bool isSwapped; //true or false. Update when a loan is swapped
    uint256 lastUpdate; // block.timestamp
  }

  struct LoanState  {
    uint id; // loan.id
    bytes32 loanMarket;
    uint actualLoanAmount;
    bytes32 currentMarket;
    uint currentAmount;
    STATE state;
  }
  struct CollateralRecords {
    uint256 id;
    bytes32 market;
    bytes32 commitment;
    uint256 amount;
    bool isCollateralisedDeposit;
    uint256 timelockValidity;
    bool isTimelockActivated;  // timelock duration
    uint256 activationTime; // blocknumber when yield withdrawal request was placed.
  }
  struct CollateralYield {
    uint256 id;
    bytes32 market;
    bytes32 commitment;
    uint oldLengthAccruedYield; // length of the APY time array.
    uint oldTime; // last recorded block num
    uint accruedYield; // accruedYield in 
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
  mapping(address => mapping(bytes32 => mapping(bytes32 => DeductibleInterest))) indaccruedInterest;
  mapping(address => mapping(bytes32 => mapping(bytes32 => CollateralYield))) indCollateralisedDepositRecords;
  mapping(address => mapping(bytes32 => mapping(bytes32 => LoanState))) indLoanState;


/// EVENTS
  event NewLoan(address indexed account,bytes32 indexed market,uint256 indexed amount,bytes32 loanCommitment,uint256 timestamp);
  event LoanRepaid(address indexed account, uint256 indexed id,  bytes32 indexed market, uint256 timestamp);
  event AddCollateral(address indexed account, uint256 indexed id,  uint amount, uint256 timestamp);
  event PermissibleWithdrawal(address indexed account, uint256 indexed id,  bytes32 market, uint256 indexed amount, uint256 timestamp);
  event MarketSwapped(address indexed account, uint indexed id, bytes32 marketFrom, bytes32 marketTo, uint timestamp);
  event CollateralReleased(address indexed account, uint indexed amount, bytes32 indexed market, uint timestamp);

  /// Constructor
  constructor() {
    adminLoanAddress = msg.sender;
  }

// External view functions

  function hasLoanAccount(address _account) external returns (bool){
    _hasLoanAccount(_account);
    return true;
  }

  /// NEW LOAN REQUEST

  function loanRequest(bytes32 _lMarket,bytes32 _commitment,uint256 _lAmount,bytes32 _collateralMarket,uint256 _collateralAmount) external nonReentrant() returns(bool success) {

      _preLoanRequestProcess(_lMarket, _commitment, _lAmount, _collateralMarket, _collateralAmount);      
      
      LoanAccount storage loanAccount = loanPassbook[msg.sender];
      LoanRecords storage loan = indLoanRecords[msg.sender][_loanMarket][_commitment];
      LoanState storage loanState = indLoanState[msg.sender][_loanMarket][_commitment];
      CollateralRecords storage collateral = indCollateralRecords[msg.sender][_loanMarket][_commitment];
      CollateralYield storage cYield = indCollateralisedDepositRecords[msg.sender][_loanMarket][_commitment];
      DeductibleInterest storage deductibleInterest = indaccruedInterest[msg.sender][_loanMarket][_commitment];

      require(loan.id == 0, "Active loan");
      
      collateralToken.transfer(address(reserve), _collateralAmount);        
      _ensureLoanAccount(msg.sender,loanAccount);

      // check permissibleCDR.  - If loan request is not permitted, I have to
      //a require();
      
      _processNewLoan(msg.sender,_lMarket,_commitment, _lAmount, collateral_, _collateralAmount);

      emit NewLoan(msg.sender, _lMarket,_lAmount, _commitment, block.timetstamp);
      return success;
  }

/// ADDCOLLATERAL
    // Collateral can be provided in the same denomination as that of existing
    // collateralMarkeor can be any other base market. If the market is different,
    // the market is swapped to collateralMarket & added as the collateral to the
    // active loan.
  function addCollateral(bytes32 _loanMarket, bytes32 _commitment, bytes32 _collateralMarket, bytes32 _collateralAmount) external returns (bool success)  {
    
    LoanAccount storage loanAccount = loanPassbook[msg.sender];
    LoanRecords storage loan = indLoanRecords[msg.sender][_loanMarket][_commitment];
    LoanState storage loanState = indLoanState[msg.sender][_loanMarket][_commitment];
    CollateralRecords storage collateral = indCollateralRecords[msg.sender][_loanMarket][_commitment];
    DeductibleInterest storage deductibleInterest = indaccruedInterest[msg.sender][_loanMarket][_commitment];
    CollateralYield storage cYield = indCollateralisedDepositRecords[msg.sender][_loanMarket][_commitment];

    _preAddCollateralProcess(msg.sender, _loanMarket, _commitment);
    
    markets._connectMarket(_collateralMarket, _collateralAmount, collateralToken);
    collateralToken.transfer(address(reserve), _collateralAmount);

    _addCollateral(loan.id, _loanMarket, _commitment, _collateralMarket, _collateralAmount);
    _accruedInterest(msg.sender, loan.id);

    if (collateral.isCollateralisedDeposit)  {
      _accruedYield(msg.sender, cYield.id);
    }
    
    emit AddCollateral(msg.sender, loan.id, _collateralAmount, block.timestamp);
    return success;
  }

/// Swap loan to a secondary market.
  function swapLoan(bytes32 _loanMarket, bytes32 _commitment, bytes32 _swapMarket) external nonReentrant() returns (bool success)  {
    
    _hasLoanAccount(msg.sender);
    _isMarketSupported(_loanMarket);
    _isMarketSupported(_swapMarket);

    LoanAccount storage loanAccount = loanPassbook[msg.sender];
    LoanRecords storage loan = indLoanRecords[msg.sender][_loanMarket][_commitment];
    LoanState storage loanState = indLoanState[msg.sender][_loanMarket][_commitment];
    DeductibleInterest storage deductibleInterest = indaccruedInterest[msg.sender][_loanMarket][_commitment];

    require (loan.id !=0, "loan does not exist");
    require(loan.isSwapped == false, "Swapped market exists");
    // require(loanState.currentMarket == loanState.loanMarket == loan.market  , "Swapped market exists");

    uint swappedAmount;
    uint num = loan.id - 1;

/// Preswap LiquidationCheck()
    // implement liquidationCheck. i.e. if the swap could lead to a USD price
    // such that the net asset value is less than or equal to LiquidationPrice.
    swappedAmount = liquidator.swap(_loanMarket, _swapMarket, loan.amount);

/// Updating LoanRecord
    loan.isSwapped = true;
    loan.lastUpdate = block.timestamp;
/// Updating LoanState
    loanState.currentMarket = _swapMarket;
    loanState.currentAmount = swappedAmount;

/// Updating LoanAccount
    loanAccount.loan[num].isSwapped = true;
    loanAccount.loan[num].lastUpdate = block.timestamp;
    loanAccount.loanState[num].currentMarket = _swapMarket;
    loanAccount.loanState[num].currentAmount = swappedAmount;

    _accruedInterest(msg.sender, loan.id);
    _accruedYield(msg.sender, loan.id);

    emit MarketSwapped(msg.sender, loan.id, _loanMarket, _swapMarket, block.timestamp);
    return success;
  }


  /// SwapToLoan 
  function swapToLoan(bytes32 _loanMarket, bytes32 _commitment, bytes32 _swapMarket) external nonReentrant() returns (bool success)  {

    _hasLoanAccount(msg.sender);
    _isMarketSupported(_loanMarket);
    _isMarketSupported(_swapMarket);

    LoanAccount storage loanAccount = loanPassbook[msg.sender];
    LoanRecords storage loan = indLoanRecords[msg.sender][_loanMarket][_commitment];
    LoanState storage loanState = indLoanState[msg.sender][_loanMarket][_commitment];
    DeductibleInterest storage deductibleInterest = indaccruedInterest[msg.sender][_loanMarket][_commitment];

    require(loan.id !=0, "loan does not exist");
    require(loan.isSwapped == true, "Swapped market does not exist");

    uint swappedAmount;
    uint num = loan.id - 1;

/// Preswap LiquidationCheck()
    // implement liquidationCheck. i.e. if the swap could lead to a USD price
    // such that the net asset value is less than or equal to LiquidationPrice.
    swappedAmount = liquidator.swap(_swapMarket, _loanMarket, loanState.currentAmount);

/// Updating LoanRecord
    loan.isSwapped = false;
    loan.lastUpdate = block.timestamp;

/// updating the LoanState
    loanState.currentMarket = _loanMarket;
    loanState.currentAmount = swappedAmount;

/// Updating LoanAccount
    loanAccount.loan[num].isSwapped = false;
    loanAccount.loan[num].lastUpdate = block.timestamp;
    loanAccount.loanState[num].currentMarket = _loanMarket;
    loanAccount.loanState[num].currentAmount = swappedAmount;

    _accruedInterest(msg.sender, loan.id);
    _accruedYield(msg.sender, loan.id);

    emit MarketSwapped(msg.sender, loan.id, _swapMarket, _loanMarket, block.timestamp);
    return success;
  }

  function repayLoan(bytes32 _loanMarket, bytes32 _commitment ,  uint _repayAmount) external returns (bool success)  {

    require(indLoanRecords[msg.sender][_loanMarket][_commitment].id !=0, "Loan does not exist");

    LoanAccount storage loanAccount = loanPassbook[msg.sender];
    LoanRecords storage loan = indLoanRecords[msg.sender][_loanMarket][_commitment];
    LoanState storage loanState = indLoanState[msg.sender][_loanMarket][_commitment];
    CollateralRecords storage collateral = indCollateralRecords[msg.sender][_loanMarket][_commitment];
    DeductibleInterest storage deductibleInterest = indaccruedInterest[msg.sender][_loanMarket][_commitment];
    CollateralYield storage cYield = indCollateralisedDepositRecords[msg.sender][_loanMarket][_commitment];

    _accruedInterest(msg.sender, loan.id);
    _accruedYield(msg.sender, loan.id);

    if (_repayAmount == 0)  {
      // converting the current market into loanMarket for repayment.
      if (loanState.currentMarket == _loanMarket) {
        _repayAmount = loanState.currentAmount;
        _repaymentLogic(msg.sender, loanAccount, loan, loanState,collateral,deductibleInterest, cYield);
      
      } else if(loanState.currentMarket != _loanMarket) {
        _repayAmount = liquidator.swap(loanState.currentMarket, _loanMarket, loanState.currentAmount);
        _repaymentLogic(msg.sender, loanAccount, loan, loanState,collateral,deductibleInterest, cYield);
        }
    } else if (_repayAmount > 0) {
      
      markets._connectMarket(_loanMarket, _repayAmount, loanToken);
      loanToken.transfer(msg.sender, address(reserve), _repayAmount);

      if (_repayAmount > loan.amount) {
        uint _remnantAmount = _repayAmount - loan.amount;
        collateral.amount +=  cYield.accruedYield - deductibleInterest.accruedInterest;
        
        loan.amount = 0;
        loan.isSwapped = false;
        loan.lastUpdate = block.timestamp;

        if (loanState.currentMarket == _loanMarket) {
          loanToken.transfer(address(reserve), msg.sender, loanState.currentAmount+_remnantAmount);
          
        } else if (loanState.currentMarket != _loanMarket)  {
          uint amount = liquidator.swap(loanState.currentMarket, _loanMarket, loanState.currentAmount);
          
          loan.currentMarket = _loanMarket;
          loan.currentAmount = amount;

          loanToken.transfer(address(reserve), msg.sender, loanState.currentAmount+_remnantAmount);
        }

        delete cYield;
        delete deductibleInterest;
        delete loanAccount.accruedInterest[loan.id-1];
        delete loanAccount.accruedYield[loan.id-1];

        emit LoanRepaid(msg.sender, loan.id, loan.market, block.timestamp);

        if (_commitment == comptroller.commitment[2]) {
    /// updating LoanRecords
          loan.amount = 0;
          loan.isSwapped = false;
          loan.lastUpdate = block.timestamp;
    /// updating LoanState
          loanState.actualLoanAmount = 0;
          Loanstate.currentAmount = 0;
          loanState.state = STATE.REPAID;
    /// updating CollateralRecords
          collateral.isCollateralisedDeposit = false;
          collateral.isTimelockActivated = true;
          collateral.activationTime = block.timestamp;
        
        } else if (_commitment == comptroller.commitment[0]) {
    /// transfer collateral.amount from reserve contract to the msg.sender
          markets._connectMarket(collateral.market, collateral.amount, collateralToken);
          reserve.transferAnyBEP20(collateralToken, msg.sender, collateral.amount);

          uint num = loan.id - 1;
    /// delete loan Entries, loanRecord, loanstate, collateralrecords
          delete loanState;
          delete loan;
          delete collateral;

          delete loanAccount.loanState[num];
          delete loanAccount.loans[num];
          delete loanAccount.collaterals[num];

          emit CollateralReleased(account, collateral.amount, collateral.market, block.timestamp);
        }
      } else if (_repayAmount < loan.amount){
        // loan.amount -= _repayAmount;
        // loanState.actualLoanAmount = loan.amount;
        uint _remnantDue = loan.amount - _repayAmount;
        
        collateral.amount +=  cYield.accruedYield - deductibleInterest.accruedInterest;
        liquidator.swap(collateral.market, loan.market, collateral.amount);
        
        loan.amount = 0;
        loan.isSwapped = false;
        loan.lastUpdate = block.timestamp;

        if (loanState.currentMarket == _loanMarket) {
          loanToken.transfer(address(reserve), msg.sender, loanState.currentAmount+_remnantAmount);
          
        } else if (loanState.currentMarket != _loanMarket)  {
          uint amount = liquidator.swap(loanState.currentMarket, _loanMarket, loanState.currentAmount);
          
          loan.currentMarket = _loanMarket;
          loan.currentAmount = amount;

          loanToken.transfer(address(reserve), msg.sender, loanState.currentAmount+_remnantAmount);
        }

      }
    }
    return success;
  }

  function _hasLoanAccount(address _account) internal  {
    require(loanPassbook[account].accOpenTime!=0, "Loan _account does not exist");
  }

  function _updateDeductibleInterest(address _account, uint loanID) internal {
    if (collateral.commitment == comptroller.commitment[2]) {
      _accruedYield(account, cYield.id);
    }
  }

  function _accruedYield(address _account, uint collateralID_) internal {    
  }

   function _addCollateral(uint id, bytes32 _loanMarket, bytes32 _loanCommitment, bytes32 _collateralMarket, bytes32 _collateralAmount ) internal {
     
    collateral.amount += _collateralAmount;
    loanAccount.collaterals[loan.id-1].amount = collateral.amount;

    return this;
  }

  /// Calculating deductible Interest
  function _accruedInterest(address _account, uint loanId) internal{
    require(LoanState.state == STATE.ACTIVE, "Loan is inactive");
    require(DeductibleInterest.loanId !=0, "APR not applicable");

    uint256 aggregateYield;
    uint availableCollateral;
    uint loanValue;
    uint collateralUSDPrice;
    uint deductibleUSDValue;
    uint oldLengthAccruedInterest;
    uint oldTime;
    uint num = loanId - 1;

    LoanAccount storage loanAccount = loanPassbook[msg.sender];
    LoanRecords storage loan = indLoanRecords[msg.sender][_loanMarket][_commitment];
    LoanState storage loanState = indLoanState[msg.sender][_loanMarket][_commitment];
    CollateralRecords storage collateral = indCollateralRecords[msg.sender][_loanMarket][_commitment];
    DeductibleInterest storage deductibleInterest = indaccruedInterest[msg.sender][_loanMarket][_commitment];
    
    comptroller._calcAPR(_account, loan.commitment,deductibleInterest.oldLengthAccruedInterest, deductibleInterest.oldTime, aggregateInterest);
    
    /// finding the deductible sum.
    loanValue = (loan.amount)*oracle.getLatestPrice(_loanMarket);
    collateralUSDPrice = oracle.getLatestPrice(collateral.market);
    
    deductibleUSDValue = loanValue*aggregateYield;
    deductibleInterest.accruedInterest += deductibleUSDValue/collateralUSDPrice;
    deductibleInterest.oldLengthAccruedInterest = oldLengthAccruedInterest;
    deductibleInterest.oldTime = oldTime;

    // availableCollateral = collateral.amount -
    // deductibleInterest.accruedInterest;
    
    loanAccount.accruedInterest[num].accruedInterest = deductibleInterest.accruedInterest;
    loanAccount.accruedInterest[num].oldLengthAccruedInterest = oldLengthAccruedInterest;
    loanAccount.accruedInterest[num].oldTime = oldTime; 

    return this;
  }



  function permissibleWithdrawal() external returns (bool) {}

  function _permissibleWithdrawal() internal returns (bool) {}

  // function switchLoanType(CONSIDER from, CONSIDER to) external nonReentrant() returns (bool success){
//  this feature is kept on hold as a lower priority task.
  // }
  
  function _calcCdr() internal {} // performs a cdr check internally

  function _repaymentLogic(address account, LoanAccount storage loanAccount,LoanRecords storage loan,LoanState storage loanState,CollateralRecords storage collateral,DeductibleInterest storage deductibleInterest,CollateralYield storage cYield ) internal  {

    uint collateralAmount = collateral.amount - deductibleInterest.accruedInterest + cYield.accruedYield;
    _repayAmount += liquidator.swap(collateral.market, loan.market, collateralAmount);

    uint _remnantAmount = _repayAmount - loan.amount;
    collateral.amount = liquidator.swap(loan.market, collateral.market, _remnantAmount);
    
    delete cYield;
    delete deductibleInterest;
    delete loanAccount.accruedInterest[loan.id-1];
    delete loanAccount.accruedYield[loan.id-1];

    emit LoanRepaid(msg.sender, loan.id, loan.market, block.timestamp);

    if (_commitment == comptroller.commitment[2]) {
/// updating LoanRecords
      loan.amount = 0;
      loan.isSwapped = false;
      loan.lastUpdate = block.timestamp;
/// updating LoanState
      loanState.actualLoanAmount = 0;
      Loanstate.currentAmount = 0;
      loanState.state = STATE.REPAID;
/// updating CollateralRecords
      collateral.isCollateralisedDeposit = false;
      collateral.isTimelockActivated = true;
      collateral.activationTime = block.timestamp;
    
    } else if (_commitment == comptroller.commitment[0]) {
/// transfer collateral.amount from reserve contract to the msg.sender
      markets._connectMarket(collateral.market, collateral.amount, collateralToken);
      reserve.transferAnyBEP20(collateralToken, account, collateral.amount);

      uint num = loan.id - 1;
/// delete loan Entries, loanRecord, loanstate, collateralrecords
      delete loanState;
      delete loan;
      delete collateral;

      delete loanAccount.loanState[num];
      delete loanAccount.loans[num];
      delete loanAccount.collaterals[num];

      emit CollateralReleased(account, collateral.amount, collateral.market, block.timestamp);
    }
    return this;
  }
  function _isMarketSupported(bytes32 _market) internal {
    require(markets.tokenSupportCheck[_market] != false, "Unsupported market");
  }
 
  function liquidation(
    bytes32 _lMarket,
    bytes32 _commitment,
    bytes32 amount_
  ) external nonReentrant returns (bool) {
    //   calls the liqudiate function in the liquidator contract.
  }

  function _preLoanRequestProcess(bytes32 _lMarket,
    bytes32 _commitment,
    uint256 _lAmount,
    bytes32 _collateralMarket,
    uint256 _collateralAmount) internal {
    require(_lAmount !=0 && _collateralAmount!=0, "Loan or collateral cannot be zero");

    _isMarketSupported(_lMarket);
    _isMarketSupported(_collateralMarket);

    markets._connectMarket(_lMarket, _lAmount, loanToken);
    markets._connectMarket(_collateralMarket, _collateralAmount, collateralToken);
    _cdrCheck(_lAmount, _collateralAmount);
  }


    function _processNewLoan(address _account, bytes32 _lMarket,
      bytes32 _commitment,
      uint256 _lAmount,
      bytes32 _collateralMarket,
      uint256 _collateralAmount) internal {

      // comptroller.commitment[] loans == TWOWEEKMCP, ONEMONTHCOMMITMENT.
      uint id;

      if (loanAccount.loans.length == 0)   {
          id = 1;
      } else if (loanAccount.loans.length != 0)    {
          id = loanAccount.loans.length + 1;
      }

      if (_commitment == comptroller.commitment[0]) {
          loan = LoanRecords({
            id:id,
            amount:_lAmount,
            market: _lMarket,
            commitment: _commitment,
            isSwapped: false,
            lastUpdate: block.timestamp
          });

        collateral = CollateralRecords({
          id:id,
          market:_collateralMarket,
          commitment: _commitment,
          amount: _collateralAmount,
          isCollateralisedDeposit: false,
          timelockValidity: 0,
          isTimelockActivated: true,
          activationTime: 0
        });

        deductibleInterest = DeductibleInterest({
          id:id,
          market: _collateralMarket,
          oldLengthAccruedInterest: apr.time.length,
          oldTime:block.timestamp,
          accruedInterest: 0
        });

        loanState = LoanState({
          id:id,
          loanMarket: _lMarket,
          actualLoanAmount: _lAmount,
          currentMarket: _lMarket,
          currentAmount: _lAmount,
          state: STATE.ACTIVE
        });

        loanAccount.loans.push(loan);
        loanAccount.collaterals.push(collateral);
        loanAccount.accruedInterest.push(deductibleInterest);
        loanAccount.loanState.push(loanState);
        // loanAccount.accruedYield.push(accruedYield); - no yield because it is
        // a flexible loan
      }
      else if (comptroller.commitment[2]) {
        /// Here the commitment is for ONEMONTH. But Yield is for TWOWEEKMCP
        loan = LoanRecords({
          id:id,
          amount:_lAmount,
          market: _lMarket,
          commitment: _commitment,
          isSwapped: false,
          lastUpdate: block.timestamp
        });

        collateral = CollateralRecords({
          id:id,
          market:_collateralMarket,
          commitment: _commitment,
          amount: _collateralAmount,
          isCollateralisedDeposit: true,
          timelockValidity: 86400, // convert this into block.timestamp
          isTimelockActivated: false,
          activationTime: 0
        });

        cYield = CollateralYield({
          id:id,
          market:_collateralMarket,
          commitment: comptroller.commitment[1],
          oldLengthAccruedYield: apy.time.length,
          oldTime: block.timestamp,
          accruedYield: 0
        });

        deductibleInterest = DeductibleInterest({
          id:id,
          market: _collateralMarket,
          oldLengthAccruedInterest: apr.time.length,
          oldTime:block.timestamp,
          accruedInterest: 0
        });

        loanState = LoanState({
          id:id,
          loanMarket: _lMarket,
          actualLoanAmount: _lAmount,
          currentMarket: _lMarket,
          currentAmount: _lAmount,
          state: STATE.ACTIVE
        });

        loanAccount.loans.push(loan);
        loanAccount.collaterals.push(collateral);
        loanAccount.accruedYield.push(cYield);
        loanAccount.accruedInterest.push(deductibleInterest);
        loanAccount.loanState.push(loanState);
      }
      return this;
    }

  function _preAddCollateralProcess(address _account,bytes32 _loanMarket, bytes32 _commitment) internal {
    _isMarketSupported(_loanMarket);

    require(loanAccount.accOpenTime !=0, "Loan _account does not exist");
    require(loan.id !=0, "Loan record does not exist");
    require(loanState.state == STATE.ACTIVE, "Inactive loan");

    return this;
  }

  function _ensureLoanAccount(address _account, LoanAccount storage loanAccount) internal {
    if(loanAccount.accOpenTime == 0)  {
      loanAccount.accOpenTime = block.timestamp;
      loanAccount.account = _account;
    }
    return this;
  }

  function _cdrCheck(bytes32 _loanMarket, bytes32 _collateralMarket, uint _lAmount, uint _collateralAmount) internal {
    //  check if the 

    oracle.getLatestPrice(_loanMarket);
    oracle.getLatestPrice(_collateralMarket);

  }

  modifier nonReentrant() {
    require(isReentrant == false, "Re-entrant alert!");
    isReentrant = true;
    _;
    isReentrant = false;
  }

  modifier authLoan() {
    require(
      msg.sender == adminLoanAddress,
      "Only an admin can call this function"
    );
    _;
  }
}