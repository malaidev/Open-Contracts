// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;
abstract contract Proxy {

  function implementation() public virtual view returns (address);

  fallback() external payable {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
  receive() external payable {}
  
}