pragma solidity ^0.4.18;

/**
 * @title IMCCService
 * @dev MCC Service methods for future MCC Token Service 
 */
interface IMCCService {
    /**
    * @dev Function is called by contributor to refund payments if crowdsale failed to reach soft cap
    */
    function requestCreditInfo(string[] params) external returns (address);
    
        /**
    * @dev Function is called by contributor to refund payments if crowdsale failed to reach soft cap
    */
    function submitMyCredit(string[] params) external;
}