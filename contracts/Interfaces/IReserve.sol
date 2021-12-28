<<<<<<< HEAD
// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// import "../util/IBEP20.sol";

interface IReserve {
    function transferAnyBEP20(address token_,address recipient_,uint256 value_) external returns(bool);
    function avblMarketReserves(bytes32 _market) external view returns (uint);
    function marketReserves(bytes32 _market) external view returns(uint);
    function marketUtilisation(bytes32 _market) external view returns(uint);
    function collateralTransfer(address _account, bytes32 _market, bytes32 _commitment) external returns (bool);
    function pauseReserve() external;
    function unpauseReserve() external;
    function isPausedReserve() external view returns (bool);
}
=======
// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// import "../util/IBEP20.sol";

interface IReserve {
    function transferAnyBEP20(address token_,address recipient_,uint256 value_) external returns(bool);
    function avblMarketReserves(bytes32 _market) external view returns (uint);
    function marketReserves(bytes32 _market) external view returns(uint);
    function marketUtilisation(bytes32 _market) external view returns(uint);
    function collateralTransfer(address _account, bytes32 _market, bytes32 _commitment) external returns (bool);
    function pauseReserve() external;
    function unpauseReserve() external;
    function isPausedReserve() external view returns (bool);
}
>>>>>>> 24a2f5b138a7c09f54be2d2dd357f39580a432dc
