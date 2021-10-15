// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import "./util/Pausable.sol";
import "./util/IBEP20.sol";
import "./interfaces/ITokenList.sol";
import "./interfaces/ILoan.sol";
contract OracleOpen is Pausable {

    bytes32 adminOpenOracle;
    address adminOpenOracleAddress;
    address superAdminAddress;
    ITokenList tokenList;
    ILoan loan;
    uint decimals = 12;

    uint minConsensus = 2;

    struct PriceData{
        uint timestamp;
        uint price;
        bytes32 market;
        uint arrivedPrices;
        mapping(uint => uint) response;
        mapping(address => uint) nest;
    }

    event OffChainRequest (
        string url,
        bytes32 market,
        uint price
    );

    event UpdatedRequest (
        bytes32 market,
        uint price
    );

    mapping(bytes32 => PriceData) latestPrice;

    constructor(
        address superAdminAddr_, 
        address tokenListAddr_
    )
    {
        superAdminAddress = superAdminAddr_;
        adminOpenOracleAddress = msg.sender;
        tokenList = ITokenList(tokenListAddr_);
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
        IBEP20(token_).transfer(recipient_, value_);
        return true;
    }

    function getLatestPrice(bytes32 _market) external view returns (uint256) {
        return latestPrice[_market].price;
    }
    
    function getLatestTimestamp(bytes32 _market) external view returns (uint256) {
        return latestPrice[_market].timestamp;
    }
    
    function newPriceRequest (
        string memory _url,
        bytes32 _market,
        uint _price
    ) external {
        PriceData storage r = latestPrice[_market];
        r.timestamp = block.timestamp;
        r.market = _market;
        r.price = _price;

        emit OffChainRequest (_url, _market, _price);
    }

    function updatedChainRequest (
        bytes32 _market,
        uint _price
    ) external {
        PriceData storage trackRequest = latestPrice[_market];

        //Check if the token is supported. In TokenList Contract.
        require(tokenList.isMarketSupported(trackRequest.market), "Token is not supported.");

        if(trackRequest.nest[msg.sender] == 1){
            trackRequest.nest[msg.sender] = 2;
            
            uint tmpI = trackRequest.arrivedPrices;
            trackRequest.response[tmpI] = _price;
            trackRequest.arrivedPrices = tmpI + 1;
            
            uint currentConsensusCount = 1;
            
            for(uint i = 0; i < tmpI; i++){
                uint a = trackRequest.response[i];
                uint b = _price;

                if(a == b){
                    currentConsensusCount++;
                    if(currentConsensusCount >= minConsensus){
                        trackRequest.price = _price;
                        
                        //Add token to TokenList Contract.
                        tokenList.addTokenSupport(trackRequest.market, decimals, address(tokenList));

                        emit UpdatedRequest (_market, _price);
                    }
                }
            }
        }
    }

    function liquidationTrigger(
        address account, 
        // bytes32 market,
        // bytes32 commitment,
        uint loanId
    ) public
    {
        //Call liquidate() in Loan contract.
        // uint price = latestPrice[market].price;
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
