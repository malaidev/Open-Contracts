<<<<<<< HEAD
// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface ILoan {
	enum STATE {ACTIVE,REPAID}

    function swapLoan(bytes32 _market, bytes32 _commitment, bytes32 _swapMarket) external returns (bool);
    function swapToLoan(bytes32 _swapMarket, bytes32 _commitment, bytes32 _market ) external returns (bool);
    function withdrawCollateral(bytes32 _market, bytes32 _commitment) external returns (bool);
    function collateralPointer(address _account, bytes32 _market, bytes32 _commitment, bytes32 collateralMarket, uint collateralAmount) external view returns (bool);
    function repayLoan(bytes32 _market,bytes32 _commitment,uint256 _repayAmount) external  returns (bool);
    function getFairPriceLoan(uint _requestId) external returns (uint);
    function pauseLoan() external;
    function unpauseLoan() external;
    function isPausedLoan() external view returns (bool);
=======
// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface ILoan {
	enum STATE {ACTIVE,REPAID}

    function swapLoan(bytes32 _market, bytes32 _commitment, bytes32 _swapMarket) external returns (bool);
    function swapToLoan(bytes32 _swapMarket, bytes32 _commitment, bytes32 _market ) external returns (bool);
    function withdrawCollateral(bytes32 _market, bytes32 _commitment) external returns (bool);
    function collateralPointer(address _account, bytes32 _market, bytes32 _commitment, bytes32 collateralMarket, uint collateralAmount) external view returns (bool);
    function repayLoan(bytes32 _market,bytes32 _commitment,uint256 _repayAmount) external  returns (bool);
    function pauseLoan() external;
    function unpauseLoan() external;
    function isPausedLoan() external view returns (bool);
>>>>>>> 24a2f5b138a7c09f54be2d2dd357f39580a432dc
}