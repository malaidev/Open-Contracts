// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./TokenList.sol";
import "./Comptroller.sol";
import "./Deposit.sol";
import "./Reserve.sol";
import "./util/IBEP20.sol";

contract Loan {
  bytes32 adminLoan;
  address adminLoanAddress;

  bool isReentrant = false;

  TokenList markets = TokenList(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
  Comptroller comptroller = Comptroller(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
  Deposit deposit = Deposit(0xeAc61D9e3224B20104e7F0BAD6a6DB7CaF76659B);
  Reserve reserve = Reserve(payable(0xeAc61D9e3224B20104e7F0BAD6a6DB7CaF76659B));
  IBEP20 loanToken;
  IBEP20 collateralToken;

  struct LoanAccount {
    uint256 accOpenTime;
    address account;
    LoanRecords[] loans; // 2 types of loans. 3 markets intially. So, a maximum o f6 records.
    CollateralRecords[] collaterals;
    DeductibleInterest[] accruedInterest;
    CollateralYield[] accruedYield;
  }
  struct LoanRecords {
    uint256 id;
    uint256 initialLoan;
    bytes32 market;
    bytes32 commitment;
    uint256 loanAmount;
    uint256 lastUpdate;
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
    bool isTimelockActivated; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
    uint timelockValidity; // timelock duration
    uint releaseAfter; // block.number(isTimelockActivated) + timelockValidity.
  }
  // DeductibleInterest{} stores the amount_ of interest deducted.
  struct DeductibleInterest {
    uint256 id; // Id of the loan the interest is being deducted for.
    bytes32 market; // market_ this yield is calculated for
    uint256 oldLengthAccruedInterest; // length of the APY blockNumbers array.
    uint256 oldBlockNum; // length of the APY blockNumbers array.
    uint256 accruedInterest;
    bool isTimelockApplicable; // accruedYield in
    bool isTimelockActivated; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
    uint256 timelockValidity; // timelock duration
    uint256 timelockActivationBlock; // blocknumber when yield withdrawal request was placed.
  }

  struct SwapMarket {
    uint id;
    uint index;

    //  Implement
  }

  enum COMMITMENT{FLEXIBLE, FIXED}


  mapping(address => LoanAccount) loanPassbook;
  mapping(address => mapping(bytes32 => mapping(bytes32 => LoanRecords))) indLoanRecords;
  mapping(address => mapping(bytes32 => mapping(bytes32 => CollateralRecords))) indCollateralRecords;
  mapping(address => mapping(bytes32 => mapping(bytes32 => DeductibleInterest))) indaccruedInterest;
  mapping(address => mapping(bytes32 => mapping(bytes32 => CollateralYield))) indCollateralisedDepositRecords;

  event NewLoanProcessed(address indexed account,bytes32 indexed market,uint256 indexed amount,bytes32 loanCommitment,uint256 timestamp);
  event LoanRepaid(address indexed account, uint256 indexed id,  bytes32 market, uint256 indexed amount, uint256 timestamp);
  event CollateralAdd(address indexed account, uint256 indexed id,  uint amount, uint256 timestamp);
  event WithdrawLoan(address indexed account, uint256 indexed id,  bytes32 market, uint256 indexed amount, uint256 timestamp);

  constructor() {
    adminLoanAddress = msg.sender;
  }

  function loanRequest(bytes32 market_,bytes32 commitment_,uint256 loanAmount_,bytes32 collateralMarket_,uint256 collateralAmount_) external nonReentrant() returns(bool success) {
      
      _preLoanRequestProcess(market_, commitment_, loanAmount_, collateral_, collateralAmount_);      
      
      LoanAccount storage loanAccount = loanPassbook[msg.sender];
      LoanRecords storage loan = indLoanRecords[msg.sender][market_][commitment_];
      CollateralRecords storage collateral = indCollateralRecords[msg.sender][market_][commitment_];
      DeductibleInterest storage deductibleInterest = indaccruedInterest[msg.sender][market_][commitment_];
      CollateralYield storage cYield = indCollateralisedDepositRecords[msg.sender][market_][commitment_];
      APR storage apr = comptroller.indAPRRecords[commitment_];

      collateralToken.transfer(address(reserve), collateralAmount_);      
      _ensureLoanAccount(msg.sender);
      
      require(loan.id == 0 && loan.initialLoan == 0, "Add on loans on the same market is not permitted");
      _processNewLoan(msg.sender,market_,commitment_, loanAmount_, collateral_, collateralAmount_);
      loanToken.transfer(address(reserve), msg.sender, loanAmount_);
      
      emit NewLoanProcessed(msg.sender, market_,loanAmount_, commitment_, block.timetstamp);
      return bool(sucess);
      // Process the loan & update the records.
  }
  function _preLoanRequestProcess(bytes32 market_,
    bytes32 commitment_,
    uint256 loanAmount_,
    bytes32 collateralMarket_,
    uint256 collateralAmount_) internal {
    require(loanAmount_ !=0 && collateralAmount_!=0, "Loan or collateral cannot be zero");
    _isMarketSupported(market_, collateral_);

    // IBEP20 loanToken;
    // IBEP20 collateralToken;

    markets._connectMarket(market_, loanAmount_, loanToken);
    markets._connectMarket(collateralMarket_, collateralAmount_, collateralToken);
    _cdrCheck(loanAmount_, collateralAmount_);
  }

  function _isMarketSupported(bytes32 market_, bytes32 collateralMarket_) internal {
    require(markets.tokenSupportCheck[market_] != false && markets.tokenSupportCheck[collateral_] != false, "Unsupported market");
  }

  function _cdrCheck(uint loanAmount_, uint collateralAmount_) internal {
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
            initialLoan: block.number,
            market: market_,
            commitment: commitment_,
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
          initialLoan: block.number,
          market: market_,
          commitment: commitment_,
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

  function addCollateral(bytes32 loanMarket_, bytes32 loanCommitment_, bytes32 collateralMarket_, bytes32 collateralAmount_) external returns (bool)  {
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
    
    emit CollateralAdd(msg.sender, loan.id, collateralAmount_, block.timestamp);

    return true;
  }

  function _preAddCollateralProcess(address account_,bytes32 loanMarket_, bytes32 loanCommitment_) internal {
    _isMarketSupported(loanMarket_, loanCommitment_);

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
    // update collateralRecords
    collateral.amount += collateralAmount_;
    // update loanAccountPointer 
    loanAccount.collaterals[loan.id-1].amount = collateral.amount;
  }

  function swapLoan(bytes32 market, uint loanId,uint amount, bytes32 secondaryMarket, uint swappedAmount) external returns(bool)  {}

  function permissibleWithdrawal() external returns (bool) {}

  function _permissibleWithdrawal() internal returns (bool) {}

  function switchLoanType() external {}

  function _switchLoanType() internal {}

  function currentApr() public {}

  function _calcCdr() internal {} // performs a cdr check internally

  function repayLoan(
    bytes32 market_,
    bytes32 commitment_,
    bytes32 amount_
  ) external nonReentrant returns (bool) {}

  function _repayLoan(
    bytes32 market_,
    bytes32 commitment_,
    bytes32 amount_
  ) internal {}

  function liquidation(
    bytes32 market_,
    bytes32 commitment_,
    bytes32 amount_
  ) external nonReentrant returns (bool) {
    //   calls the liqudiate function in the liquidator contract.
  }

  function collateralRelease(uint256 loanId, uint256 amount_)
    external
    nonReentrant
  {}

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
