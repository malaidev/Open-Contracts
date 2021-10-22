// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import "./util/Pausable.sol";
import "./mockup/IMockBep20.sol";
import "./interfaces/IAugustusSwapper.sol";
import "./interfaces/ITokenList.sol";

contract Liquidator is Pausable {
    address adminLiquidator;
    address superAdminAddress;
  
    IAugustusSwapper public simpleSwap;
    ITokenList public tokenList;

    constructor(address superAdminAddr_, address tokenListAddr_) {
        superAdminAddress = superAdminAddr_;
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
        IMockBep20(token_).transfer(recipient_, value_);
        return true;
    }
    
    function swap(bytes32 _fromMarket, bytes32 _toMarket, uint256 _fromAmount, uint8 mode) external payable returns (uint256 receivedAmount) {

        require(_fromMarket != _toMarket, "FromToken can't be the same as ToToken.");

        address addrFromMarket;
        address addrToMarket;
        if(mode == 0){
            addrFromMarket = tokenList.getMarketAddress(_fromMarket);
            addrToMarket = tokenList.getMarket2Address(_fromMarket);
        } else if(mode == 1) {
            addrFromMarket = tokenList.getMarket2Address(_fromMarket);
            addrToMarket = tokenList.getMarketAddress(_toMarket);
        } else if(mode == 2) {
            addrFromMarket = tokenList.getMarket2Address(_toMarket);
            addrToMarket = tokenList.getMarket2Address(_fromMarket);
        }

        uint minAmount;
        address[] memory callees;
        uint256[] memory startIndexes;
        uint256[] memory values;
        bytes memory exchangeData;
        address payable beneficiary;
        receivedAmount =  simpleSwap.simpleSwap(
            addrFromMarket,
            addrToMarket,
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