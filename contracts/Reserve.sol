// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./util/IBEP20.sol";
import "./util/Pausable.sol";

contract Reserve is Pausable {
    
    IBEP20 token;

    bytes32 adminReserve;
    address adminReserveAddress;
    address superAdminAddress;

    constructor(address superAdminAddr_) {
        superAdminAddress = superAdminAddr_;
        adminReserveAddress = msg.sender;
    }
    
    receive() external payable {
        payable(adminReserveAddress).transfer(_msgValue());
    }
    
    fallback() external payable {
        payable(adminReserveAddress).transfer(_msgValue());
    }
    
    // function transferAnyERC20(address token_,address _recipient,uint256 _value) external returns(bool) {
    //     IBEP20(token_).transfer(_recipient, _value);
    //     return true;
    // }

    function transferAnyBEP20(
        address token_,
        address _recipient,
        uint256 _value) external nonReentrant  authReserve  returns(bool)   
    {
        token = IBEP20(token_);
        token.transfer(_recipient, _value);
        return true;
    }

    modifier authReserve()  {
        require(msg.sender == adminReserveAddress || 
            msg.sender == superAdminAddress, 
            "Only Reverse admin can call this function"
        );
        _;
    }

    function pause() external authReserve() nonReentrant() {
       _pause();
	}
	
	function unpause() external authReserve() nonReentrant() {
       _unpause();   
	}

}

//  reserver contract holds all the funds. While the comptroller is the auditor
//  general.
