pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISmartTokenConverter {

    function version() external view returns (uint16);

    function connectors(address) external view returns (uint256, uint32, bool, bool, bool);

    function getReserveRatio(IERC20 token) external view returns (uint256);

    function connectorTokenCount() external view returns (uint256);

    function connectorTokens(uint256 i) external view returns (IERC20);

    function liquidate(uint256 _amount) external;

    function fund(uint256 _amount) external;

    function convert2(IERC20 _fromToken, IERC20 _toToken, uint256 _amount, uint256 _minReturn, address _affiliateAccount, uint256 _affiliateFee) external returns (uint256);

    function convert(IERC20 _fromToken, IERC20 _toToken, uint256 _amount, uint256 _minReturn) external returns (uint256);

}
