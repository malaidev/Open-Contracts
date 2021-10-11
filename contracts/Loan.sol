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
    SwapRecord[] swapMarkets;
    CollateralYield[] accruedYield;
    LoanState[] loanState;
  }
  struct LoanRecords {
    uint256 id;
    uint256 amount;
    bytes32 market;
    bytes32 commitment;
    bool isSwapped; //true or false. Update when a loan is swapped
    uint256 lastUpdate;
  }

  struct LoanState  {
    uint id;
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
    uint256 activationBlock; // blocknumber when yield withdrawal request was placed.
  }
  struct CollateralYield {
    uint256 id;
    bytes32 market;
    bytes32 commitment;
    uint256 amount;
    uint oldLengthAccruedYield; // length of the APY blockNumbers array.
    uint oldBlockNum; // last recorded block num
    uint accruedYield; // accruedYield in 
    // cross-check if the below can be deleted.
    bool isTimelockActivated; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
    uint timelockValidity; // timelock duration
    uint releaseAfter; // block.number(isTimelockActivated) + timelockValidity.
    //  till here
  }
  // DeductibleInterest{} stores the amount_ of interest deducted.
  struct DeductibleInterest {
    uint256 id; // Id of the loan the interest is being deducted for.
    bytes32 market; // market_ this yield is calculated for
    uint256 oldLengthAccruedInterest; // length of the APY blockNumbers array.
    uint256 oldBlockNum; // length of the APY blockNumbers array.
    uint256 accruedInterest;
    // cross-check if the below can be deleted.
    bool isTimelockApplicable; // accruedYield in
    bool isTimelockActivated; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
    uint256 timelockValidity; // timelock duration
    uint256 timelockActivationBlock; // blocknumber when yield withdrawal request was placed.
    //  till here
  }

// cross-check if the below can be deleted.
  struct SwapRecord {
    uint id; // same as LoanId
    bytes32 loanMarket;
    bytes32 swapMarket;
    uint amount;
  }
//  till here

  mapping(address => LoanAccount) loanPassbook;
  mapping(address => mapping(bytes32 => mapping(bytes32 => LoanRecords))) indLoanRecords;
  mapping(address => mapping(bytes32 => mapping(bytes32 => CollateralRecords))) indCollateralRecords;
  mapping(address => mapping(bytes32 => mapping(bytes32 => DeductibleInterest))) indaccruedInterest;
  mapping(address => mapping(bytes32 => mapping(bytes32 => CollateralYield))) indCollateralisedDepositRecords;
  mapping(address => mapping(bytes32 => mapping(bytes32 => LoanState))) indLoanState;
  mapping(address => mapping(bytes32 => mapping(bytes32 => SwapMarket))) indSwapRecords;

  event NewLoan(address indexed account,bytes32 indexed market,uint256 indexed amount,bytes32 loanCommitment,uint256 timestamp);
  event LoanRepaid(address indexed account, uint256 indexed id,  bytes32 indexed market, uint256 timestamp);
  event AddCollateral(address indexed account, uint256 indexed id,  uint amount, uint256 timestamp);
  event WithdrawLoan(address indexed account, uint256 indexed id,  bytes32 market, uint256 indexed amount, uint256 timestamp);
  event SwappedMarket(address indexed account, uint indexed id, bytes32 marketFrom, bytes32 marketTo, uint timestamp);
  event CollateralReleased(address indexed account, uint indexed amount, bytes32 indexed market, uint timestamp);

  constructor() {
    adminLoanAddress = msg.sender;
  }

  function loanRequest(bytes32 market_,bytes32 commitment_,uint256 loanAmount_,bytes32 collateralMarket_,uint256 collateralAmount_) external nonReentrant() returns(bool success) {

      _preLoanRequestProcess(market_, commitment_, loanAmount_, collateralMarket_, collateralAmount_);      
      LoanAccount storage loanAccount = loanPassbook[msg.sender];
      LoanRecords storage loan = indLoanRecords[msg.sender][market_][commitment_];
      CollateralRecords storage collateral = indCollateralRecords[msg.sender][market_][commitment_];
      DeductibleInterest storage deductibleInterest = indaccruedInterest[msg.sender][market_][commitment_];
      CollateralYield storage cYield = indCollateralisedDepositRecords[msg.sender][market_][commitment_];
      APR storage apr = comptroller.indAPRRecords[commitment_];

      collateralToken.transfer(address(reserve), collateralAmount_);      
      _ensureLoanAccount(msg.sender);
      
      require(loan.id == 0 && loan.amount == 0, "Add on loans on the same market is not permitted");
      _processNewLoan(msg.sender,market_,commitment_, loanAmount_, collateral_, collateralAmount_);
      loanToken.transfer(address(reserve), msg.sender, loanAmount_); //shouldn't happen no?
      
      emit NewLoan(msg.sender, market_,loanAmount_, commitment_, block.timetstamp);
      return success;
      // Process the loan & update the records.
  }


  function addCollateral(bytes32 loanMarket_, bytes32 loanCommitment_, bytes32 collateralMarket_, bytes32 collateralAmount_) external returns (bool success)  {
    LoanAccount storage loanAccount = loanPassbook[msg.sender];
    LoanRecords storage loan = indLoanRecords[msg.sender][loanMarket_][loanCommitment_];
    CollateralRecords storage collateral = indCollateralRecords[msg.sender][loanMarket_][loanCommitment_];
    DeductibleInterest storage deductibleInterest = indaccruedInterest[msg.sender][loanMarket_][loanCommitment_];
    CollateralYield storage cYield = indCollateralisedDepositRecords[msg.sender][loanMarket_][loanCommitment_];
    APR storage apr = comptroller.indAPRRecords[loanCommitment_];

    _preAddCollateralProcess(msg.sender, loanMarket_, loanCommitment_);

    _updateDeductibleInterest(msg.sender, loan.id);
    if (collateral.isCollateralisedDeposit)  {
      _updateCollateralYield(msg.sender, cYield.id);
    }
    
    markets._connectMarket(collateralMarket_, collateralAmount_, collateralToken);
    collateralToken.transfer(address(reserve), collateralAmount_);

    _addCollateral(loan.id, loanMarket_, loanCommitment_, collateralMarket_, collateralAmount_);
    
    emit AddCollateral(msg.sender, loan.id, collateralAmount_, block.timestamp);

    return success;
  }
  // function _cdrCheck(uint loanAmount_, uint collateralAmount_) internal {
    // fetch the usd price of the loanAmount_, and collateralAmount.
    //   check if the collateral amount / loanAmount_ is within the permissible
    //   CDR. Permissible cdr is a determinant of reserveFactor. RF =
    //   (totalDeposits) - activeLoans.
  }

  // function _connectMarkets(bytes32 market_, uint256 loanAmount_, bytes32 collateralMarket_, uint256 collateralAmount_) internal {
	// 	MarketData storage marketData = markets.indMarketData[market_];
	// 	marketAddress = marketData.tokenAddress;
	// 	token = IBEP20(marketAddress);
	// 	amount_ *= marketData.decimals;
	// }

  function _cdrCheck(bytes32 loanMarket_, bytes32 collateralMarket_, uint loanAmount_, uint collateralAmount_) internal {
    //  check if the 

    oracle.getLatestPrice(loanMarket_);
    oracle.getLatestPrice(collateralMarket_);

  }


    function _processNewLoan(address account_, bytes32 market_,
      bytes32 commitment_,
      uint256 loanAmount_,
      bytes32 collateralMarket_,
      uint256 collateralAmount_) internal {

      // calculateAPR on comptrollerContract itself. It is safest that way.  
      // _checkActiveLoan(bytes) - checks if there is any outstandng loan for
      // the market with the same commmitment type. If yes, no need to add id.
      // If no, then the below id mechanism will come handy.
      // creating a commonID;


      // Fixed loans == TWOWEEKMCP, ONEMONTHCOMMITMENT.
      uint id;

      if (loanAccount.loans.length == 0)   {
          id = 1;
      } else if (loanAccount.loans.length != 0)    {
          id = loanAccount.loans.length + 1;
      }

      if (commitment_ == comptroller.commitment[0]) {
          loan = LoanRecords({
            id:id,
            amount: block.number,
            market: market_,
            commitment: commitment_,
            isSwapped: false,
            loanAmount:loanAmount_,
            lastUpdate: block.number
          });

        collateral = CollateralRecords({
          id:id,
          market:collateralMarket_,
          commitment: commitment_,
          amount: collateralAmount_,
          isCollateralisedDeposit: false,
          timelockValidity: 0,
          isTimelockActivated: true,
          activationBlock: 0
          });

        deductibleInterest = DeductibleInterest({
          id:id,
          market: collateralMarket_,
          oldLengthAccruedInterest: apr.blockNumbers.length,
          oldBlockNum:block.number,
          accruedInterest: 0,
          isTimelockApplicable: false,
          isTimelockActivated: true,
          timelockValidity: 0,
          timelockActivationBlock: block.number
          });

        loanAccount.loans.push(loan);
        loanAccount.collaterals.push(collateral);
        loanAccount.accruedInterest.push(deductibleInterest);
        loanAccount.accruedYield.push(0);
      }
      else if (comptroller.commitment[2]) {
        /// Here the commitment is for ONEMONTH. But Yield is for TWOWEEKMCP
        loan = LoanRecords({
          id:id,
          amount: block.number,
          market: market_,
          commitment: commitment_,
          isSwapped: false,
          loanAmount:loanAmount_,
          lastUpdate: block.number
        });

        collateral = CollateralRecords({
          id:id,
          market:collateralMarket_,
          commitment: commitment_,
          amount: collateralAmount_,
          isCollateralisedDeposit: true,
          timelockValidity: 86400,
          isTimelockActivated: false,
          activationBlock: 0
        });

        deductibleInterest = DeductibleInterest({
          id:id,
          market: collateralMarket_,
          oldLengthAccruedInterest: apr.blockNumbers.length,
          oldBlockNum:block.number,
          accruedInterest: 0,
          isTimelockActivated: false,
          timelockValidity: 86400,
          timelockActivationBlock: 0
        });

        cYield = CollateralYield({
          id:id,
          market:collateralMarket_,
          commitment: comptroller.commitment[1],
          amount: collateralAmount_,
          isCollateralisedDeposit: true,
          timelockValidity: 86400,
          isTimelockActivated:false,
          activationBlock:0             
        });

        loanAccount.loans.push(loan);
        loanAccount.collaterals.push(collateral);
        loanAccount.accruedInterest.push(deductibleInterest);
        loanAccount.accruedYield.push(cYield);
      }
      return this;
    }


  function _hasLoanAccount(address account_) internal  {
    require(loanPassbook[account_].accOpenTime!=0, "Loan account does not exist");
  }


  function _ensureLoanAccount(address account_) internal {
		if (loanAccount.accOpenTime == 0) {
			loanAccount.accOpenTime = block.timestamp;
			loanAccount.account = account_;
		}
    return this;
	}


  function _preAddCollateralProcess(address account_,bytes32 loanMarket_, bytes32 loanCommitment_) internal {
    _isMarketSupported(loanMarket_);

    require(loanAccount.accOpenTime !=0, "Loan account does not exist");
    require(loan.id !=0, "Loan record does not exist");
    // Ensuring the contract is interacting with the appropriate struct.
    require(loanMarket_ == loan.market,"Something is wrong. Loan market Mismatch" );
    require(loanCommitment_ == loan.commitment,"Something is wrong. Loan market Mismatch" );
    require(collateralMarket_ == collateral.market,"Something is wrong. Loan market Mismatch" );
    
    require(loan.id == collateral.id == deductibleInterest.id,"Something is wrong" );
    require(loanAccount.collaterals[id-1].id == collateral.id, "Collateral does not match");
    
    return this;
  }



  function _updateDeductibleInterest(address account_, uint loanID) internal {
    if (collateral.commitment == comptroller.commitment[2]) {
      _updateCollateralYield(account_, cYield.id);
    }
  }

  function _updateCollateralYield(address account_, uint collateralID_) internal {
    
  }

   function _addCollateral(uint id, bytes32 loanMarket_, bytes32 loanCommitment_, bytes32 collateralMarket_, bytes32 collateralAmount_ ) internal {
      
    require(collateral.id == loan.id && collateral.id == deductibleInterest.id, "crosscheck once");
    
    collateral.amount += collateralAmount_;
    loanAccount.collaterals[loan.id-1].amount = collateral.amount;

    return this;
  }


/// Swap loan to a secondary market.

  function swapLoan(bytes32 loanMarket_, bytes32 commitment_, bytes32 swapMarket_) external nonReentrant() returns (bool success)  {
    
    _hasLoanAccount(msg.sender);
    _isMarketSupported(loanMarket_);
    _isMarketSupported(swapMarket_);

    LoanAccount storage loanAccount = loanPassbook[msg.sender];
    LoanRecords storage loan = indLoanRecords[msg.sender][loanMarket_][commitment_];
    LoanState storage loanState = indLoanState[msg.sender][loanMarket_][commitment_];
    DeductibleInterest storage deductibleInterest = indaccruedInterest[msg.sender][loanMarket_][commitment_];
    SwapRecord storage swap = indSwapRecords[msg.sender][loanMarket_][commitment_];

    require (loan.id !=0, "loan does not exist");
    require(loan.isSwapped == false, "Swapped market exists");

    uint swappedAmount;
    uint num = loan.id - 1;

    ///  ensuring there is no duplicate Loanstate structs
    delete loanState;
    delete swap;
    delete loanAccount.loanState[num];
    delete loanAccount.swapMarkets[num];

/// Preswap LiquidationCheck()
    // implement liquidationCheck. i.e. if the swap could lead to a USD price
    // such that the net asset value is less than or equal to LiquidationPrice.
    swappedAmount = liquidator.swap(loanMarket_, swapMarket_, loan.amount);

/// Updating SwapRecord
    swap = SwapRecord({
      id:loan.id,
      loanMarket: loanMarket_,
      swapMarket: swapMarket_,
      amount: swappedAmount
    });

/// Updating LoanRecord
    loan.isSwapped = true;
    loan.lastUpdate = block.timestamp;

/// Updating LoanState
    loanState = LoanState({id:loan.id, loanMarket:loanMarket_, actualLoanAmount:loan.amount,currentMarket:swapMarket_, currentAmount:swap.amount});

/// Updating LoanAccount
    loanAccount.swapMarkets[num] = swap;
    loanAccount.loan[num].isSwapped = true;
    loanAccount.loan[num].lastUpdate = block.timestamp;
    loanAccount.loanState[num] = loanState;

    emit SwappedMarket(msg.sender, loan.id, loanMarket_, swapMarket_, block.timestamp);
    return success;
  }


  /// SwapToLoan 

  function swapToLoan(bytes32 loanMarket_, bytes32 commitment_, bytes32 swapMarket_) external nonReentrant() returns (bool success)  {
    
    _hasLoanAccount(msg.sender);
    _isMarketSupported(loanMarket_);
    _isMarketSupported(swapMarket_);

    LoanAccount storage loanAccount = loanPassbook[msg.sender];
    LoanRecords storage loan = indLoanRecords[msg.sender][loanMarket_][commitment_];
    LoanState storage loanState = indLoanState[msg.sender][loanMarket_][commitment_];
    DeductibleInterest storage deductibleInterest = indaccruedInterest[msg.sender][loanMarket_][commitment_];
    SwapRecord storage swap = indSwapRecords[msg.sender][loanMarket_][commitment_];

    require(loan.id !=0, "loan does not exist");
    require(loan.isSwapped == true, "Swapped market exists");
    require(swap.swapMarket == swapMarket_, "From market is different than the actual");
    require(swap.loanMarket == loanMarket_, "loan market is different than the actual");

    uint swappedAmount;
    uint num = loan.id - 1;

/// Preswap LiquidationCheck()
    // implement liquidationCheck. i.e. if the swap could lead to a USD price
    // such that the net asset value is less than or equal to LiquidationPrice.
    swappedAmount = liquidator.swap(swapMarket_, loanMarket_, swap.amount);

/// Updating LoanRecord
    loan.amount = swappedAmount;
    loan.isSwapped = false;
    loan.lastUpdate = block.timestamp;

/// updating the LoanState
    loanState.currentMarket = loanMarket_;
    loanState.currentAmount = swappedAmount;
  
  ///  Deleting the swapMarket Record
    delete swap;
    delete loanAccount.swapMarkets[num];

/// Updating LoanAccount
    loanAccount.swapMarkets[num] = swap;
    loanAccount.loan[num].amount = swappedAmount;
    loanAccount.loan[num].isSwapped = false;
    loanAccount.loan[num].lastUpdate = block.timestamp;
    
    loanAccount.loanState[num].currentMarket = loanMarket_;
    loanAccount.loanState[num].currentAmount = swappedAmount;

    emit SwappedMarket(msg.sender, loan.id, swapMarket_, loanMarket_, block.timestamp);
    return success;
  }


  function permissibleWithdrawal() external returns (bool) {}

  function _permissibleWithdrawal() internal returns (bool) {}

  // function switchLoanType(CONSIDER from, CONSIDER to) external nonReentrant() returns (bool success){
//  this feature is kept on hold as a lower priority task.
  // }
  
  function _calcCdr() internal {} // performs a cdr check internally


  function repayLoan(bytes32 loanMarket_, bytes32 commitment_ ,  uint repayAmount_) external returns (bool success)  {

    require(indLoanRecords[msg.sender][loanMarket_][commitment_].id !=0, "Loan does not exist");

    LoanAccount storage loanAccount = loanPassbook[msg.sender];
    LoanRecords storage loan = indLoanRecords[msg.sender][loanMarket_][commitment_];
    LoanState storage loanState = indLoanState[msg.sender][loanMarket_][commitment_];
    CollateralRecords storage collateral = indCollateralRecords[msg.sender][loanMarket_][commitment_];
    DeductibleInterest storage deductibleInterest = indaccruedInterest[msg.sender][loanMarket_][commitment_];
    CollateralYield storage cYield = indCollateralisedDepositRecords[msg.sender][loanMarket_][commitment_];
    APR storage apr = comptroller.indAPRRecords[commitment_];

    _updateDeductibleInterest(msg.sender, loan.id);
    _updateCollateralYield(msg.sender, cYield.id);

    if (repayAmount_ == 0)  {
      // converting the current market into loanMarket for repayment.
      if (loanState.currentMarket == loanMarket_) {
        repayAmount_ = loanState.currentAmount;
        _repaymentLogic();
      
      } else if(loanState.currentMarket != loanMarket_) {
        repayAmount_ = liquidator.swap(loanState.currentMarket, loanMarket_, loanState.currentAmount);
        _repaymentLogic();
        }
    } else if (repayAmount_ > 0) {
      
      markets._connectMarket(loanMarket_, repayAmount_, loanToken);
      loanToken.transfer(msg.sender, address(reserve), repayAmount_);

      if (repayAmount_ > loan.amount) {
        uint remnantAmount_ = repayAmount_ - loan.amount;
        
        loan.amount = 0;
        loan.isSwapped = false;
        loan.lastUpdate = block.timestamp;

        if (loanState.currentMarket == loanMarket_) {
          loanToken.transfer(address(reserve), msg.sender, loanState.currentAmount+remnantAmount_);
        } else if (loanState.currentMarket != loanMarket_)  {
          liquidator.swap(loanState.currentMarket, loanMarket_, loanState.currentAmount);
          loanToken.transfer(address(reserve), msg.sender, loanState.currentAmount+remnantAmount_);
        }
        
        loanToken.transfer(address(reserve), msg.sender, remnantAmount_);

        // repayLoan
        // if loanState.curremtMarket != loan.market, swap it o loanMarket
        //  transfer remnant amount(repayAmount + swapped amount) to msg.sender
        // activate collateralwithdrawal
        // delete cYield, deductible Interest, etc.

      } else {
        loan.amount -= repayAmount_;
        loanState.actualLoanAmount = loan.amount;

      }
      
    }
    return success;
  }


  function _repaymentLogic() internal  {

    uint collateralAvailable = collateral.amount - deductibleInterest.accruedInterest + cYield.amount;
    repayAmount_ += liquidator.swap(collateral.market, loanMarket_, collateralAvailable);

    uint remnantAmount_ = repayAmount_ - loanState.actualLoanAmount;
    collateral.amount = liquidator.swap(loanMarket_, collateral.market, remnantAmount_);
    
    delete cYield;
    delete deductibleInterest;
    delete loanAccount.accruedInterest[loan.id-1];
    delete loanAccount.accruedYield[loan.id-1];

    emit LoanRepaid(msg.sender, loan.id, loanMarket_, block.timestamp);

    if (commitment_ == FIXED) {
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
      collateral.activationBlock = block.number;
    
    } else if (commitment_ == FLEXIBLE) {
/// transfer collateral.amount from reserve contract to the msg.sender
      markets._connectMarket(collateral.market, collateral.amount, collateralToken);
      reserve.transferToken(collateralToken, msg.sender, collateral.amount);

      uint num = loan.id - 1;
/// delete loan Entries, loanRecord, loanstate, collateralrecords
      delete collateral;
      delete loanState;
      delete loan;
      delete loanAccount.collaterals[num];
      delete loanAccount.loanState[num];
      delete loanAccount.loans[num];

      emit CollateralReleased(msg.sender, collateral.amount, collateral.market, block.timestamp);
    }
    return this;
  }

  function _isMarketSupported(bytes32 market_) internal {
    require(markets.tokenSupportCheck[market_] != false, "Unsupported market");
  }
 
  function liquidation(
    bytes32 market_,
    bytes32 commitment_,
    bytes32 amount_
  ) external nonReentrant returns (bool) {
    //   calls the liqudiate function in the liquidator contract.
  }

  function _preLoanRequestProcess(bytes32 market_,
    bytes32 commitment_,
    uint256 loanAmount_,
    bytes32 collateralMarket_,
    uint256 collateralAmount_) internal {
    require(loanAmount_ !=0 && collateralAmount_!=0, "Loan or collateral cannot be zero");

    _isMarketSupported(market_);
    _isMarketSupported(collateralMarket_);

    markets._connectMarket(market_, loanAmount_, loanToken);
    markets._connectMarket(collateralMarket_, collateralAmount_, collateralToken);
    _cdrCheck(loanAmount_, collateralAmount_);
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