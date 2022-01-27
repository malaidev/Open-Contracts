// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

struct Struct2 {
    uint val2;
    string str2;
}

struct AppStorage {
    Struct2 st2;
}
library Lib2 {

    uint8 constant STATUS_CLOSED_PORTAL = 0;
    uint8 constant STATUS_VRF_PENDING = 1;
    bytes32 constant DIAMOND_STORAGE_POSITION = 0xa7513e6e63bb532f9771966eae24bd3160885bc35e57313effe2e8bf1f822011;

    event TestEvent2(uint val);

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := DIAMOND_STORAGE_POSITION
        }
    }

    function _getVal2() internal view returns (uint) {
        AppStorage storage s = diamondStorage();
        return s.st2.val2;
    }

    function _setVal2(uint val) internal {
        AppStorage storage s = diamondStorage();
        s.st2.val2 = val;
        emit TestEvent2(val);
    }
}
