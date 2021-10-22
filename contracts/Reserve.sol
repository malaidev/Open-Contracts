// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./mockup/IMockBep20.sol";
import "./util/Pausable.sol";
import "./interfaces/ILoan.sol";
import "./interfaces/IDeposit.sol";

contract Reserve is Pausable {
    IDeposit deposit;
    ILoan loan;
    // ILoan loan = ILoan(0xeAc61D9e3224B20104e7F0BAD6a6DB7CaF76659B);
    // IDeposit deposit = IDeposit(0xeAc61D9e3224B20104e7F0BAD6a6DB7CaF76659B);

    IMockBep20 token;

    bytes32 adminReserve;
    address adminReserveAddress;
    address superAdminAddress;

    constructor(address superAdminAddr_, address depositAddr_) {
        superAdminAddress = superAdminAddr_;
        adminReserveAddress = msg.sender;
        deposit = IDeposit(depositAddr_);
    }
    
    receive() external payable {
        payable(adminReserveAddress).transfer(_msgValue());
    }
    
    fallback() external payable {
        payable(adminReserveAddress).transfer(_msgValue());
    }
    
    // function transferAnyERC20(address token_,address _recipient,uint256 _value) external returns(bool) {
    //     IBEP20(token_).transfer(_recipient, _value);
    //     return true;
    // }

    function transferAnyBEP20(
        address token_,
        address _recipient,
        uint256 _value) external nonReentrant  authReserve  returns(bool)   
    {
        token = IMockBep20(token_);
        token.transfer(_recipient, _value);
        return true;
    }

    // function marketReserves(bytes32 _market) external view returns(uint) {
    //     _avblReserves(_market);
    // }
    // function _avblReserves(bytes32 _market) internal view returns(uint) {
    //     return loan.reserves(_market) + deposit.reserves(_market);
    // }

    function avblMarketReserves(bytes32 _market) external view returns (uint)    {
        return _avblMarketReserves(_market);
    }
    function _avblMarketReserves(bytes32 _market) internal view returns (uint) {
        require((_marketReserves(_market) - _marketUtilisation(_market)) >=0, "Mathematical error");
        return _marketReserves(_market) - _marketUtilisation(_market);
    }

	function marketReserves(bytes32 _market) external view returns(uint)	{
		return _marketReserves(_market);
	}

	function _marketReserves(bytes32 _market) internal view returns (uint) {
		return deposit.avblReserves(_market)+loan.avblReserves(_market);
	}
	
	function marketUtilisation(bytes32 _market) external view returns(uint)	{
		return _marketUtilisation(_market);
	}

	function _marketUtilisation(bytes32 _market) internal view returns (uint) {
		return deposit.utilisedReserves(_market) + loan.utilisedReserves(_market);
	}

    function collateralTransfer(address _account, bytes32 _market, bytes32 _commitment) external {

    }

    function setLoanAddress(address loanAddr_) external authReserve {
        loan = ILoan(loanAddr_);
    }

    modifier authReserve()  {
        require(msg.sender == adminReserveAddress || 
            msg.sender == superAdminAddress, 
            "Only Reverse admin can call this function"
        );
        _;
    }

    function pause() external authReserve() nonReentrant() {
       _pause();
	}
	
	function unpause() external authReserve() nonReentrant() {
       _unpause();   
	}

}