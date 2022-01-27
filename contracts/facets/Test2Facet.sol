// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {AppStorage, Lib2} from "../libraries/Lib2.sol";

contract Test2Facet {
    event TestEvent(address something);

    function setVal2(uint val) external {
        Lib2._setVal2(val);
    }

    function getVal2() external view returns (uint) {
        return Lib2._getVal2();
    }

}
