// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./TokenList.sol";
import "./Passbook.sol";
import "./util/Address.sol";

// import "./Library/OpenLibrary.sol";

contract Deposit {
	using Address for address;


	constructor() {
	}
	function deposit() external returns (bool) {}

	function _deposit() internal {}

	function withdrawDeposit() external returns (bool) {}

	function _withdrawDeposit() internal returns (bool) {}

	function switchDepositType() external {}

	function _switchDepositType() internal {}

	function convertDepositToCollateral() external {}
	function _convertDepositToCollateral() internal {}
}




/* ASA
Calculating interest onchain is complex. I can delegate the task to offchain
node-schedule to record and keep things up-to-date.

So, whenever someone makes a call for accrued interest, or dividend data. The
response is returned directly via a REST API offchain. This means, the interest
is calculated offchain and propagated inside the web application.

If i can get to see the accrued interest without the worry of 

ASA */



// Add dividends struct. bool for yes or no. Last dividend received -
// blockNumber


// need to associate amount with validity & blockNumber.