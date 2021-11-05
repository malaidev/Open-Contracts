// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import "./util/Pausable.sol";
// import "./mockup/IMockBep20.sol";
import "./libraries/LibDiamond.sol";

contract Liquidator is Pausable, ILiquidator {
  
    constructor() {
    	// LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
        // ds.adminLiquidatorAddress = msg.sender;
        // ds.liquidator = ILiquidator(msg.sender);
        // ds.simpleSwap = IAugustusSwapper(0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57);
    }
    
    // receive() external payable {
    // 	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
    //     payable(ds.contractOwner).transfer(_msgValue());
    // }

    // fallback() external payable {
    // 	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
    //     payable(ds.adminLiquidatorAddress).transfer(_msgValue());
    // }
    
    function swap(bytes32 _fromMarket, bytes32 _toMarket, uint256 _fromAmount, uint8 _mode) external returns (uint256 receivedAmount) {

        require(_fromMarket != _toMarket, "FromToken can't be the same as ToToken.");
        receivedAmount = LibDiamond._swap(_fromMarket, _toMarket, _fromAmount, _mode);
    }

    function pauseLiquidator() external authLiquidator() nonReentrant() {
       _pause();
	}
	
	function unpauseLiquidator() external authLiquidator() nonReentrant() {
       _unpause();   
	}

    function isPausedLiquidator() external view virtual returns (bool) {
        return _paused();
    }

	modifier authLiquidator() {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		require(
			msg.sender == ds.contractOwner,
			"Only Liquidator admin can call this function"
		);
		_;
	}
}