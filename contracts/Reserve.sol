// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./util/Pausable.sol";
import "./libraries/LibDiamond.sol";


contract Reserve is Pausable, IReserve {

    constructor() {
    	// LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
        // ds.adminReserveAddress = msg.sender;
        // ds.reserve = IReserve(msg.sender);
    }
    
    receive() external payable {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
        payable(ds.contractOwner).transfer(_msgValue());
    }
    
    fallback() external payable {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
        payable(ds.contractOwner).transfer(_msgValue());
    }

    function transferAnyBEP20(
        address _token,
        address _recipient,
        uint256 _value) external override nonReentrant returns(bool)   
    {
    	LibDiamond._transferAnyBEP20(_token, msg.sender, _recipient, _value);
        return true;
    }

    // function marketReserves(bytes32 _market) external view returns(uint) {
    //     _avblReserves(_market);
    // }
    // function _avblReserves(bytes32 _market) internal view returns(uint) {
    //     return loan.reserves(_market) + deposit.reserves(_market);
    // }

    function avblMarketReserves(bytes32 _market) external view override returns (uint) {
        return LibDiamond._avblMarketReserves(_market);
    }

    function marketReserves(bytes32 _market) external view override returns(uint)	{
        return LibDiamond._marketReserves(_market);
    }
	
	function marketUtilisation(bytes32 _market) external view override returns(uint)	{
		return LibDiamond._marketUtilisation(_market);
	}

    function collateralTransfer(address _account, bytes32 _market, bytes32 _commitment) external override returns (bool){
        LibDiamond._collateralTransfer(_account, _market, _commitment);
        return true;
    }

    modifier authReserve()  {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 

        require(LibDiamond._hasAdminRole(ds.superAdmin, ds.contractOwner) || LibDiamond._hasAdminRole(ds.adminReserve, ds.adminReserveAddress), "Admin role does not exist.");

        _;
    }

    function pauseReserve() external override authReserve() nonReentrant() {
       _pause();
	}
	
	function unpauseReserve() external override authReserve() nonReentrant() {
       _unpause();   
	}

    function isPausedReserve() external view virtual override returns (bool) {
        return _paused();
    }

}