// SPDX-License-Identifier: MIT

pragma solidity >=0.8.6 <0.9.0;

import "./Context.sol";

abstract contract Pausable is Context {

	bool isReentrant = false;
    bool private isPaused;
    event PauseState(address indexed _pauser, bool isPaused);


    constructor() {
        isPaused = false;
    }

    function paused() public view virtual returns (bool) {
        return isPaused;
    }
    
    function pauseState() public view returns (string memory) {
       if (isPaused == true) {
           return "Contract is paused. Token transfers are temporarily disabled.";
       }
       return "Contract is not paused";
   }

    modifier whenNotPaused() {
        require(!paused(), "Paused status");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Not paused status");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        isPaused = true;
        emit PauseState(_msgSender(), true);
    }

    function _unpause() internal virtual whenPaused {
        isPaused = false;
        emit PauseState(_msgSender(), false);
    }

    function _checkPauseState() internal view {
        require(isPaused == false,"The contract is paused. Transfer functions are temporarily disabled");
    }

    modifier nonReentrant() {
		require(isReentrant == false, "Re-entrant alert!");
		isReentrant = true;
		_;
		isReentrant = false;
	}
}