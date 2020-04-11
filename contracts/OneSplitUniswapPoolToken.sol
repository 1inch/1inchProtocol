pragma solidity ^0.5.0;

import "./interface/IUniswapExchange.sol";
import "./interface/IUniswapFactory.sol";
import "./OneSplitBase.sol";


contract OneSplitUniswapPoolTokenBase {
    using SafeMath for uint256;

    IUniswapFactory uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);

    function isLiquidityPool(IERC20 token) internal view returns (bool) {
        return address(uniswapFactory.getToken(address(token))) != address(0);
    }

}

contract OneSplitUniswapPoolTokenView is OneSplitBaseView, OneSplitUniswapPoolTokenBase {

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        internal
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }


        if (!disableFlags.check(FLAG_DISABLE_UNISWAP_POOL_TOKEN)) {
            bool isPoolTokenFrom = isLiquidityPool(fromToken);
            bool isPoolTokenTo = isLiquidityPool(toToken);

            if (isPoolTokenFrom && isPoolTokenTo) {
                (
                    uint256 returnETHAmount,
                    uint256[] memory poolTokenFromDistribution
                ) = _getExpectedReturnFromPoolToken(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    parts,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );

                (
                    uint256 returnPoolTokenToAmount,
                    uint256[] memory poolTokenToDistribution
                ) = _getExpectedReturnToPoolToken(
                    ETH_ADDRESS,
                    toToken,
                    returnETHAmount,
                    parts,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );

                for (uint i = 0; i < poolTokenToDistribution.length; i++) {
                    poolTokenFromDistribution[i] |= poolTokenToDistribution[i] << 128;
                }

                return (returnPoolTokenToAmount, poolTokenFromDistribution);
            }

            if (isPoolTokenFrom) {
                return _getExpectedReturnFromPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );
            }

            if (isPoolTokenTo) {
                return _getExpectedReturnToPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );
            }
        }

        return super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );
    }

    function _getExpectedReturnFromPoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        private
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {

        distribution = new uint256[](DEXES_COUNT);

        IERC20 uniswapToken = uniswapFactory.getToken(address(poolToken));

        uint256 totalSupply = poolToken.totalSupply();

        uint256 ethReserve = address(poolToken).balance;
        uint256 ethAmount = amount.mul(ethReserve).div(totalSupply);

        if (!toToken.isETH()) {
            (uint256 ret, uint256[] memory dist) = getExpectedReturn(
                ETH_ADDRESS,
                toToken,
                ethAmount,
                parts,
                disableFlags
            );

            returnAmount = returnAmount.add(ret);
            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j];
            }
        } else {
            returnAmount = returnAmount.add(ethAmount);
        }

        uint256 tokenReserve = uniswapToken.balanceOf(address(poolToken));
        uint256 exchangeTokenAmount = amount.mul(tokenReserve).div(totalSupply);

        if (toToken != uniswapToken) {
            (uint256 ret, uint256[] memory dist) = getExpectedReturn(
                uniswapToken,
                toToken,
                exchangeTokenAmount,
                parts,
                disableFlags
            );

            returnAmount = returnAmount.add(ret);
            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << 8;
            }
        } else {
            returnAmount = returnAmount.add(exchangeTokenAmount);
        }

        return (returnAmount, distribution);
    }

    function _getExpectedReturnToPoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        private
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {

        distribution = new uint256[](DEXES_COUNT);

        IERC20 uniswapToken = uniswapFactory.getToken(address(poolToken));

        uint256 totalSupply = poolToken.totalSupply();

        uint256 ethReserve = address(poolToken).balance;
        uint256 partAmountForEth = amount.div(2);

        if (!fromToken.isETH()) {
            (uint256 ret, uint256[] memory dist) = getExpectedReturn(
                fromToken,
                ETH_ADDRESS,
                partAmountForEth,
                parts,
                disableFlags
            );

            returnAmount = returnAmount.add(
                ret.mul(totalSupply).div(ethReserve)
            );
            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j];
            }
        } else {
            returnAmount = returnAmount.add(
                partAmountForEth.mul(totalSupply).div(ethReserve)
            );
        }

        uint256 tokenReserve = uniswapToken.balanceOf(address(poolToken));
        uint256 partAmountForToken = amount.sub(partAmountForEth);

        if (fromToken != uniswapToken) {
            (uint256 ret, uint256[] memory dist) = getExpectedReturn(
                fromToken,
                uniswapToken,
                partAmountForToken,
                parts,
                disableFlags
            );

            returnAmount = returnAmount.add(
                ret.mul(totalSupply).div(tokenReserve)
            );
            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << 8;
            }
        } else {
            returnAmount = returnAmount.add(
                partAmountForToken.mul(totalSupply).div(tokenReserve)
            );
        }

        return (returnAmount, distribution);
    }

}


contract OneSplitUniswapPoolToken is OneSplitBase, OneSplitUniswapPoolTokenBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) internal {
        if (fromToken == toToken) {
            return;
        }

        if (!disableFlags.check(FLAG_DISABLE_UNISWAP_POOL_TOKEN)) {
            bool isPoolTokenFrom = isLiquidityPool(fromToken);
            bool isPoolTokenTo = isLiquidityPool(toToken);

            if (isPoolTokenFrom && isPoolTokenTo) {
                uint256[] memory dist = new uint256[](distribution.length);
                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] & ((1 << 128) - 1);
                }

                uint256 ethBalanceBefore = address(this).balance;

                _swapFromPoolToken(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    dist,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );

                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] >> 128;
                }

                uint256 ethBalanceAfter = address(this).balance;

                return _swapToPoolToken(
                    ETH_ADDRESS,
                    toToken,
                    ethBalanceAfter.sub(ethBalanceBefore),
                    dist,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );
            }

            if (isPoolTokenFrom) {
                return _swapFromPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );
            }

            if (isPoolTokenTo) {
                return _swapToPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );
            }
        }

        return super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            disableFlags
        );
    }

    function _swapFromPoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) private {
        IERC20 uniswapToken = uniswapFactory.getToken(address(poolToken));

        uint256[] memory dist = new uint256[](distribution.length);

        (
            uint256 ethAmount,
            uint256 exchangeTokenAmount
        ) = IUniswapExchange(address(poolToken)).removeLiquidity(
            amount,
            1,
            1,
            now.add(1800)
        );

        if (!toToken.isETH()) {
            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j]) & 0xFF;
            }

            this.swap(
                ETH_ADDRESS,
                toToken,
                ethAmount,
                0,
                dist,
                disableFlags
            );
        }

        if (toToken != uniswapToken) {
            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> 8) & 0xFF;
            }

            this.swap(
                uniswapToken,
                toToken,
                exchangeTokenAmount,
                0,
                dist,
                disableFlags
            );
        }
    }

    function _swapToPoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) private {
        IERC20 uniswapToken = uniswapFactory.getToken(address(poolToken));

        uint256 partAmountForEth = amount.div(2);

        uint256[] memory dist = new uint256[](distribution.length);

        if (!fromToken.isETH()) {
            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j]) & 0xFF;
            }

            this.swap(
                fromToken,
                ETH_ADDRESS,
                partAmountForEth,
                0,
                dist,
                disableFlags
            );
        }

        uint256 partAmountForToken = amount.sub(partAmountForEth);

        if (fromToken != uniswapToken) {
            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> 8) & 0xFF;
            }

            this.swap(
                fromToken,
                uniswapToken,
                partAmountForToken,
                0,
                dist,
                disableFlags
            );

            _infiniteApproveIfNeeded(uniswapToken, address(poolToken));
        }

        uint256 maxTokens = uniswapToken.balanceOf(address(this)) + 1;

        IUniswapExchange(address(poolToken)).addLiquidity.value(address(this).balance)(
            1, // todo: think about another value
            maxTokens,
            now.add(1800)
        );
    }
}
