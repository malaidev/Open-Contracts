// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import './TokenList.sol';
import './Comptroller.sol';
import './Reserve.sol';



contract Passbook   {

    bytes32[] commitment; 

    bytes32 adminPassbook;
    address adminPassbookAddress;

    TokenList markets = TokenList(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
    Comptroller comptroller = Comptroller(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
    Reserve reserve = Reserve(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);


    struct SavingsAccount {
        uint accOpenTime;
        address account; 
        DepositRecords[] deposits;
        Yield[] accruedYieldLedger;
    }
    struct DepositRecords   {
        uint id;
        uint firstDeposit;
        bytes32 market;
        bytes32 commitment;
        uint amount; // Non fractional amount
        uint lastDeposit;
    }

    struct Yield    {
        uint id;
        uint oldLengthAccruedYield; // length of the APY blockNumbers array.
        uint oldBlockNum; // last recorded block num
        bytes32 market; // market_ this yield is calculated for
        uint accruedYield; // accruedYield in 
        bool timelock; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
        uint timelockValidity; // timelock duration
        bool timelockActivated; // blocknumber when yield withdrawal request was placed.
        bool activationBlockNum; // blocknumber when yield withdrawal request was placed.
    }

    struct LoanAccount  {
        uint accOpenTime;
        LoanRecords[] outstandingLoans;
        CollateralRecords[] collaterals;
        PayableInterest[] interestRecords;
    }
    struct LoanRecords  {
        uint time; // block.timestamp
        uint id; // since there can be multiple loans of one single asset type, it is necessary to implement  loanid;a
        bytes32 market;
        bytes32 commitment;
        uint amount;
    }

    struct CollateralisedDeposits   {
        uint time;
        uint id; // since there can be multiple loans of one single asset type, it is necessary to implement  loanid;a
    }

    struct CollateralRecords    {
        uint time;
        uint id; // since there can be multiple loans of one single asset type, it is necessary to implement  loanid;a
        bytes32 market;
        bytes32 commitment;
        uint amount;
        // uint 

    }

// Interest{} stores the amount_ of interest deducted.
    struct PayableInterest    {
        uint id; // Id of the loan the interest is being deducted for.
        uint oldLengthAccruedYield; // length of the APY blockNumbers array.
        uint oldBlockNum; // length of the APY blockNumbers array.
        bytes32 market; // market_ this yield is calculated for
        uint accruedInterest; // accruedYield in 
        bool timelock; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
        uint timelockValidity; // timelock duration
        uint timelockActivationBlock; // blocknumber when yield withdrawal request was placed.
    }

        
    mapping(address => SavingsAccount) savingsPassbook;  // Maps an account to its savings Passbook
    mapping(address => mapping(bytes32 => mapping(bytes32 => DepositRecords))) indDepositRecord; // address => market_ => commitment_ => depositRecord
    mapping(address => mapping(bytes32 => mapping(bytes32 => Yield))) indYieldRecord; // address => market_ => commitment_ => depositRecord

    event NewDeposit(address indexed account, bytes32 indexed market_, uint indexed amount_, bytes32 commitment_);
    
}