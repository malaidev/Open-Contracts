// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {AppStorage, Lib1} from "../libraries/Lib1.sol";

contract Test1Facet {
    event TestEvent(address something);

    function setVal1(uint val) external {
        Lib1._setVal1(val);
    }

    function getVal1() external view returns (uint) {
        return Lib1._getVal1();
    }

}
