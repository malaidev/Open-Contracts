// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./util/IBEP20.sol";

contract Reserve {
    
    IBEP20 token;

    bytes32 adminReserve;
    address adminReserveAddress;

    bool isReentrant = false;


    constructor()   {
        adminReserveAddress = msg.sender;
    }

    fallback() external payable {}
    receive() external payable {}


    function transferAnyBEP20(address token_,address recipient_,uint256 value_) external nonReentrant()  authReserve()  returns(bool)   {
        token = IBEP20(token_);
        token.transfer(recipient_, value_);
        return true;
    }

    // function transfer(address _to, uint256 _value) external returns (bool);


    modifier nonReentrant() {
        require(isReentrant == false, "Re-entrant alert!");
        isReentrant = true;
        _;
        isReentrant = false;
    }

    modifier authReserve()  {
        require(msg.sender == adminReserveAddress, "Only an admin can call this function");
        _;
    }

}





//  reserver contract holds all the funds. While the comptroller is the auditor
//  general.
