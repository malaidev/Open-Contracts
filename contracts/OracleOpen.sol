// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import "./util/Pausable.sol";
import "./libraries/LibDiamond.sol";
import "hardhat/console.sol";

contract OracleOpen is Pausable, IOracleOpen {

    constructor() {
    	// LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
        // ds.adminOpenOracleAddress = msg.sender;
        // ds.oracle = IOracleOpen(msg.sender);
    }

    function getLatestPrice(address _addrMarket) external view returns (uint) {    
        return LibDiamond._getLatestPrice(_addrMarket);
    }

    function liquidationTrigger(
        address account, 
        uint loanId
    ) external onlyAdmin() nonReentrant()
    {
        LibDiamond._liquidation(account, loanId);
    }

    function pauseOracle() external onlyAdmin() nonReentrant() {
       _pause();
	}
	
	function unpauseOracle() external onlyAdmin() nonReentrant() {
       _unpause();   
	}

    function isPausedOracle() external view virtual returns (bool) {
        return _paused();
    }

    modifier onlyAdmin() {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
        require(msg.sender == ds.contractOwner, 
            "Only Oracle admin can call this function"
        );
        _;
    }
}
