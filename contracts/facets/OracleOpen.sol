// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Pausable.sol";
import "../libraries/LibOpen.sol";


contract OracleOpen is Pausable, IOracleOpen {

	constructor() {
		// AppStorage storage ds = LibOpen.diamondStorage(); 
			// ds.adminOpenOracleAddress = msg.sender;
			// ds.oracle = IOracleOpen(msg.sender);
	}

	receive() external payable {
		payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}
	
	fallback() external payable {
		payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}

	function getLatestPrice(bytes32 _market) external view override returns (uint) {    
		return LibOpen._getLatestPrice(_market);
	}

	function getFairPrice(uint _requestId) external view override returns (uint) {
		return LibOpen._getFairPrice(_requestId);
	}

	function setFairPrice(uint _requestId, uint _fPrice, bytes32 _market, uint _amount) external authOracleOpen() returns(bool){
		LibOpen._fairPrice(_requestId, _fPrice, _market, _amount);
		return true;
	}

	// function liquidationTrigger(address account, uint loanId) external override authOracleOpen() nonReentrant() returns(bool) {
	//     LibOpen._liquidation(account, loanId);
	//     return true;
	// }

	function pauseOracle() external override authOracleOpen() nonReentrant() {
			_pause();
	}
	
	function unpauseOracle() external override authOracleOpen() nonReentrant() {
		_unpause();

	}

	function isPausedOracle() external view override virtual returns (bool) {
			return _paused();
	}

	modifier authOracleOpen() {
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		require(IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.superAdmin, msg.sender) || IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.adminOpenOracle, msg.sender), "ERROR: Not an admin");
		_;
	}

}
