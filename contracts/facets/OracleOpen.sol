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

    function getLatestPrice(bytes32 _market) external view override returns (uint) {    
        return LibOpen._getLatestPrice(_market);
    }

    function getFairPrice(uint _requestId) external view override returns (uint) {
        return LibOpen._getFairPrice(_requestId);
    }

    function setFairPrice(uint _requestId, uint _fPrice, bytes32 _market, uint _amount) external {
        LibOpen._fairPrice(_requestId, _fPrice, _market, _amount);
    }

    function liquidationTrigger(address account, uint loanId) external override onlyAdmin() nonReentrant() returns(bool) {
        LibOpen._liquidation(account, loanId);
        return true;
    }

    function pauseOracle() external override onlyAdmin() nonReentrant() {
       _pause();
	}
	
	function unpauseOracle() external override onlyAdmin() nonReentrant() {
       _unpause();   
	}

    function isPausedOracle() external view override virtual returns (bool) {
        return _paused();
    }

    modifier onlyAdmin() {
    	AppStorageOpen storage ds = LibOpen.diamondStorage(); 
        require(LibOpen._hasAdminRole(ds.superAdmin, ds.superAdminAddress) || LibOpen._hasAdminRole(ds.adminOpenOracle, ds.adminOpenOracleAddress), "Admin role does not exist.");

        _;
    }
}
