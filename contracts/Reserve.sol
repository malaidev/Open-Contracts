// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

contract Reserve {

    struct ApyLedger    {
        uint[] _apy; // apy rate as a percentage. It means, for 18%, it is recorded as 18.
        uint[] _blockNumber; // records  the blocknumber when the change was applied
    }
    struct AprLedger    {
        uint[] _apr; // apr rate as a percentage. It means, for 18%, it is recorded as 18.
        uint[] _blockNumber; // records  the blocknumber when the change was applied
    }

    fallback() external payable {}
    receive() external payable {}

}





//  reserver contract holds all the funds. While the comptroller is the auditor
//  general.
