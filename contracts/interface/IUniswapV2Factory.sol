pragma solidity ^0.5.0;

import "./IUniswapV2Exchange.sol";


interface IUniswapV2Factory {
    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniswapV2Exchange pair);
}
