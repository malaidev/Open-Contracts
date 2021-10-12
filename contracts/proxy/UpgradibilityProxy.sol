// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import "./Proxy.sol";
import "../util/IBEP20.sol";
import "../util/Pausable.sol";

contract UpgradibilityProxy is Proxy, Pausable {

    address adminProxyAddress;
    address superAdminAddress;
    // Storage position of the address of the current implementation
    bytes32 private constant implementationPosition = 
        keccak256("UpgradibilityProxy.implementation.address");
    
    // Storage position of the owner of the contract
    bytes32 private constant proxyOwnerPosition = 
        keccak256("UpgradibilityProxy.proxy.owner");
    
    event Upgraded(address indexed implementation);
    constructor(address superAdminAddr_, address _implementation) {
        superAdminAddress = superAdminAddr_;
        adminProxyAddress = msg.sender;
        _setUpgradeabilityOwner(msg.sender);
        _upgradeTo(_implementation);
    }

    function transferProxyOwnership(address _newOwner) 
        public onlyProxyOwner() 
    {
        require(_newOwner != address(0));
        _setUpgradeabilityOwner(_newOwner);
    }
    
    function upgradeTo(address _implementation) 
        public onlyProxyOwner()
    {
        _upgradeTo(_implementation);
    }
    
    function implementation() public override view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }
    
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }
    
    function _setImplementation(address _newImplementation) 
        internal 
    {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }
    
    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }
    
    function _setUpgradeabilityOwner(address _newProxyOwner) 
        internal 
    {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }

    // receive() external payable {
    //     payable(adminProxyAddress).transfer(_msgValue());
    // }
    
    // fallback() external payable {
    //     payable(adminProxyAddress).transfer(_msgValue());
    // }

    function transferAnyERC20(address token_,address recipient_,uint256 value_) external returns(bool) {
        IBEP20(token_).transfer(recipient_, value_);
        return true;
    }

    function pause() external authProxy() nonReentrant() {
       _pause();
	}
	
	function unpause() external authProxy() nonReentrant() {
       _unpause();   
	}

    modifier onlyProxyOwner() {
        require (msg.sender == proxyOwner());
        _;
    }

	modifier authProxy() {
		require(
			msg.sender == adminProxyAddress || 
            msg.sender == superAdminAddress,
			"Only Proxy admin can call this function"
		);
		_;
	}
}