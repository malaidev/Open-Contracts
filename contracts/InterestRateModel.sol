// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./Comptroller.sol";
import "./Passbook.sol";

contract InterestRateModel {
  Comptroller comptroller =
    Comptroller(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
  Passbook passbook = Passbook(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
  bytes32 commitment = passbook.commitment;

  function _yieldPerBlock(bytes32 commitment_) internal returns (uint256) {
    APY memory _apyRecord = comptroller.indAPYRecords[commitment_];
    uint256 _yield = _apyRecord.apyChangeRecords[
      _apyRecord.apyChangeRecords.length - 1
    ];
    return _yield / 105120000;
  }

  function _interestPerBlock(bytes32 commitment_) internal returns (uint256) {
    APY memory _aprRecord = comptroller.indAPRRecords[commitment_];
    uint256 _interest = _aprRecord.aprChangeRecords[
      _aprRecord.aprChangeRecords.length - 1
    ];
    return _interest / 105120000;
  }

  function _yieldMath(bytes32 commitment_, uint256 lastBlock_)
    returns (uint256)
  {}
}

// https://github.com/compound-finance/compound-protocol/blob/master/contracts/WhitePaperInterestRateModel.sol
