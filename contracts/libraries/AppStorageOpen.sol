// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Address.sol";
import "../interfaces/ILoan.sol";
import "../util/IBEP20.sol";

// =========== TokenList structs ===========
struct MarketData {
    bytes32 market;
    address tokenAddress;
    uint256 decimals;
    uint256 chainId;
    uint minAmount;
}

// =========== Comptroller structs ===========
/// @notice each APY or APR struct holds the recorded changes in interest data & the
/// corresponding time for a particular commitment type.
    struct APY  {
        bytes32 commitment; 
        uint[] time; // ledger of time when the APY changes were made.
        uint[] apyChanges; // ledger of APY changes.
    }

    struct APR  {
        bytes32 commitment; // validity
        uint[] time; // ledger of time when the APR changes were made.
        uint[] aprChanges; // Per block.timestamp APR is tabulated in here.
    }

// =========== Deposit structs ===========
struct SavingsAccount {
    uint accOpenTime;
    address account; 
    DepositRecords[] deposits;
    YieldLedger[] yield;
}

struct DepositRecords   {
    uint id;
    bytes32 market;
    bytes32 commitment;
    uint amount;
    uint lastUpdate;
    bool isTimelockApplicable; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
    bool isTimelockActivated; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
    uint timelockValidity; // timelock duration
    uint activationTime; // block.timestamp(isTimelockActivated) + timelockValidity.
}

struct YieldLedger    {
    uint id;
    bytes32 market; //_market this yield is calculated for
    uint oldLengthAccruedYield; // length of the APY time array.
    uint oldTime; // last recorded block num. This is when this struct is lastly updated.
    uint accruedYield; // accruedYield in 
    bool isTimelockApplicable; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
    bool isTimelockActivated; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
    uint timelockValidity; // timelock duration
    uint activationTime; // block.timestamp(isTimelockActivated) + timelockValidity.
}
// =========== Loan structs ===========
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
    ILoan.STATE state;
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

// DeductibleInterest stores the amount_ of interest deducted.
struct DeductibleInterest {
    uint256 id; // Id of the loan the interest is being deducted for.
    bytes32 market; // market_ this yield is calculated for
    uint256 oldLengthAccruedInterest; // length of the APY time array.
    uint256 oldTime; // length of the APY time array.
    uint256 accruedInterest;
}

// =========== OracleOpen structs =============
struct PriceData {
    bytes32 market;
    uint amount;
    uint price;
}

// =========== AccessRegistry structs =============

struct AppStorageOpen {
    
    IBEP20 token;
    mapping(bytes4 => uint) facetIndex;
	address reserveAddress;
    // ===========  admin addresses ===========
    bytes32 superAdmin; // superAdmin address backed in function setupgradeAdmin()
    address superAdminAddress; // Address of AccessRegistry
    address upgradeAdmin; 

    // =========== TokenList state variables ===========
    bytes32 adminTokenList;
    address adminTokenListAddress;
    bytes32[] pMarkets; // Primary markets
    bytes32[] sMarkets; // Secondary markets

    mapping (bytes32 => bool) tokenSupportCheck;
    mapping (bytes32=>uint256) marketIndex;
    mapping (bytes32 => MarketData) indMarketData;

    mapping (bytes32 => bool) token2SupportCheck;
    mapping (bytes32=>uint256) market2Index;
    mapping (bytes32 => MarketData) indMarket2Data;

    // =========== Comptroller state variables ===========
    bytes32 adminComptroller;
    address adminComptrollerAddress;        
    bytes32[] commitment; // NONE, TWOWEEKS, ONEMONTH, THREEMONTHS
    uint reserveFactor;
    uint loanIssuanceFees;
    uint loanClosureFees;
    uint loanPreClosureFees;
    uint depositPreClosureFees;
    uint maxWithdrawalFactor;
    uint maxWithdrawalBlockLimit;
    uint depositWithdrawalFees;
    uint collateralReleaseFees;
    uint yieldConversionFees;
    uint marketSwapFees;
    mapping(bytes32 => APY) indAPYRecords;
    mapping(bytes32 => APR) indAPRRecords;

    // =========== Liquidator state variables ===========
    bytes32 adminLiquidator;
    address adminLiquidatorAddress;

    // =========== Deposit state variables ===========
    bytes32 adminDeposit;
    address adminDepositAddress;

    mapping(address => SavingsAccount) savingsPassbook;  // Maps an account to its savings Passbook
    mapping(address => mapping(bytes32 => mapping(bytes32 => DepositRecords))) indDepositRecord; // address =>_market => _commitment => depositRecord
    mapping(address => mapping(bytes32 => mapping(bytes32 => YieldLedger))) indYieldRecord; // address =>_market => _commitment => depositRecord

    //  Balance monitoring  - Deposits
    mapping(bytes32 => uint) marketReservesDeposit; // mapping(market => marketBalance)
    mapping(bytes32 => uint) marketUtilisationDeposit; // mapping(market => marketBalance)

    // =========== OracleOpen state variables ==============
    bytes32 adminOpenOracle;
    address adminOpenOracleAddress;
    mapping(bytes32 => address) pairAddresses;
    PriceData[] prices;
    mapping(uint => PriceData) priceData;
    uint requestEventId;
    // =========== Loan state variables ============
    bytes32 adminLoan;
    address adminLoanAddress;
    bytes32 adminLoanExt;
    address adminLoanExtAddress;
    IBEP20 loanToken;
    IBEP20 withdrawToken;
    IBEP20 collateralToken;

    // STRUCT Mapping
    mapping(address => LoanAccount) loanPassbook;
    mapping(address => mapping(bytes32 => mapping(bytes32 => LoanRecords))) indLoanRecords;
    mapping(address => mapping(bytes32 => mapping(bytes32 => CollateralRecords))) indCollateralRecords;
    mapping(address => mapping(bytes32 => mapping(bytes32 => DeductibleInterest))) indAccruedAPR;
    mapping(address => mapping(bytes32 => mapping(bytes32 => CollateralYield))) indAccruedAPY;
    mapping(address => mapping(bytes32 => mapping(bytes32 => LoanState))) indLoanState;

    //  Balance monitoring  - Loan
    mapping(bytes32 => uint) marketReservesLoan; // mapping(market => marketBalance)
    mapping(bytes32 => uint) marketUtilisationLoan; // mapping(market => marketBalance)

    // =========== Reserve state variables ===========
    bytes32 adminReserve;
    address adminReserveAddress;

    // =========== AccessRegistry state variables ==============
    
}
