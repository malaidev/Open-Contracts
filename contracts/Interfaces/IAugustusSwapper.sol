// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
interface IAugustusSwapper {
    
    function simpleSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 expectedAmount,
        address[] memory callees,
        bytes memory exchangeData,
        uint256[] memory startIndexes,
        uint256[] memory values,
        address payable beneficiary,
        string memory referrer,
        bool useReduxToken
    )
        external
        payable
        returns (uint256 receivedAmount);
    
}