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


contract OneSplitBalancerPoolTokenView is OneSplitViewWrapBase, OneSplitBalancerPoolTokenBase {

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }


        if (!flags.check(FLAG_DISABLE_BALANCER_POOL_TOKEN)) {
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
            flags
        );
    }

    function _getExpectedReturnFromBalancerPoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
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
                flags
            );

            returnAmount = returnAmount.add(ret);

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        return (returnAmount, distribution);
    }

    function _getExpectedReturnToBalancerPoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
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
                    flags
                );

                for (uint j = 0; j < distribution.length; j++) {
                    distribution[j] |= dist[j] << (i * 8);
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

//        uint256 _minFundAmount = minFundAmount;
//        uint256 swapFee = IBPool(address(poolToken)).getSwapFee();
        // Swap leftovers for PoolToken
//        for (uint i = 0; i < details.tokens.length; i++) {
//            if (_minFundAmount == fundAmounts[i]) {
//                continue;
//            }
//
//            uint256 leftover = tokenAmounts[i].sub(
//                fundAmounts[i].mul(details.tokens[i].reserveBalance).div(details.totalSupply)
//            );
//
//            uint256 tokenRet = IBPool(address(poolToken)).calcPoolOutGivenSingleIn(
//                details.tokens[i].reserveBalance,
//                details.tokens[i].denormalizedWeight,
//                details.totalSupply,
//                details.totalWeight,
//                leftover,
//                swapFee
//            );
//
//            minFundAmount = minFundAmount.add(tokenRet);
//        }

        return (minFundAmount, distribution);
    }

}


contract OneSplitBalancerPoolToken is OneSplitBaseWrap, OneSplitBalancerPoolTokenBase {
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

        if (!flags.check(FLAG_DISABLE_BALANCER_POOL_TOKEN)) {
            bool isPoolTokenFrom = bFactory.isBPool(address(fromToken));
            bool isPoolTokenTo = bFactory.isBPool(address(toToken));

            if (isPoolTokenFrom && isPoolTokenTo) {
                uint256[] memory dist = new uint256[](distribution.length);
                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] & ((1 << 128) - 1);
                }

                uint256 ethBalanceBefore = address(this).balance;

                _swapFromBalancerPoolToken(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    dist,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
                );

                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] >> 128;
                }

                uint256 ethBalanceAfter = address(this).balance;

                return _swapToBalancerPoolToken(
                    ETH_ADDRESS,
                    toToken,
                    ethBalanceAfter.sub(ethBalanceBefore),
                    dist,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
                );
            }

            if (isPoolTokenFrom) {
                return _swapFromBalancerPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
                );
            }

            if (isPoolTokenTo) {
                return _swapToBalancerPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
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

    function _swapFromBalancerPoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {

        IBPool bToken = IBPool(address(poolToken));

        address[] memory currentTokens = bToken.getCurrentTokens();

        uint256 ratio = amount.sub(
            amount.mul(bToken.EXIT_FEE())
        ).mul(1e18).div(poolToken.totalSupply());

        uint256[] memory minAmountsOut = new uint256[](currentTokens.length);
        for (uint i = 0; i < currentTokens.length; i++) {
            minAmountsOut[i] = bToken.getBalance(currentTokens[i]).mul(ratio).div(1e18).mul(995).div(1000); // 0.5% slippage;
        }

        bToken.exitPool(amount, minAmountsOut);

        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < currentTokens.length; i++) {

            if (currentTokens[i] == address(toToken)) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            uint256 exchangeTokenAmount = IERC20(currentTokens[i]).balanceOf(address(this));

            this.swap(
                IERC20(currentTokens[i]),
                toToken,
                exchangeTokenAmount,
                0,
                dist,
                flags
            );
        }

    }

    function _swapToBalancerPoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        uint256[] memory dist = new uint256[](distribution.length);
        uint256 minFundAmount = uint256(-1);

        PoolTokenDetails memory details = _getPoolDetails(IBPool(address(poolToken)));

        uint256[] memory maxAmountsIn = new uint256[](details.tokens.length);
        uint256 curFundAmount;
        for (uint i = 0; i < details.tokens.length; i++) {
            uint256 exchangeAmount = amount
                .mul(details.tokens[i].denormalizedWeight)
                .div(details.totalWeight);

            if (details.tokens[i].token != fromToken) {
                uint256 tokenBalanceBefore = details.tokens[i].token.balanceOf(address(this));

                for (uint j = 0; j < distribution.length; j++) {
                    dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
                }

                this.swap(
                    fromToken,
                    details.tokens[i].token,
                    exchangeAmount,
                    0,
                    dist,
                    flags
                );

                uint256 tokenBalanceAfter = details.tokens[i].token.balanceOf(address(this));

                curFundAmount = (
                    tokenBalanceAfter.sub(tokenBalanceBefore)
                ).mul(details.totalSupply).div(details.tokens[i].reserveBalance);
            } else {
                curFundAmount = (
                    exchangeAmount
                ).mul(details.totalSupply).div(details.tokens[i].reserveBalance);
            }

            if (curFundAmount < minFundAmount) {
                minFundAmount = curFundAmount;
            }

            maxAmountsIn[i] = uint256(-1);
            _infiniteApproveIfNeeded(details.tokens[i].token, address(poolToken));
        }

        // todo: check for vulnerability
        IBPool(address(poolToken)).joinPool(minFundAmount, maxAmountsIn);

        // Return leftovers
        for (uint i = 0; i < details.tokens.length; i++) {
            details.tokens[i].token.universalTransfer(msg.sender, details.tokens[i].token.balanceOf(address(this)));
        }
    }
}
