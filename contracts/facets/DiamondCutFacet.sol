
// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

contract DiamondCutFacet is IDiamondCut {
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.enforceIsupgradeAdmin();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}
