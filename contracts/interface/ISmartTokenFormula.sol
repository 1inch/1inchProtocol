pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ISmartTokenFormula {
    function _calculateLiquidateReturn(
        uint256 supply,
        uint256 reserveBalance,
        uint32 totalRatio,
        uint256 amount
    ) external view returns (uint256);

    function _calculatePurchaseReturn(
        uint256 supply,
        uint256 reserveBalance,
        uint32 totalRatio,
        uint256 amount
    ) external view returns (uint256);
}
