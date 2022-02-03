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
	
	receive() external payable {
		payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}

	fallback() external payable {
		payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}
	
	function swap(bytes32 _fromMarket, bytes32 _toMarket, uint256 _fromAmount, uint8 _mode) external override returns (uint256 receivedAmount) {
			require(_fromMarket != _toMarket, "FromToken can't be the same as ToToken.");
			receivedAmount = LibOpen._swap(msg.sender, _fromMarket, _toMarket, _fromAmount, _mode);
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
		require(IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.superAdmin, msg.sender) || IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.adminLiquidator, msg.sender), "ERROR: Not an admin");
		_;
	}
}