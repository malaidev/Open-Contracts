// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "../util/Pausable.sol";
// import "./mockup/IMockBep20.sol";
import "../libraries/LibOpen.sol";

contract AccessRegistry is Pausable, IAccessRegistry {
    
    constructor() {
    	// AppStorage storage ds = LibOpen.diamondStorage(); 
        // ds.superAdmin = keccak256("AccessRegistry.admin");
        // LibOpen._addAdminRole(keccak256("AccessRegistry.admin"), ds.contractOwner);
    }
    
    // receive() external payable {
    // 	AppStorage storage ds = LibOpen.diamondStorage(); 
    //     payable(ds.contractOwner).transfer(_msgValue());
    // }
    
    // fallback() external payable {
    // 	AppStorage storage ds = LibOpen.diamondStorage(); 
    //     payable(ds.contractOwner).transfer(_msgValue());
    // }

    function hasRole(bytes32 role, address account) external view override returns (bool) {
        return LibOpen._hasRole(role, account);
    }

    function addRole(bytes32 role, address account) external override onlyAdmin {

        require(
            !LibOpen._hasRole(role, account),
            "Role already exists. Please create a different role"
        );
        LibOpen._addRole(role, account);
    }

    function removeRole(bytes32 role, address account) external override onlyAdmin {
        require(LibOpen._hasRole(role, account), "Role does not exist.");

        LibOpen._revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) external override nonReentrant() {
        require(LibOpen._hasRole(role, account), "Role does not exist.");
        require(_msgSender() == account, "Inadequate permissions");

        LibOpen._revokeRole(role, account);
    }

    function transferRole(
        bytes32 role,
        address oldAccount,
        address newAccount
    ) external override nonReentrant() {
        require(
            LibOpen._hasRole(role, oldAccount) && _msgSender() == oldAccount,
            "Role does not exist."
        );

        LibOpen._revokeRole(role, oldAccount);
        LibOpen._addRole(role, newAccount);
    }

    function hasAdminRole(bytes32 role, address account)
        external
        view
        override 
        returns (bool)
    {
        return LibOpen._hasAdminRole(role, account);
    }

    function addAdminRole(bytes32 role, address account) external override onlyAdmin {
        require(
            !LibOpen._hasAdminRole(role, account),
            "Role already exists. Please create a different role"
        );
        LibOpen._addAdminRole(role, account);
    }

    function removeAdminRole(bytes32 role, address account) external override onlyAdmin {
        require(LibOpen._hasAdminRole(role, account), "Role does not exist.");
        LibOpen._revokeAdmin(role, account);
    }

    function adminRoleTransfer(
        bytes32 role,
        address oldAccount,
        address newAccount 
    ) external override onlyAdmin
    {
        require(
            LibOpen._hasAdminRole(role, oldAccount),
            "Role already exists. Please create a different role"
        );

        LibOpen._revokeAdmin(role, oldAccount);
        LibOpen._addAdminRole(role, newAccount);
    }

    function adminRoleRenounce(bytes32 role, address account) external override onlyAdmin {
        require(LibOpen._hasAdminRole(role, account), "Role does not exist.");
        require(_msgSender() == account, "Inadequate permissions");

        LibOpen._revokeAdmin(role, account);
    }
    
    modifier onlyAdmin {
    	AppStorage storage ds = LibOpen.diamondStorage();
        require(LibOpen._hasAdminRole(ds.superAdmin, ds.superAdminAddress), "Admin role does not exist.");
        _;
    }

    function pauseAccessRegistry() external override onlyAdmin() nonReentrant() {                                                                                                  
       _pause();
	}
	
	function unpauseAccessRegistry() external override onlyAdmin() nonReentrant() {
       _unpause();   
	}

    function isPausedAccessRegistry() external view override virtual returns (bool) {                                                                                                                                                                                                                                                               
        return _paused();
    }

}
