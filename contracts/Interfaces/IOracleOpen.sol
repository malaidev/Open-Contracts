// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

// import "../util/IBEP20.sol";
// import "./ITokenList.sol";
// import "./ILoan.sol";

interface IOracleOpen {
    function getLatestPrice(bytes32 _market) external view returns (uint256);
    function getLatestTimestamp(bytes32 _market) external view returns (uint256);
    function newPriceRequest (
        string memory _url,
        bytes32 _market,
        uint _price
    ) external;
    function updatedChainRequest (
        bytes32 _market,
        uint _price
    ) external;
}