// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

struct Struct1 {
    uint val1;
    string str1;
}

struct AppStorage {
    Struct1 st1;
}
library Lib1 {

    uint8 constant STATUS_CLOSED_PORTAL = 0;
    uint8 constant STATUS_VRF_PENDING = 1;
    bytes32 constant DIAMOND_STORAGE_POSITION = 0xa7513e6e63bb532f9771966eae24bd3160885bc35e57313effe2e8bf1f822000;
    
    event TestEvent1(uint val);

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := DIAMOND_STORAGE_POSITION
        }
    }

    function _getVal1() internal view returns (uint) {
        AppStorage storage s = diamondStorage();
        return s.st1.val1;
    }

    function _setVal1(uint val) internal {
        AppStorage storage s = diamondStorage();
        s.st1.val1 = val;
        emit TestEvent1(val);
    }
}
