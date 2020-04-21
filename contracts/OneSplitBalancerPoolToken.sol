pragma solidity ^0.5.0;

import "./OneSplitBase.sol";
import "./interface/IBFactory.sol";
import "./interface/IBPool.sol";


contract OneSplitBalancerPoolTokenBase {
    using SafeMath for uint256;

    // todo: factory for Bronze release
    // may be changed in future
    IBFactory bFactory = IBFactory(0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd);

    struct TokenWithWeight {
        IERC20 token;
        uint256 reserveBalance;
        uint256 denormalizedWeight;
    }

    struct PoolTokenDetails {
        TokenWithWeight[] tokens;
        uint256 totalWeight;
        uint256 totalSupply;
    }

    function _getPoolDetails(IBPool poolToken)
        internal
        view
        returns(PoolTokenDetails memory details)
    {
        address[] memory currentTokens = poolToken.getCurrentTokens();
        details.tokens = new TokenWithWeight[](currentTokens.length);
        details.totalWeight = poolToken.getTotalDenormalizedWeight();
        details.totalSupply = poolToken.totalSupply();
        for (uint256 i = 0; i < details.tokens.length; i++) {
            details.tokens[i].token = IERC20(currentTokens[i]);
            details.tokens[i].denormalizedWeight = poolToken.getDenormalizedWeight(currentTokens[i]);
            details.tokens[i].reserveBalance = poolToken.getBalance(currentTokens[i]);
        }
    }

}

contract OneSplitBalancerPoolTokenView is OneSplitBaseView, OneSplitBalancerPoolTokenBase {

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
    internal
    returns (
        uint256 returnAmount,
        uint256[] memory distribution
    )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }


        if (!disableFlags.check(FLAG_DISABLE_BALANCER_POOL_TOKEN)) {
            bool isPoolTokenFrom = bFactory.isBPool(address(fromToken));
            bool isPoolTokenTo = bFactory.isBPool(address(toToken));

            if (isPoolTokenFrom && isPoolTokenTo) {
                (
                uint256 returnETHAmount,
                uint256[] memory poolTokenFromDistribution
                ) = _getExpectedReturnFromBalancerPoolToken(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    parts,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
                );

                (
                uint256 returnPoolTokenToAmount,
                uint256[] memory poolTokenToDistribution
                ) = _getExpectedReturnToBalancerPoolToken(
                    ETH_ADDRESS,
                    toToken,
                    returnETHAmount,
                    parts,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
                );

                for (uint i = 0; i < poolTokenToDistribution.length; i++) {
                    poolTokenFromDistribution[i] |= poolTokenToDistribution[i] << 128;
                }

                return (returnPoolTokenToAmount, poolTokenFromDistribution);
            }

            if (isPoolTokenFrom) {
                return _getExpectedReturnFromBalancerPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
                );
            }

            if (isPoolTokenTo) {
                return _getExpectedReturnToBalancerPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
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

    function _getExpectedReturnFromBalancerPoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
    private
    returns (
        uint256 returnAmount,
        uint256[] memory distribution
    )
    {
        distribution = new uint256[](DEXES_COUNT);

        IBPool bToken = IBPool(address(poolToken));
        address[] memory currentTokens = bToken.getCurrentTokens();

        uint256 pAiAfterExitFee = amount.sub(
            amount.mul(bToken.EXIT_FEE())
        );
        uint256 ratio = pAiAfterExitFee.mul(1e18).div(poolToken.totalSupply());
        for (uint i = 0; i < currentTokens.length; i++) {
            uint256 tokenAmountOut = bToken.getBalance(currentTokens[i]).mul(ratio).div(1e18);

            if (currentTokens[i] == address(toToken)) {
                returnAmount = returnAmount.add(tokenAmountOut);
                continue;
            }

            (uint256 ret, uint256[] memory dist) = getExpectedReturn(
                IERC20(currentTokens[i]),
                toToken,
                tokenAmountOut,
                parts,
                disableFlags
            );

            returnAmount = returnAmount.add(ret);

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << 8;
            }
        }

        return (returnAmount, distribution);
    }

    function _getExpectedReturnToBalancerPoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        private
        returns (
            uint256 minFundAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);
        minFundAmount = uint256(-1);

        PoolTokenDetails memory details = _getPoolDetails(IBPool(address(poolToken)));

        uint256[] memory tokenAmounts = new uint256[](details.tokens.length);
        uint256[] memory dist;
        uint256[] memory fundAmounts = new uint256[](details.tokens.length);

        for (uint i = 0; i < details.tokens.length; i++) {
            uint256 exchangeAmount = amount.mul(
                details.tokens[i].denormalizedWeight
            ).div(details.totalWeight);

            if (details.tokens[i].token != fromToken) {
                (tokenAmounts[i], dist) = getExpectedReturn(
                    fromToken,
                    details.tokens[i].token,
                    exchangeAmount,
                    parts,
                    disableFlags
                );

                for (uint j = 0; j < distribution.length; j++) {
                    distribution[j] |= dist[j] << 8;
                }
            } else {
                tokenAmounts[i] = exchangeAmount;
            }

            fundAmounts[i] = tokenAmounts[i]
                .mul(details.totalSupply)
                .div(details.tokens[i].reserveBalance);

            if (fundAmounts[i] < minFundAmount) {
                minFundAmount = fundAmounts[i];
            }
        }

        uint256 _minFundAmount = minFundAmount;
        uint256 swapFee = IBPool(address(poolToken)).getSwapFee();
        // Swap leftovers for PoolToken
        for (uint i = 0; i < details.tokens.length; i++) {
            if (_minFundAmount == fundAmounts[i]) {
                continue;
            }

            uint256 leftover = tokenAmounts[i].sub(
                fundAmounts[i].mul(details.tokens[i].reserveBalance).div(details.totalSupply)
            );

            uint256 tokenRet = IBPool(address(poolToken)).calcPoolOutGivenSingleIn(
                details.tokens[i].reserveBalance,
                details.tokens[i].denormalizedWeight,
                details.totalSupply,
                details.totalWeight,
                leftover,
                swapFee
            );

            minFundAmount = minFundAmount.add(tokenRet);
        }

        return (minFundAmount, distribution);
    }

}


//contract OneSplitBalancerPoolToken is OneSplitBase, OneSplitBalancerPoolTokenBase {
//    function _swap(
//        IERC20 fromToken,
//        IERC20 toToken,
//        uint256 amount,
//        uint256[] memory distribution,
//        uint256 disableFlags
//    ) internal {
//        if (fromToken == toToken) {
//            return;
//        }
//
//        if (!disableFlags.check(FLAG_DISABLE_BALANCER_POOL_TOKEN)) {
//            bool isPoolTokenFrom = isLiquidityPool(fromToken);
//            bool isPoolTokenTo = isLiquidityPool(toToken);
//
//            if (isPoolTokenFrom && isPoolTokenTo) {
//                uint256[] memory dist = new uint256[](distribution.length);
//                for (uint i = 0; i < distribution.length; i++) {
//                    dist[i] = distribution[i] & ((1 << 128) - 1);
//                }
//
//                uint256 ethBalanceBefore = address(this).balance;
//
//                _swapFromPoolToken(
//                    fromToken,
//                    ETH_ADDRESS,
//                    amount,
//                    dist,
//                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
//                );
//
//                for (uint i = 0; i < distribution.length; i++) {
//                    dist[i] = distribution[i] >> 128;
//                }
//
//                uint256 ethBalanceAfter = address(this).balance;
//
//                return _swapToPoolToken(
//                    ETH_ADDRESS,
//                    toToken,
//                    ethBalanceAfter.sub(ethBalanceBefore),
//                    dist,
//                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
//                );
//            }
//
//            if (isPoolTokenFrom) {
//                return _swapFromPoolToken(
//                    fromToken,
//                    toToken,
//                    amount,
//                    distribution,
//                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
//                );
//            }
//
//            if (isPoolTokenTo) {
//                return _swapToPoolToken(
//                    fromToken,
//                    toToken,
//                    amount,
//                    distribution,
//                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
//                );
//            }
//        }
//
//        return super._swap(
//            fromToken,
//            toToken,
//            amount,
//            distribution,
//            disableFlags
//        );
//    }
//
//    function _swapFromPoolToken(
//        IERC20 poolToken,
//        IERC20 toToken,
//        uint256 amount,
//        uint256[] memory distribution,
//        uint256 disableFlags
//    ) private {
//
//        uint256[] memory dist = new uint256[](distribution.length);
//
//        (
//        uint256 ethAmount,
//        uint256 exchangeTokenAmount
//        ) = IUniswapExchange(address(poolToken)).removeLiquidity(
//            amount,
//            1,
//            1,
//            now.add(1800)
//        );
//
//        if (!toToken.isETH()) {
//            for (uint j = 0; j < distribution.length; j++) {
//                dist[j] = (distribution[j]) & 0xFF;
//            }
//
//            super._swap(
//                ETH_ADDRESS,
//                toToken,
//                ethAmount,
//                dist,
//                disableFlags
//            );
//        }
//
//        IERC20 uniswapToken = uniswapFactory.getToken(address(poolToken));
//
//        if (toToken != uniswapToken) {
//            for (uint j = 0; j < distribution.length; j++) {
//                dist[j] = (distribution[j] >> 8) & 0xFF;
//            }
//
//            super._swap(
//                uniswapToken,
//                toToken,
//                exchangeTokenAmount,
//                dist,
//                disableFlags
//            );
//        }
//    }
//
//    function _swapToPoolToken(
//        IERC20 fromToken,
//        IERC20 poolToken,
//        uint256 amount,
//        uint256[] memory distribution,
//        uint256 disableFlags
//    ) private {
//        uint256[] memory dist = new uint256[](distribution.length);
//
//        uint256 partAmountForEth = amount.div(2);
//        if (!fromToken.isETH()) {
//            for (uint j = 0; j < distribution.length; j++) {
//                dist[j] = (distribution[j]) & 0xFF;
//            }
//
//            super._swap(
//                fromToken,
//                ETH_ADDRESS,
//                partAmountForEth,
//                dist,
//                disableFlags
//            );
//        }
//
//        IERC20 uniswapToken = uniswapFactory.getToken(address(poolToken));
//
//        uint256 partAmountForToken = amount.sub(partAmountForEth);
//        if (fromToken != uniswapToken) {
//            for (uint j = 0; j < distribution.length; j++) {
//                dist[j] = (distribution[j] >> 8) & 0xFF;
//            }
//
//            super._swap(
//                fromToken,
//                uniswapToken,
//                partAmountForToken,
//                dist,
//                disableFlags
//            );
//
//            _infiniteApproveIfNeeded(uniswapToken, address(poolToken));
//        }
//
//        uint256 ethBalance = address(this).balance;
//        uint256 tokenBalance = uniswapToken.balanceOf(address(this));
//
//        (uint256 ethAmount, uint256 returnAmount) = getMaxPossibleFund(
//            poolToken,
//            uniswapToken,
//            tokenBalance,
//            ethBalance
//        );
//
//        IUniswapExchange(address(poolToken)).addLiquidity.value(ethAmount)(
//            returnAmount.mul(995).div(1000), // 0.5% slippage
//            uint256(- 1), // todo: think about another value
//            now.add(1800)
//        );
//
//        // todo: do we need to check difference between balance before and balance after?
//        uniswapToken.universalTransfer(msg.sender, uniswapToken.balanceOf(address(this)));
//        ETH_ADDRESS.universalTransfer(msg.sender, address(this).balance);
//    }
//}
