// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import "./util/Pausable.sol";
// import "./mockup/IMockBep20.sol";
import "./util/IBEP20.sol";

import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/ILoan.sol";

contract OracleOpen is Pausable {

    bytes32 adminOpenOracle;
    address adminOpenOracleAddress;
    address superAdminAddress;
    ILoan loan;

    constructor(address superAdminAddr_) {
        superAdminAddress = superAdminAddr_;
        adminOpenOracleAddress = msg.sender;
    }

    receive() external payable {
        payable(adminOpenOracleAddress).transfer(_msgValue());
    }
    
    fallback() external payable {
        payable(adminOpenOracleAddress).transfer(_msgValue());
    }
    
    function transferAnyBEP20(address token_,address recipient_,uint256 value_) 
        external onlyAdmin returns(bool) 
    {
        IBEP20(token_).transfer(recipient_, value_);
        return true;
    }

    function getLatestPrice(address _addrMarket) public view returns (uint) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(_addrMarket).latestRoundData();
        return uint256(price);
    }

    function liquidationTrigger(
        address account, 
        uint loanId
    ) public
    {
        loan.liquidation(account, loanId);
    }

    function pause() external onlyAdmin() nonReentrant() {
       _pause();
	}
	
	function unpause() external onlyAdmin() nonReentrant() {
       _unpause();   
	}

    function setLoanAddress(address _loanAddress) public onlyAdmin {
        loan = ILoan(_loanAddress);
    }

    modifier onlyAdmin() {
        require(msg.sender == adminOpenOracleAddress || 
            msg.sender == superAdminAddress,
            "Only Oracle admin can call this function"
        );
        _;
    }
}
