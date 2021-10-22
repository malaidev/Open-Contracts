// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import "./util/Pausable.sol";
import "./mockup/IMockBep20.sol";

import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/ILoan.sol";

contract OracleOpen is Pausable {

    bytes32 adminOpenOracle;
    address adminOpenOracleAddress;
    address superAdminAddress;
    ILoan loan;
    AggregatorV3Interface internal priceFeed;
    AggregatorV3Interface internal priceBnb;

    constructor(
        address superAdminAddr_
    )
    {
        superAdminAddress = superAdminAddr_;
        adminOpenOracleAddress = msg.sender;
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331); // ETH/USD
        priceBnb = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); // BNB / USD
    }

    receive() external payable {
        payable(adminOpenOracleAddress).transfer(_msgValue());
    }
    
    fallback() external payable {
        payable(adminOpenOracleAddress).transfer(_msgValue());
    }
    
    function transferAnyERC20(address token_,address recipient_,uint256 value_) 
        external returns(bool) 
    {
        IMockBep20(token_).transfer(recipient_, value_);
        return true;
    }

    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getLatestPriceBnb() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceBnb.latestRoundData();
        return price;
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
