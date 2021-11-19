// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface ILoan1 {
	enum STATE {ACTIVE,REPAID}

    function hasLoanAccount(address _account) external view returns (bool);
    function avblReservesLoan(bytes32 _market) external view returns(uint);
    function utilisedReservesLoan(bytes32 _market) external view returns(uint);
    function loanRequest(bytes32 _market, bytes32 _commitment, uint256 _loanAmount, bytes32 _collateralMarket, uint256 _collateralAmount) external;
    function addCollateral(bytes32 _market, bytes32 _commitment, bytes32 _collateralMarket, uint256 _collateralAmount) external;
    function liquidation(address _account, uint256 id) external returns (bool success);
    function permissibleWithdrawal(bytes32 _market,bytes32 _commitment, bytes32 _collateralMarket, uint256 _amount) external returns (bool success);
    function pauseLoan1() external;
    function unpauseLoan1() external;
    function isPausedLoan1() external view returns (bool);
}