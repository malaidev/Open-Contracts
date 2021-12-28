// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
interface IOracleOpen {
    function getLatestPrice(bytes32 _market) external returns (uint);
    function getFairPrice(uint _requestId) external returns (uint);
    function liquidationTrigger(address account, uint loanId) external returns (bool);
    function pauseOracle() external;
    function unpauseOracle() external;
    function isPausedOracle() external view returns (bool);
}
