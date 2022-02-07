
// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {AppStorageOpen} from "../libraries/AppStorageOpen.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
// It is exapected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract DiamondInit {    
    AppStorageOpen internal s;

    // You can add parameters to this function in order to pass in 
    // data to set your own state variables
    function init(address account, address reserveAddr, address accessRegistry) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;

        s.superAdmin = 0x72b5b8ca10202b2492d7537bf1f6abcda23a980f7acf51a1ec8a0ce96c7d7ca8; //keccak256("AccessRegistry.admin");
        s.superAdminAddress = accessRegistry;
        s.reserveAddress = reserveAddr;
        s.upgradeAdmin = account;
        ds.upgradeAdmin = account;
        
    }
}
