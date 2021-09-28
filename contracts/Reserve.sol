// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./util/IBEP20.sol";

contract Reserve {
    
    IBEP20 token;

    bytes32 adminReserve;
    address adminReserveAddress;


    constructor()   {
        adminReserveAddress = msg.sender;
    }

    fallback() external payable {}
    receive() external payable {}

    function transferAnyIBEP20(address tokenContract_, address recipient_, uint amount_) public authReserve() returns (bool success) {
        token = IBEP20(tokenContract_);
        token.transfer(recipient_, amount_);
        
        return bool(success);
    }

    modifier authReserve()  {
        require(msg.sender == adminReserveAddress, "Only an admin can call this function");
        _;
    }

}





//  reserver contract holds all the funds. While the comptroller is the auditor
//  general.
