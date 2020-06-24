pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IBalancerPool {
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
    // struct PairInfo {
    //     uint80 weight1;
    //     uint80 weight2;
    //     uint80 swapFee;
    // }

    // function pairs(address pool, bytes32 key) external view returns(PairInfo memory);
    function pools(bytes32 key) external view returns(address[] memory);
    function poolsLimited(bytes32 key, uint256 limit) external view returns(address[] memory result);

    function getPoolReturn(
        address pool,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) external view returns(uint256);

    function getPoolReturns(
        address pool,
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] calldata amounts
    ) external view returns(uint256[] memory returnAmounts);
}


library BalancerRegistryHelper {
    function createKey(IERC20 token1, IERC20 token2) internal pure returns(bytes32) {
        return bytes32(
            (uint256(uint128((token1 < token2) ? address(token1) : address(token2))) << 128) |
            (uint256(uint128((token1 < token2) ? address(token2) : address(token1))))
        );
    }
}
