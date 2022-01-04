// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./util/Pausable.sol";
// import "./mockup/IMockBep20.sol";
import "./libraries/LibDiamond.sol";
contract AccessRegistry is Pausable, IAccessRegistry {
    
    constructor() {
    	// LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
        // ds.superAdmin = keccak256("AccessRegistry.admin");
        // LibDiamond._addAdminRole(keccak256("AccessRegistry.admin"), ds.contractOwner);
    }
    
    receive() external payable {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
        payable(ds.contractOwner).transfer(_msgValue());
    }
    
    fallback() external payable {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
        payable(ds.contractOwner).transfer(_msgValue());
    }

    function hasRole(bytes32 role, address account) external view override returns (bool) {
        return LibDiamond._hasRole(role, account);
    }

    function addRole(bytes32 role, address account) external override onlyAdmin {

        require(
            !LibDiamond._hasRole(role, account),
            "Role already exists. Please create a different role"
        );
        LibDiamond._addRole(role, account);
    }

    function removeRole(bytes32 role, address account) external override onlyAdmin {
        require(LibDiamond._hasRole(role, account), "Role does not exist.");

        LibDiamond._revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) external override nonReentrant() {
        require(LibDiamond._hasRole(role, account), "Role does not exist.");
        require(_msgSender() == account, "Inadequate permissions");

        LibDiamond._revokeRole(role, account);
    }

    function transferRole(
        bytes32 role,
        address oldAccount,
        address newAccount
    ) external override nonReentrant() {
        require(
            LibDiamond._hasRole(role, oldAccount) && _msgSender() == oldAccount,
            "Role does not exist."
        );

        LibDiamond._revokeRole(role, oldAccount);
        LibDiamond._addRole(role, newAccount);
    }

    function hasAdminRole(bytes32 role, address account)
        external
        view
        override 
        returns (bool)
    {
        return LibDiamond._hasAdminRole(role, account);
    }

    function addAdminRole(bytes32 role, address account) external override onlyAdmin {
        require(
            !LibDiamond._hasAdminRole(role, account),
            "Role already exists. Please create a different role"
        );
        LibDiamond._addAdminRole(role, account);
    }

    function removeAdminRole(bytes32 role, address account) external override onlyAdmin {
        require(LibDiamond._hasAdminRole(role, account), "Role does not exist.");
        LibDiamond._revokeAdmin(role, account);
    }

    function adminRoleTransfer(
        bytes32 role,
        address oldAccount,
        address newAccount 
    ) external override onlyAdmin
    {
        require(
            LibDiamond._hasAdminRole(role, oldAccount),
            "Role already exists. Please create a different role"
        );

        LibDiamond._revokeAdmin(role, oldAccount);
        LibDiamond._addAdminRole(role, newAccount);
    }

    function adminRoleRenounce(bytes32 role, address account) external override onlyAdmin {
        require(LibDiamond._hasAdminRole(role, account), "Role does not exist.");
        require(_msgSender() == account, "Inadequate permissions");

        LibDiamond._revokeAdmin(role, account);
    }
    
    modifier onlyAdmin {
    	LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(LibDiamond._hasAdminRole(ds.superAdmin, ds.contractOwner), "Admin role does not exist.");
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
