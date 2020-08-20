// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IUniswapV1Factory {
    function getExchange(IERC20 token) external view returns (IUniswapV1Exchange exchange);
}

interface IUniswapV1Exchange {
    function getEthToTokenInputPrice(uint256 ethSold) external view returns (uint256 tokensBought);
    function getTokenToEthInputPrice(uint256 tokensSold) external view returns (uint256 ethBought);

    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline)
        external payable returns (uint256 tokensBought);
    function tokenToEthSwapInput(uint256 tokensSold, uint256 minEth, uint256 deadline)
        external returns (uint256 ethBought);
}
