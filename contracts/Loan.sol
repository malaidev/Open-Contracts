// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./interfaces/ITokenList.sol";
import "./util/IBEP20.sol";
import "./util/Pausable.sol";
import "./interfaces/IComptroller.sol";
import "./interfaces/IReserve.sol";

contract Loan is Pausable {

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

	bytes32 adminLoan;
    address adminLoanAddress;
    address superAdminAddress;

    ITokenList markets;
    IComptroller comptroller;
    IReserve reserve;
    IBEP20 token;

	constructor(
        address superAdminAddr_,
        address tokenListAddr,
        address comptrollerAddr,
        address reserveAddr
    )
    {
        superAdminAddress = superAdminAddr_;
        adminLoanAddress = msg.sender;
        markets = ITokenList(tokenListAddr);
        comptroller = IComptroller(comptrollerAddr);
        reserve = IReserve(reserveAddr);
    }

    receive() external payable {
        payable(adminLoanAddress).transfer(_msgValue());
    }
    
    fallback() external payable {
        payable(adminLoanAddress).transfer(_msgValue());
    }
    
    function transferAnyERC20(address token_,address recipient_,uint256 value_) external returns(bool) {
        IBEP20(token_).transfer(recipient_, value_);
        return true;
    }

	function borrow() external {}
	function _borrow() internal {}

	function permissibleWithdrawal() external returns(bool) {}
	function _permissibleWithdrawal() internal returns(bool) {}

	function switchLoanType() external {}
	function _switchLoanType() internal {}

	function currentApr() public  {}

	function _calcCdr() internal {} // performs a cdr check internally
    
    function pause() external authLoan() nonReentrant() {
       _pause();
	}
	
	function unpause() external authLoan() nonReentrant() {
       _unpause();   
	}

    modifier authLoan() {
        require(
            msg.sender == adminLoanAddress || 
            msg.sender == superAdminAddress,
            "Only Loan admin can call this function"
        );
        _;
    }
}