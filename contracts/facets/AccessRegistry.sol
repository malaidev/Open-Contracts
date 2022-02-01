// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "../util/Pausable.sol";
// import "./mockup/IMockBep20.sol";
import "../libraries/LibOpen.sol";

contract AccessRegistry is Pausable, IAccessRegistry {
  
	event AdminRoleDataGranted(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);

	event AdminRoleDataRevoked(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);

	event RoleGranted(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);

	event RoleRevoked(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);
	constructor() {
		// AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		// ds.superAdmin = keccak256("AccessRegistry.admin");
		// LibOpen._addAdminRole(keccak256("AccessRegistry.admin"), ds.contractOwner);
	}
		
	// receive() external payable {
	// 	AppStorageOpen storage ds = LibOpen.diamondStorage(); 
	//     payable(ds.contractOwner).transfer(_msgValue());
	// }

	// fallback() external payable {
	// 	AppStorageOpen storage ds = LibOpen.diamondStorage(); 
	//     payable(ds.contractOwner).transfer(_msgValue());
	// }

	function hasRole(bytes32 role, address account) public view override returns (bool) {
		return LibOpen._hasRole(role, account);
	}

	function addRole(bytes32 role, address account) public override onlyAdmin {
		require(!hasRole(role, account), "Role already exists. Please create a different role");
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		ds._roles[role]._members[account] = true;
		emit RoleGranted(role, account, msg.sender);
	}

	function removeRole(bytes32 role, address account) external override onlyAdmin {
		require(hasRole(role, account), "Role does not exist.");
		revokeRole(role, account);
	}

	function renounceRole(bytes32 role, address account) external override nonReentrant() {
		require(hasRole(role, account), "Role does not exist.");
		require(_msgSender() == account, "Inadequate permissions");

		revokeRole(role, account);
	}

	function revokeRole(bytes32 role, address account) private {
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		ds._roles[role]._members[account] = false;
		emit RoleRevoked(role, account, msg.sender);
	}

	function transferRole(
		bytes32 role,
		address oldAccount,
		address newAccount
	) external override nonReentrant() {
		require(
				hasRole(role, oldAccount) && _msgSender() == oldAccount,
				"Role does not exist."
		);

		revokeRole(role, oldAccount);
		addRole(role, newAccount);
	}

	function hasAdminRole(bytes32 role, address account) public view override returns (bool) {
		return LibOpen._hasAdminRole(role, account);
	}

	function addAdminRole(bytes32 role, address account) public override onlyAdmin {
		require(
				!hasAdminRole(role, account),
				"Role already exists. Please create a different role"
		);
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		ds._adminRoles[role]._adminMembers[account] = true;
		emit AdminRoleDataGranted(role, account, msg.sender);
	}

	function removeAdminRole(bytes32 role, address account) external override onlyAdmin {
		require(hasAdminRole(role, account), "Role does not exist.");
		revokeAdmin(role, account);
	}

	function revokeAdmin(bytes32 role, address account) private {
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		ds._adminRoles[role]._adminMembers[account] = false;
		emit AdminRoleDataRevoked(role, account, msg.sender);
	}

	function adminRoleTransfer(
		bytes32 role,
		address oldAccount,
		address newAccount 
	) external override onlyAdmin
	{
		require(
				hasAdminRole(role, oldAccount),
				"Role already exists. Please create a different role"
		);

		revokeAdmin(role, oldAccount);
		addAdminRole(role, newAccount);
	}

	function adminRoleRenounce(bytes32 role, address account) external override onlyAdmin {
		require(hasAdminRole(role, account), "Role does not exist.");
		require(_msgSender() == account, "Inadequate permissions");

		revokeAdmin(role, account);
	}
	
	modifier onlyAdmin {
		AppStorageOpen storage ds = LibOpen.diamondStorage();
		require(hasAdminRole(ds.superAdmin, ds.superAdminAddress), "ERROR: Not an admin");
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
