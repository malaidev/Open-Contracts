// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Pausable.sol";
import "../libraries/LibOpen.sol";


contract Reserve is Pausable, IReserve {

    constructor() {
    	// AppStorage storage ds = LibOpen.diamondStorage(); 
        // ds.adminReserveAddress = msg.sender;
        // ds.reserve = IReserve(msg.sender);
    }
    
    receive() external payable {
    	AppStorageOpen storage ds = LibOpen.diamondStorage(); 
        payable(ds.superAdminAddress).transfer(_msgValue());
    }
    
    fallback() external payable {
    	AppStorageOpen storage ds = LibOpen.diamondStorage(); 
        payable(ds.superAdminAddress).transfer(_msgValue());
    }

    function transferAnyBEP20(
        address _token,
        address _recipient,
        uint256 _value) external override nonReentrant returns(bool)   
    {
    	LibOpen._transferAnyBEP20(_token, msg.sender, _recipient, _value);
        return true;
    }

    // function marketReserves(bytes32 _market) external view returns(uint) {
    //     _avblReserves(_market);
    // }
    // function _avblReserves(bytes32 _market) internal view returns(uint) {
    //     return loan.reserves(_market) + deposit.reserves(_market);
    // }

    function avblMarketReserves(bytes32 _market) external view override returns (uint) {
        return LibOpen._avblMarketReserves(_market);
    }

    function marketReserves(bytes32 _market) external view override returns(uint)	{
        return LibOpen._marketReserves(_market);
    }
	
	function marketUtilisation(bytes32 _market) external view override returns(uint)	{
		return LibOpen._marketUtilisation(_market);
	}

    function collateralTransfer(address _account, bytes32 _market, bytes32 _commitment) external override returns (bool){
        AppStorageOpen storage ds = LibOpen.diamondStorage(); 

		bytes32 collateralMarket;
		uint collateralAmount;

		(collateralMarket, collateralAmount) = LibOpen._collateralPointer(_account,_market,_commitment);
		ds.token = IBEP20(LibOpen._connectMarket(collateralMarket));
		ds.token.approveFrom(ds.reserveAddress, address(this), collateralAmount);
        ds.token.transferFrom(ds.reserveAddress, _account, collateralAmount);
        return true;
    }

    modifier authReserve()  {
    	AppStorageOpen storage ds = LibOpen.diamondStorage(); 
        require(IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.superAdmin, msg.sender) || IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.adminReserve, msg.sender), "ERROR: Not an admin");

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