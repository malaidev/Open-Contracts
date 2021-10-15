// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import "./util/Pausable.sol";
import "./util/IBEP20.sol";
import "./interfaces/IAugustusSwapper.sol";
import "./interfaces/ITokenList.sol";

contract Liquidator is Pausable {
    address adminLiquidator;
  
    IAugustusSwapper public simpleSwap;
    ITokenList public tokenList;

    constructor(address superAdminAddr_, address tokenListAddr_) {
        adminLiquidator = msg.sender;
        tokenList = ITokenList(tokenListAddr_);
        IAugustusSwapper _simpleSwap = IAugustusSwapper(0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57);
        simpleSwap = _simpleSwap;
    }
    
    receive() external payable {
        payable(adminLiquidator).transfer(_msgValue());
    }
    
    fallback() external payable {
        payable(adminLiquidator).transfer(_msgValue());
    }
    
    function transferAnyERC20(address token_,address recipient_,uint256 value_) 
        external returns(bool) 
    {
        IBEP20(token_).transfer(recipient_, value_);
        return true;
    }
    
    function swap(bytes32 _fromToken, bytes32 _toToken, uint256 _fromAmount) external payable returns (uint256 receivedAmount) {

        require(_fromToken != _toToken, "_fromToken = _toToken");

        address addrFromToken = tokenList.getMarket2TokenAddress(_fromToken);
        address addrToToken = tokenList.getMarket2TokenAddress(_toToken);
        uint minAmount;
        address[] memory callees;
        uint256[] memory startIndexes;
        uint256[] memory values;
        bytes memory exchangeData;
        address payable beneficiary;
        uint256 _receiveAmount =  simpleSwap.simpleSwap(
            addrFromToken,
            addrToToken,
            _fromAmount,
            minAmount,
            minAmount,
            callees,
            exchangeData,
            startIndexes,
            values,
            beneficiary,
            string(""),
            false
        );
        return _receiveAmount;
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