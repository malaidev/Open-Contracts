<<<<<<< HEAD
// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// import "./IAugustusSwapper.sol";
// import "./ITokenList.sol";

interface ILiquidator {
    function swap(bytes32 _fromMarket, bytes32 _toMarket, uint256 _fromAmount, uint8 mode) external returns (uint256 receivedAmount);
    function pauseLiquidator() external;
    function unpauseLiquidator() external;
    function isPausedLiquidator() external view returns (bool);
=======
// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// import "./IAugustusSwapper.sol";
// import "./ITokenList.sol";

interface ILiquidator {
    function swap(bytes32 _fromMarket, bytes32 _toMarket, uint256 _fromAmount, uint8 mode) external returns (uint256 receivedAmount);
    function pauseLiquidator() external;
    function unpauseLiquidator() external;
    function isPausedLiquidator() external view returns (bool);
>>>>>>> 24a2f5b138a7c09f54be2d2dd357f39580a432dc
}