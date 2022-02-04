// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface ILoanExt {
	enum STATE {ACTIVE,REPAID}

    function hasLoanAccount(address _account) external view returns (bool);
    function avblReservesLoan(bytes32 _market) external view returns(uint);
    function utilisedReservesLoan(bytes32 _market) external view returns(uint);
    function loanRequest(bytes32 _market, bytes32 _commitment, uint256 _loanAmount, bytes32 _collateralMarket, uint256 _collateralAmount) external returns (bool);
    function addCollateral(bytes32 _market, bytes32 _commitment, bytes32 _collateralMarket, uint256 _collateralAmount) external returns (bool success);
    function liquidation(address _account, uint256 id) external returns (bool success);
    function pauseLoanExt() external;
    function unpauseLoanExt() external;
    function isPausedLoanExt() external view returns (bool);
}
