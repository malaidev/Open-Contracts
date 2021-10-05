// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;
import "./util/Pausable.sol";
import "./util/IBEP20.sol";
contract Liquidator is Pausable {
    address adminLiquidator;
    constructor() {
        adminLiquidator = msg.sender;
    }
    
    receive() external payable {
        payable(adminLiquidator).transfer(_msgValue());
    }
    
    fallback() external payable {
        payable(adminLiquidator).transfer(_msgValue());
    }
    
    function transferAnyERC20(address token_,address recipient_,uint256 value_) external returns(bool) {
        IBEP20(token_).transfer(recipient_, value_);
        return true;
    }

    function pause() external authLiquidator() nonReentrant() {
       _pause();
	}
	
	function unpause() external authLiquidator() nonReentrant() {
       _unpause();   
	}

	modifier authLiquidator() {
		require(
			msg.sender == adminLiquidator,
			"Only Liquidator admin can call this function"
		);
		_;
	}
}