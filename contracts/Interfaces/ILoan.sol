// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface ILoan {
	enum STATE {ACTIVE,REPAID}

    function swapLoan(bytes32 _market, bytes32 _commitment, bytes32 _swapMarket) external returns (bool success);
    function swapToLoan(bytes32 _swapMarket, bytes32 _commitment, bytes32 _market ) external returns (bool success);
    function withdrawCollateral(bytes32 _market, bytes32 _commitment) external returns (bool success);
    function collateralPointer(address _account, bytes32 _market, bytes32 _commitment, bytes32 collateralMarket, uint collateralAmount) external view;
    function repayLoan(bytes32 _market,bytes32 _commitment,uint256 _repayAmount) external  returns (bool success);
    function permissibleWithdrawal(bytes32 _market,bytes32 _commitment, bytes32 _collateralMarket, uint256 _amount) external returns (bool success);
    function liquidation(address _account, uint256 id) external returns (bool success);
    function pauseLoan() external;
    function unpauseLoan() external;
    function isPausedLoan() external view returns (bool);
}