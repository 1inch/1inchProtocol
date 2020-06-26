pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ISmartTokenConverter {
    function getReserveRatio(IERC20 token) external view returns (uint32);

    function connectorTokenCount() external view returns (uint256);

    function connectorTokens(uint256 i) external view returns (IERC20);
}
