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

    function getMaxPossibleFund(
        IERC20 poolToken,
        IERC20 uniswapToken,
        uint256 tokenAmount,
        uint256 existEthAmount
    )
        internal
        view
        returns (
            uint256,
            uint256
        )
    {
        uint256 ethReserve = address(poolToken).balance;
        uint256 totalLiquidity = poolToken.totalSupply();
        uint256 tokenReserve = uniswapToken.balanceOf(address(poolToken));

        uint256 possibleEthAmount = ethReserve.mul(
            tokenAmount.sub(1)
        ).div(tokenReserve);

        if (existEthAmount > possibleEthAmount) {
            return (
                possibleEthAmount,
                possibleEthAmount.mul(totalLiquidity).div(ethReserve)
            );
        }

        return (
            existEthAmount,
            existEthAmount.mul(totalLiquidity).div(ethReserve)
        );
    }

}

contract OneSplitUniswapPoolTokenView is OneSplitViewWrapBase, OneSplitUniswapPoolTokenBase {

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
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
        view
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
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {

        distribution = new uint256[](DEXES_COUNT);

        uint256[] memory dist = new uint256[](DEXES_COUNT);

        uint256 ethAmount;
        uint256 partAmountForEth = amount.div(2);
        if (!fromToken.isETH()) {
            (ethAmount, dist) = super.getExpectedReturn(
                fromToken,
                ETH_ADDRESS,
                partAmountForEth,
                parts,
                disableFlags
            );

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j];
            }
        } else {
            ethAmount = partAmountForEth;
        }

        IERC20 uniswapToken = uniswapFactory.getToken(address(poolToken));

        uint256 tokenAmount;
        uint256 partAmountForToken = amount.sub(partAmountForEth);
        if (fromToken != uniswapToken) {
            (tokenAmount, dist) = super.getExpectedReturn(
                fromToken,
                uniswapToken,
                partAmountForToken,
                parts,
                disableFlags
            );

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << 8;
            }
        } else {
            tokenAmount = partAmountForToken;
        }

        (, returnAmount) = getMaxPossibleFund(
            poolToken,
            uniswapToken,
            tokenAmount,
            ethAmount
        );

        return (
            returnAmount,
            distribution
        );
    }

}


contract OneSplitUniswapPoolToken is OneSplitBaseWrap, OneSplitUniswapPoolTokenBase {
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

            super._swap(
                ETH_ADDRESS,
                toToken,
                ethAmount,
                dist,
                disableFlags
            );
        }

        IERC20 uniswapToken = uniswapFactory.getToken(address(poolToken));

        if (toToken != uniswapToken) {
            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> 8) & 0xFF;
            }

            super._swap(
                uniswapToken,
                toToken,
                exchangeTokenAmount,
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
        uint256[] memory dist = new uint256[](distribution.length);

        uint256 partAmountForEth = amount.div(2);
        if (!fromToken.isETH()) {
            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j]) & 0xFF;
            }

            super._swap(
                fromToken,
                ETH_ADDRESS,
                partAmountForEth,
                dist,
                disableFlags
            );
        }

        IERC20 uniswapToken = uniswapFactory.getToken(address(poolToken));

        uint256 partAmountForToken = amount.sub(partAmountForEth);
        if (fromToken != uniswapToken) {
            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> 8) & 0xFF;
            }

            super._swap(
                fromToken,
                uniswapToken,
                partAmountForToken,
                dist,
                disableFlags
            );

            _infiniteApproveIfNeeded(uniswapToken, address(poolToken));
        }

        uint256 ethBalance = address(this).balance;
        uint256 tokenBalance = uniswapToken.balanceOf(address(this));

        (uint256 ethAmount, uint256 returnAmount) = getMaxPossibleFund(
            poolToken,
            uniswapToken,
            tokenBalance,
            ethBalance
        );

        IUniswapExchange(address(poolToken)).addLiquidity.value(ethAmount)(
            returnAmount.mul(995).div(1000), // 0.5% slippage
            uint256(-1),                     // todo: think about another value
            now.add(1800)
        );

        // todo: do we need to check difference between balance before and balance after?
        uniswapToken.universalTransfer(msg.sender, uniswapToken.balanceOf(address(this)));
        ETH_ADDRESS.universalTransfer(msg.sender, address(this).balance);
    }
}
