pragma solidity ^0.5.0;

import "./IUniswapV2Pair.sol";

interface IUniswapV2Pool {
    function addLiquidity(
        IUniswapV2Pair pool,
        uint256[2] calldata amounts,
        uint256 minMintAmount
    )
        external
        returns (uint256);

    function removeLiquidity(
        IUniswapV2Pair pool,
        uint256 burnAmount,
        uint256[2] calldata minReturnAmount
    )
        external
        returns (uint256[2] memory);
}
