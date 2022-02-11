// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface ILoan {
	// enum STATE {ACTIVE,REPAID}

    function swapLoan(bytes32 _market, bytes32 _commitment, bytes32 _swapMarket) external returns (bool success);
    function swapToLoan(bytes32 _commitment,bytes32 _loanMarket) external returns (bool);
    function withdrawCollateral(bytes32 _market, bytes32 _commitment) external returns (bool);
    // function collateralPointer(address _account, bytes32 _market, bytes32 _commitment) external view returns (bool);
    // function getFairPriceLoan(uint _requestId) external returns (uint);
    function addCollateral(bytes32 _loanMarket,bytes32 _commitment,uint256 _collateralAmount) external returns (bool);
    
    function pauseLoan() external;
    function unpauseLoan() external;
    function isPausedLoan() external view returns (bool);
}
