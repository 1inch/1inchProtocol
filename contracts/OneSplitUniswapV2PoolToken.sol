pragma solidity ^0.5.0;

import "./OneSplitBase.sol";
import "./interface/IUniswapV2Router.sol";
import "./interface/IUniswapV2Pair.sol";


library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


contract OneSplitUniswapV2PoolTokenBase {
    using SafeMath for uint256;

    IUniswapV2Router constant uniswapRouter = IUniswapV2Router(0xf164fC0Ec4E93095b804a4795bBe1e041497b92a);

    function isLiquidityPool(IERC20 token) internal view returns (bool) {
        (bool success, bytes memory data) = address(token).staticcall.gas(2000)(
            abi.encode(IUniswapV2Pair(address(token)).factory.selector)
        );
        if (!success || data.length == 0) {
            return false;
        }
        return abi.decode(data, (address)) == 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    }

    struct TokenInfo {
        IERC20 token;
        uint256 reserve;
    }

    struct PoolDetails {
        TokenInfo[2] tokens;
        uint256 totalSupply;
    }

    function _getPoolDetails(IUniswapV2Pair pair) internal view returns (PoolDetails memory details) {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        details.tokens[0] = TokenInfo({
            token: pair.token0(),
            reserve: reserve0
            });
        details.tokens[1] = TokenInfo({
            token: pair.token1(),
            reserve: reserve1
            });

        details.totalSupply = IERC20(address(pair)).totalSupply();
    }

    function _calcRebalanceAmount(
        uint256 leftover,
        uint256 balanceOfLeftoverAsset,
        uint256 secondAssetBalance
    ) internal pure returns (uint256) {

        return Math.sqrt(
            3988000 * leftover * balanceOfLeftoverAsset +
            3988009 * balanceOfLeftoverAsset * balanceOfLeftoverAsset -
            9 * balanceOfLeftoverAsset * balanceOfLeftoverAsset / (secondAssetBalance - 1)
        ) / 1994 - balanceOfLeftoverAsset * 1997 / 1994;
    }

}


contract OneSplitUniswapV2PoolTokenView is OneSplitViewWrapBase, OneSplitUniswapV2PoolTokenBase {

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }


        if (!flags.check(FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN)) {
            bool isPoolTokenFrom = isLiquidityPool(fromToken);
            bool isPoolTokenTo = isLiquidityPool(toToken);

            if (isPoolTokenFrom && isPoolTokenTo) {
                (
                    uint256 returnWETHAmount,
                    uint256[] memory poolTokenFromDistribution
                ) = _getExpectedReturnFromUniswapV2PoolToken(
                    fromToken,
                    weth,
                    amount,
                    parts,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );

                (
                    uint256 returnPoolTokenToAmount,
                    uint256[] memory poolTokenToDistribution
                ) = _getExpectedReturnToUniswapV2PoolToken(
                    weth,
                    toToken,
                    returnWETHAmount,
                    parts,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );

                for (uint i = 0; i < poolTokenToDistribution.length; i++) {
                    poolTokenFromDistribution[i] |= poolTokenToDistribution[i] << 128;
                }

                return (returnPoolTokenToAmount, poolTokenFromDistribution);
            }

            if (isPoolTokenFrom) {
                return _getExpectedReturnFromUniswapV2PoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );
            }

            if (isPoolTokenTo) {
                return _getExpectedReturnToUniswapV2PoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );
            }
        }

        return super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            flags
        );
    }

    function _getExpectedReturnFromUniswapV2PoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        PoolDetails memory details = _getPoolDetails(IUniswapV2Pair(address(poolToken)));

        for (uint i = 0; i < 2; i++) {

            uint256 exchangeAmount = amount
                .mul(details.tokens[i].reserve)
                .div(details.totalSupply);

            if (toToken == details.tokens[i].token) {
                returnAmount = returnAmount.add(exchangeAmount);
                continue;
            }

            (uint256 ret, uint256[] memory dist) = this.getExpectedReturn(
                details.tokens[i].token,
                toToken,
                exchangeAmount,
                parts,
                flags
            );

            returnAmount = returnAmount.add(ret);
            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        return (returnAmount, distribution);
    }

    function _getExpectedReturnToUniswapV2PoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        PoolDetails memory details = _getPoolDetails(IUniswapV2Pair(address(poolToken)));

        // will overwritten to liquidity amounts
        uint256[2] memory amounts;
        amounts[0] = amount.div(2);
        amounts[1] = amount.sub(amounts[0]);
        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < 2; i++) {

            if (fromToken == details.tokens[i].token) {
                continue;
            }

            (amounts[i], dist) = this.getExpectedReturn(
                fromToken,
                details.tokens[i].token,
                amounts[i],
                parts,
                flags
            );

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        uint256 possibleLiquidity0 = amounts[0].mul(details.totalSupply).div(details.tokens[0].reserve);
        returnAmount = Math.min(
            possibleLiquidity0,
            amounts[1].mul(details.totalSupply).div(details.tokens[1].reserve)
        );

        uint256 leftoverIndex = possibleLiquidity0 > returnAmount ? 0 : 1;
        IERC20[] memory path = new IERC20[](2);
        path[0] = details.tokens[leftoverIndex].token;
        path[1] = details.tokens[1 - leftoverIndex].token;

        uint256 optimalAmount = amounts[1 - leftoverIndex].mul(
            details.tokens[leftoverIndex].reserve
        ).div(details.tokens[1 - leftoverIndex].reserve);

        IERC20 _poolToken = poolToken; // stack too deep
        uint256 exchangeAmount = _calcRebalanceAmount(
            amounts[leftoverIndex].sub(optimalAmount),
            path[0].balanceOf(address(_poolToken)).add(optimalAmount),
            path[1].balanceOf(address(_poolToken)).add(amounts[1 - leftoverIndex])
        );

        (bool success, bytes memory data) = address(uniswapRouter).staticcall.gas(500000)(
            abi.encodeWithSelector(
                uniswapRouter.getAmountsOut.selector,
                exchangeAmount,
                path
            )
        );

        if (!success) {
            return (
                returnAmount,
                distribution
            );
        }

        uint256[] memory amountsOutAfterSwap = abi.decode(data, (uint256[]));

        uint256 _addedLiquidity = returnAmount; // stack too deep
        PoolDetails memory _details = details; // stack too deep
        returnAmount = _addedLiquidity.add(
            amountsOutAfterSwap[1] // amountOut after swap
                .mul(_details.totalSupply.add(_addedLiquidity))
                .div(_details.tokens[leftoverIndex].reserve.sub(amountsOutAfterSwap[1]))
        );

        return (
            returnAmount,
            distribution
        );
    }

}


contract OneSplitUniswapV2PoolToken is OneSplitBaseWrap, OneSplitUniswapV2PoolTokenBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken == toToken) {
            return;
        }

        if (!flags.check(FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN)) {
            bool isPoolTokenFrom = isLiquidityPool(fromToken);
            bool isPoolTokenTo = isLiquidityPool(toToken);

            if (isPoolTokenFrom && isPoolTokenTo) {
                uint256[] memory dist = new uint256[](distribution.length);
                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] & ((1 << 128) - 1);
                }

                uint256 wEthBalanceBefore = weth.balanceOf(address(this));

                _swapFromUniswapV2PoolToken(
                    fromToken,
                    weth,
                    amount,
                    dist,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );

                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] >> 128;
                }

                uint256 wEthBalanceAfter = weth.balanceOf(address(this));

                return _swapToUniswapV2PoolToken(
                    weth,
                    toToken,
                    wEthBalanceAfter.sub(wEthBalanceBefore),
                    dist,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );
            }

            if (isPoolTokenFrom) {
                return _swapFromUniswapV2PoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );
            }

            if (isPoolTokenTo) {
                return _swapToUniswapV2PoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );
            }
        }

        return super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            flags
        );
    }

    function _swapFromUniswapV2PoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        _infiniteApproveIfNeeded(poolToken, address(uniswapRouter));

        IERC20 [2] memory tokens = [
            IUniswapV2Pair(address(poolToken)).token0(),
            IUniswapV2Pair(address(poolToken)).token1()
        ];

        uint256[2] memory amounts = uniswapRouter.removeLiquidity(
            tokens[0],
            tokens[1],
            amount,
            uint256(0),
            uint256(0),
            address(this),
            now.add(1800)
        );

        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < 2; i++) {

            if (toToken == tokens[i]) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            this.swap(
                tokens[i],
                toToken,
                amounts[i],
                0,
                dist,
                flags
            );
        }
    }

    function _swapToUniswapV2PoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        IERC20 [2] memory tokens = [
            IUniswapV2Pair(address(poolToken)).token0(),
            IUniswapV2Pair(address(poolToken)).token1()
        ];

        // will overwritten to liquidity amounts
        uint256[2] memory amounts;
        amounts[0] = amount.div(2);
        amounts[1] = amount.sub(amounts[0]);
        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < 2; i++) {

            _infiniteApproveIfNeeded(tokens[i], address(uniswapRouter));

            if (fromToken == tokens[i]) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            this.swap(
                fromToken,
                tokens[i],
                amounts[i],
                0,
                dist,
                flags
            );

            amounts[i] = tokens[i].universalBalanceOf(address(this));
        }

        (uint256[2] memory redeemAmounts, ) = uniswapRouter.addLiquidity(
            tokens[0],
            tokens[1],
            amounts[0],
            amounts[1],
            uint256(0),
            uint256(0),
            address(this),
            now.add(1800)
        );

        if (
            redeemAmounts[0] == amounts[0] &&
            redeemAmounts[1] == amounts[1]
        ) {
            return;
        }

        uint256 leftoverIndex = amounts[0] != redeemAmounts[0] ? 0 : 1;
        IERC20[] memory path = new IERC20[](2);
        path[0] = tokens[leftoverIndex];
        path[1] = tokens[1 - leftoverIndex];

        uint256 exchangeAmount = _calcRebalanceAmount(
            amounts[leftoverIndex].sub(redeemAmounts[leftoverIndex]),
            path[0].balanceOf(address(poolToken)),
            path[1].balanceOf(address(poolToken))
        );

        (bool success, bytes memory data) = address(uniswapRouter).call.gas(1000000)(
            abi.encodeWithSelector(
                uniswapRouter.swapExactTokensForTokens.selector,
                exchangeAmount,
                uint256(0),
                path,
                address(this),
                now.add(1800)
            )
        );

        if (!success) {
            return;
        }

        uint256[] memory amountsOut = abi.decode(data, (uint256[]));

        address(uniswapRouter).call.gas(1000000)(
            abi.encodeWithSelector(
                uniswapRouter.addLiquidity.selector,
                tokens[0],
                tokens[1],
                amountsOut[leftoverIndex],
                amountsOut[1 - leftoverIndex],
                uint256(0),
                uint256(0),
                address(this),
                now.add(1800)
            )
        );
    }
}
