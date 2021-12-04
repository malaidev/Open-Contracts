// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

contract Test {
    constructor() {
    	// LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
        // ds.adminReserveAddress = msg.sender;
        // ds.reserve = IReserve(msg.sender);
    }
    function Myfunc() public view returns(uint256) {
        return 123;
    }
}