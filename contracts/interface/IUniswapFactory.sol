pragma solidity ^0.5.0;

import "./IUniswapExchange.sol";


interface IUniswapFactory {
    function getExchange(IERC20 token) external view returns (IUniswapExchange exchange);

    function getToken(address exchange) external view returns (IERC20 token);
}
