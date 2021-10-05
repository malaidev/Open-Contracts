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
  Comptroller comptroller =Comptroller(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
  Deposit deposit = Deposit(0xeAc61D9e3224B20104e7F0BAD6a6DB7CaF76659B);
  Reserve reserve = Reserve(payable(0xeAc61D9e3224B20104e7F0BAD6a6DB7CaF76659B));
  IBEP20 token;

  struct LoanAccount {
    uint256 accOpenTime;
    address account;
    LoanRecords[] outstandingLoans;
    CollateralRecords[] collaterals;
    CollateralisedDeposits[] collateralDeposits;
    PayableInterest[] interestRecords;
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
    uint256 market;
    uint256 commitment;
    uint256 amount;
    bool isCollateralisedDeposit;
    bool timelockApplicable; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
    uint256 timelockValidity; // timelock duration
    uint256 activationBlock; // blocknumber when yield withdrawal request was placed.
  }
  struct CollateralisedDeposits {
    uint256 id;
    uint256 intii;
  }

  // PayableInterest{} stores the amount_ of interest deducted.
  struct PayableInterest {
    uint256 id; // Id of the loan the interest is being deducted for.
    uint256 oldLengthAccruedYield; // length of the APY blockNumbers array.
    uint256 oldBlockNum; // length of the APY blockNumbers array.
    bytes32 market; // market_ this yield is calculated for
    uint256 accruedInterest; // accruedYield in
    bool timelock; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
    uint256 timelockValidity; // timelock duration
    uint256 timelockActivationBlock; // blocknumber when yield withdrawal request was placed.
  }

  enum COMMITMENT{FLEXIBLE, FIXED}


  mapping(address => LoanAccount) loanPassbook;
  mapping(address => mapping(bytes32 => mapping(bytes32 => LoanRecords))) indLoanRecords;
  mapping(address => mapping(bytes32 => mapping(bytes32 => CollateralRecords))) indCollateralRecords;
  mapping(address => mapping(bytes32 => mapping(bytes32 => CollateralisedDeposits))) indCollateralisedDepositRecords;
  mapping(address => mapping(bytes32 => mapping(bytes32 => PayableInterest))) indInterestRecords;

  event loanProcessed(
    address indexed account,
    bytes32 indexed market_,
    uint256 indexed amount_,
    bytes32 loanCommitment_,
    uint256 timestamp
  );

  constructor() {
    adminLoanAddress = msg.sender;
  }

  function loanRequest(
    bytes32 market_,
    bytes32 loanCommitment_,
    uint256 loanAmount,
    bytes32 collateralMarket_,
    bytes32 collateralCommitment_,
    uint256 collateralAmount_
  ) external {
      _isMarketSupported(market_, collateralMarket_);
      _cdrCheck(loanAmount_, collateralAmount_);

      (loanAmount, loanToken) = markets._connectMarket(market_, loanAmount);
      (collateralAmount_, collateralToken) = markets._connectMarket(collateralMarket_, collateralMarket_);
      
      _createLoanAccount(msg.sender);   
      collateralToken.transfer(address(reserve), collateralAmount_);

  }

  function _isMarketSupported(bytes32 market_, bytes32 collateralMarket_) internal {
    require(markets.tokenSupportCheck[market_] != false && markets.tokenSupportCheck[collateralMarket_] != false, "Unsupported market");
  }

  function _cdrCheck(uint loanAmount_, uint collateralAmount_) internal {
    // fetch the usd price of the loanAmount, and collateralAmount.
    //   check if the collateral amount / loanAmount is within the permissible
    //   CDR. Permissible cdr is a determinant of reserveFactor. RF =
    //   (totalDeposits) - activeLoans.
  }

  function _connectMarkets(bytes32 market_, uint256 loanAmount_, bytes32 collateralMarket_, uint256 collateralAmount_) internal {
		MarketData storage marketData = markets.indMarketData[market_];
		marketAddress = marketData.tokenAddress;
		token = IBEP20(marketAddress);
		amount_ *= marketData.decimals;
	}


    function _processLoanRequest(address account_, bytes32 market_,
    bytes32 loanCommitment_,
    uint256 loanAmount,
    bytes32 collateralMarket_,
    bytes32 collateralCommitment_,
    uint256 collateralAmount_) internal {

        LoanAccount storage loanAccount = loanPassbook[account_];
        LoanRecords storage loanRecords = indLoanRecords[account_][market_][loanCommitment_];
        CollateralRecords storage collateralRecords = indCollateralRecords[account_][market_][loanCommitment_];
        CollateralisedDeposits storage collateralisedDeposits = indCollateralisedDepositRecords[account_][market_][loanCommitment_];
        PayableInterest storage payableInterest = indInterestRecords[account_][market_][loanCommitment_];
        // calculateAPR on comptrollerContract itself. It is safest that way.  
        // _checkActiveLoan(bytes) - checks if there is any outstandng loan for
        // the market with the same commmitment type. If yes, no need to add id.
        // If no, then the below id mechanism will come handy.

        // creating a commonID;
        uint id;

        if (LoanAccount.outstandingLoans.length == 0)   {
            id = 1;
        } else if (LoanAccount.outstandingLoans.length != 0)    {
            id = LoanAccount.outstandingLoans.length + 1;
        }

    }

    function _hasLoanAccount(address account_) internal  {
        require(loanPassbook[account_].accOpenTime!=0, "Loan account does not exist");
    }

    function _createLoanAccount(address account_) internal {
		LoanAccount storage loanAccount = loanPassbook[account_];

		if (loanAccount.accOpenTime == 0) {
			loanAccount.accOpenTime = block.timestamp;
			loanAccount.account = account_;
		}
	}

  function permissibleWithdrawal() external returns (bool) {}

  function _permissibleWithdrawal() internal returns (bool) {}

  function switchLoanType() external {}

  function _switchLoanType() internal {}

  function currentApr() public {}

  function _calcCdr() internal {} // performs a cdr check internally

  function repayLoan(
    bytes32 market_,
    bytes32 loanCommitment_,
    bytes32 amount_
  ) external nonReentrant returns (bool) {}

  function _repayLoan(
    bytes32 market_,
    bytes32 loanCommitment_,
    bytes32 amount_
  ) internal {}

  function liquidation(
    bytes32 market_,
    bytes32 loanCommitment_,
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
