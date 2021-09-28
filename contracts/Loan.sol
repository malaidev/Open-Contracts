// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./TokenList.sol";
import "./Passbook.sol";
import "./util/IBEP20.sol";
import "./Comptroller.sol";
import "./Reserve.sol";

contract Loan {

	bytes32 adminLoan;
    address adminLoanAddress;

    bool isReentrant = false;

    TokenList markets = TokenList(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
    Comptroller comptroller = Comptroller(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
    Reserve reserve = Reserve(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
    Passbook passbook = passbook(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
    IBEP20 token;

	constructor() {
        adminLoanAddress = msg.sender;
    }
	function borrow() external {}
	function _borrow() internal {}

	function permissibleWithdrawal() external returns(bool) {}
	function _permissibleWithdrawal() internal returns(bool) {}

	function switchLoanType() external {}
	function _switchLoanType() internal {}

	function currentApr() public  {}

	function _calcCdr() internal {} // performs a cdr check internally


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