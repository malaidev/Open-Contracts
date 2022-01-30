// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "../util/Pausable.sol";
// import "./mockup/IMockBep20.sol";
import "../libraries/LibOpen.sol";

contract Liquidator is Pausable, ILiquidator {
  
    constructor() {
    	// LibOpen.DiamondStorage storage ds = LibOpen.diamondStorage(); 
        // ds.adminLiquidatorAddress = msg.sender;
        // ds.liquidator = ILiquidator(msg.sender);
        // ds.simpleSwap = IAugustusSwapper(0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57);
    }
    
    // receive() external payable {
    // 	LibOpen.DiamondStorage storage ds = LibOpen.diamondStorage(); 
    //     payable(ds.contractOwner).transfer(_msgValue());
    // }

    // fallback() external payable {
    // 	LibOpen.DiamondStorage storage ds = LibOpen.diamondStorage(); 
    //     payable(ds.adminLiquidatorAddress).transfer(_msgValue());
    // }
    
    function swap(bytes32 _fromMarket, bytes32 _toMarket, uint256 _fromAmount, uint8 _mode) external override returns (uint256 receivedAmount) {
        require(_fromMarket != _toMarket, "FromToken can't be the same as ToToken.");
        receivedAmount = LibOpen._swap(_fromMarket, _toMarket, _fromAmount, _mode);
    }

    function pauseLiquidator() external override authLiquidator() nonReentrant() {
       _pause();
	}
	
	function unpauseLiquidator() external override authLiquidator() nonReentrant() {
       _unpause();   
	}

    function isPausedLiquidator() external view override virtual returns (bool) {
        return _paused();
    }

	modifier authLiquidator() {
    	AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		require(LibOpen._hasAdminRole(ds.superAdmin, ds.superAdminAddress) || LibOpen._hasAdminRole(ds.adminLiquidator, ds.adminLiquidatorAddress), "Admin role does not exist.");
		_;
	}
}