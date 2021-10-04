// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;
import "./UpgradibilityProxy.sol";
contract ProxyDeposit is UpgradibilityProxy {

    constructor(address _implementation) {
        _upgradeTo(_implementation);
    }
}