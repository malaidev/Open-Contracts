// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// import "./ITokenList.sol";
// import "./IComptroller.sol";
// import "./IReserve.sol";

interface IDeposit {
	enum SAVINGSTYPE{DEPOSIT, YIELD, BOTH}
	function hasAccount(address account_) external view returns (bool);
    function savingsBalance(bytes32 _market, bytes32 _commitment) external returns (uint);
	function convertYield(bytes32 _market, bytes32 _commitment) external returns (bool success);
	function hasYield(bytes32 _market, bytes32 _commitment) external view returns (bool);
	function avblReservesDeposit(bytes32 _market) external view returns (uint);
	function utilisedReservesDeposit(bytes32 _market) external view returns(uint);
	function hasDeposit(bytes32 _market, bytes32 _commitment) external view returns (bool);
	function createDeposit(bytes32 _market, bytes32 _commitment, uint256 _amount) external returns (bool);
	function withdrawDeposit (bytes32 _market, bytes32 _commitment, uint _amount, SAVINGSTYPE _request) external returns (bool success);
	function addToDeposit(bytes32 _market, bytes32 _commitment, uint _amount) external returns(bool success);
    function getFairPriceDeposit(uint _requestId) external returns (uint);
	function pauseDeposit() external;
	function unpauseDeposit() external;
	function isPausedDeposit() external view returns (bool);
}