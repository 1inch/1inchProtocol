pragma solidity ^0.5.0;

import "./OneSplitBase.sol";
import "./interface/IUniswapV2Pool.sol";
import "./interface/IUniswapV2Pair.sol";


contract OneSplitUniswapV2PoolTokenBase {
    using SafeMath for uint256;

    IUniswapV2Pool constant uniswapPool = IUniswapV2Pool(0x3f6CDd93e4A1c2Df9934Cb90D09040CcFc155F93);

    function isLiquidityPool(IERC20 token) internal view returns (bool) {
        (bool success, bytes memory data) = address(token).staticcall.gas(2000)(
            abi.encode(IUniswapV2Pair(address(token)).factory.selector)
        );
        if (!success) {
            return false;
        }
        bytes memory emptyBytes;
        if (keccak256(data) == keccak256(emptyBytes)) {
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
                    wethToken,
                    amount,
                    parts,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );

                (
                    uint256 returnPoolTokenToAmount,
                    uint256[] memory poolTokenToDistribution
                ) = _getExpectedReturnToUniswapV2PoolToken(
                    wethToken,
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

        uint256[2] memory amounts;
        amounts[0] = amount.div(2);
        amounts[1] = amount.sub(amounts[0]);
        for (uint i = 0; i < 2; i++) {

            if (fromToken == details.tokens[i].token) {
                uint256 liquidity = amounts[i].mul(details.totalSupply).div(details.tokens[i].reserve);
                returnAmount = liquidity > returnAmount ? liquidity : returnAmount;
                continue;
            }

            (uint256 ret, uint256[] memory dist) = this.getExpectedReturn(
                fromToken,
                details.tokens[i].token,
                amounts[i],
                parts,
                flags
            );

            uint256 liquidity = ret.mul(details.totalSupply).div(details.tokens[i].reserve);
            returnAmount = liquidity > returnAmount ? liquidity : returnAmount;

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

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

                uint256 wEthBalanceBefore = wethToken.balanceOf(address(this));

                _swapFromUniswapV2PoolToken(
                    fromToken,
                    wethToken,
                    amount,
                    dist,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );

                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] >> 128;
                }

                uint256 wEthBalanceAfter = wethToken.balanceOf(address(this));

                return _swapToUniswapV2PoolToken(
                    wethToken,
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
        _infiniteApproveIfNeeded(poolToken, address(uniswapPool));

        uint256[2] memory amounts = uniswapPool.removeLiquidity(
            IUniswapV2Pair(address(poolToken)),
                amount,
                [
                    uint256(0),
                    uint256(0)
                ]
        );

        uint256[] memory dist = new uint256[](distribution.length);

        PoolDetails memory details = _getPoolDetails(IUniswapV2Pair(address(poolToken)));
        for (uint i = 0; i < 2; i++) {

            if (toToken == details.tokens[i].token) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            super._swap(
                details.tokens[i].token,
                toToken,
                amounts[i],
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
        uint256[] memory dist = new uint256[](distribution.length);

        distribution = new uint256[](DEXES_COUNT);

        PoolDetails memory details = _getPoolDetails(IUniswapV2Pair(address(poolToken)));

        // will overwritten to liquidity amounts
        uint256[2] memory amounts;
        amounts[0] = amount.div(2);
        amounts[1] = amount.sub(amounts[0]);
        for (uint i = 0; i < 2; i++) {

            _infiniteApproveIfNeeded(details.tokens[i].token, address(uniswapPool));

            if (fromToken == details.tokens[i].token) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            super._swap(
                fromToken,
                details.tokens[i].token,
                amounts[i],
                dist,
                flags
            );

            amounts[i] = details.tokens[i].token.universalBalanceOf(address(this));
        }

        uniswapPool.addLiquidity(IUniswapV2Pair(address(poolToken)), amounts, 0);

        for (uint i = 0; i < 2; i++) {
            details.tokens[i].token.universalTransfer(
                msg.sender,
                details.tokens[i].token.universalBalanceOf(address(this))
            );
        }
    }
}
