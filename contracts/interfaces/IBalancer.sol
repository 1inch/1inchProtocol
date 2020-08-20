// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IBalancerPool {
    function getSwapFee() external view returns (uint256 balance);
    function getDenormalizedWeight(IERC20 token) external view returns (uint256 balance);
    function getBalance(IERC20 token) external view returns (uint256 balance);

    function swapExactAmountIn(
        IERC20 tokenIn,
        uint256 tokenAmountIn,
        IERC20 tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    )
        external
        returns (uint256 tokenAmountOut, uint256 spotPriceAfter);
}

interface IBalancerRegistry {
    // Get info about pool pair for 1 SLOAD
    function getPairInfo(address pool, IERC20 fromToken, IERC20 destToken)
        external view returns(uint256 weight1, uint256 weight2, uint256 swapFee);

    // Pools
    function checkAddedPools(address pool)
        external view returns(bool);
    function getAddedPoolsLength()
        external view returns(uint256);
    function getAddedPools()
        external view returns(address[] memory);
    function getAddedPoolsWithLimit(uint256 offset, uint256 limit)
        external view returns(address[] memory result);

    // Tokens
    function getAllTokensLength()
        external view returns(uint256);
    function getAllTokens()
        external view returns(address[] memory);
    function getAllTokensWithLimit(uint256 offset, uint256 limit)
        external view returns(address[] memory result);

    // Pairs
    function getPoolsLength(IERC20 fromToken, IERC20 destToken)
        external view returns(uint256);
    function getPools(IERC20 fromToken, IERC20 destToken)
        external view returns(IBalancerPool[] memory);
    function getPoolsWithLimit(IERC20 fromToken, IERC20 destToken, uint256 offset, uint256 limit)
        external view returns(IBalancerPool[] memory result);
    function getBestPools(IERC20 fromToken, IERC20 destToken)
        external view returns(IBalancerPool[] memory pools);
    function getBestPoolsWithLimit(IERC20 fromToken, IERC20 destToken, uint256 limit)
        external view returns(IBalancerPool[] memory pools);

    // Get swap rates
    function getPoolReturn(address pool, IERC20 fromToken, IERC20 destToken, uint256 amount)
        external view returns(uint256);
    function getPoolReturns(address pool, IERC20 fromToken, IERC20 destToken, uint256[] calldata amounts)
        external view returns(uint256[] memory result);

    // Add and update registry
    function addPool(address pool) external returns(uint256 listed);
    function addPools(address[] calldata pools) external returns(uint256[] memory listed);
    function updatedIndices(address[] calldata tokens, uint256 lengthLimit) external;
}

