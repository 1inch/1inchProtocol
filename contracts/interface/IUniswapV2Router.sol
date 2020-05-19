pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Router {
    function addLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint256[2] memory amounts, uint liquidity);

    function removeLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint256[2] memory);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        IERC20[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, IERC20[] calldata path) external view returns (uint[] memory amounts);
}
