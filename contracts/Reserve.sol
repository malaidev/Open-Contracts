// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./util/IBEP20.sol";
import "./util/Pausable.sol";
import "./Interfaces/ILoan.sol";
import "./Interfaces/IDeposit.sol";

contract Reserve is Pausable {
    

    ILoan loan = ILoan(0xeAc61D9e3224B20104e7F0BAD6a6DB7CaF76659B);
    IDeposit deposit = IDeposit(0xeAc61D9e3224B20104e7F0BAD6a6DB7CaF76659B);

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

    function marketReserve(bytes32 _market) external view returns(uint) {
        _marketReserve(_market);
    }
    function _marketReserve(bytes32 _market) internal view returns(uint) {
        return loan.reserves(_market) + deposit.reserves(_market);
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
