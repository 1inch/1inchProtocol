pragma solidity ^0.5.0;pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISmartTokenConverter {

    struct Reserve {
        uint256 virtualBalance;         // reserve virtual balance
        uint32 ratio;                   // reserve ratio, represented in ppm, 1-1000000
        bool isVirtualBalanceEnabled;   // true if virtual balance is enabled, false if not
        bool isSaleEnabled;             // is sale of the reserve token enabled, can be set by the owner
        bool isSet;                     // used to tell if the mapping element is defined
    }

    function version() external view returns (uint16);

    function reserves(address) external view returns (Reserve memory);

    function getReserveRatio(IERC20 token) external view returns (uint256);

    function connectorTokenCount() external view returns (uint256);

    function connectorTokens(uint256 i) external view returns (IERC20);

    function liquidate(uint256 _amount) external;

    function fund(uint256 _amount) external;

    function convert2(IERC20 _fromToken, IERC20 _toToken, uint256 _amount, uint256 _minReturn, address _affiliateAccount, uint256 _affiliateFee) external returns (uint256);

    function convert(IERC20 _fromToken, IERC20 _toToken, uint256 _amount, uint256 _minReturn) external returns (uint256);

}
