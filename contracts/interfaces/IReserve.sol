// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// import "../util/IBEP20.sol";

interface IReserve {
    function transferAnyBEP20(address token_,address recipient_,uint256 value_) external returns(bool);
    function avblMarketReserves(bytes32 _market) external view returns (uint);
    function marketReserves(bytes32 _market) external view returns(uint);
    function marketUtilisation(bytes32 _market) external view returns(uint);
    function pauseReserve() external;
    function unpauseReserve() external;
    function isPausedReserve() external view returns (bool);
}
