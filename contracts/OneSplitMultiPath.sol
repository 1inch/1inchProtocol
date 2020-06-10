pragma solidity ^0.5.0;

import "./OneSplitBase.sol";


contract OneSplitMultiPathBase is IOneSplitConsts, OneSplitRoot {
    function _getMultiPathToken(uint256 flags) internal pure returns(IERC20 midToken) {
        uint256[7] memory allFlags = [
            FLAG_ENABLE_MULTI_PATH_ETH,
            FLAG_ENABLE_MULTI_PATH_DAI,
            FLAG_ENABLE_MULTI_PATH_USDC,
            FLAG_ENABLE_MULTI_PATH_USDT,
            FLAG_ENABLE_MULTI_PATH_WBTC,
            FLAG_ENABLE_MULTI_PATH_TBTC,
            FLAG_ENABLE_MULTI_PATH_RENBTC
        ];

        IERC20[7] memory allMidTokens = [
            ETH_ADDRESS,
            dai,
            usdc,
            usdt,
            wbtc,
            tbtc,
            renbtc
        ];

        for (uint i = 0; i < allFlags.length; i++) {
            if (flags.check(allFlags[i])) {
                require(midToken == IERC20(0), "OneSplit: Do not use multipath with each other");
                midToken = allMidTokens[i];
            }
        }
    }
}


contract OneSplitMultiPathView is OneSplitViewWrapBase, OneSplitMultiPathBase {
    function getExpectedReturnRespectingGas(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 toTokenEthPriceTimesGasPrice
    )
        public
        view
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        IERC20 midToken = _getMultiPathToken(flags);

        if (midToken != IERC20(0)) {
            if ((fromToken.isETH() && midToken.isETH()) ||
                (toToken.isETH() && midToken.isETH()) ||
                fromToken == midToken ||
                toToken == midToken)
            {
                return super.getExpectedReturnRespectingGas(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    flags,
                    toTokenEthPriceTimesGasPrice
                );
            }

            // Stack too deep
            uint256 _flags = flags;

            (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnRespectingGas(
                fromToken,
                midToken,
                amount,
                parts,
                _flags | FLAG_DISABLE_BANCOR | FLAG_DISABLE_CURVE_COMPOUND | FLAG_DISABLE_CURVE_USDT | FLAG_DISABLE_CURVE_Y | FLAG_DISABLE_CURVE_BINANCE | FLAG_DISABLE_CURVE_PAX,
                toTokenEthPriceTimesGasPrice
            );

            uint256[] memory dist;
            uint256 estimateGasAmount2;
            (returnAmount, estimateGasAmount2, dist) = super.getExpectedReturnRespectingGas(
                midToken,
                toToken,
                returnAmount,
                parts,
                _flags | FLAG_DISABLE_BANCOR | FLAG_DISABLE_CURVE_COMPOUND | FLAG_DISABLE_CURVE_USDT | FLAG_DISABLE_CURVE_Y | FLAG_DISABLE_CURVE_BINANCE | FLAG_DISABLE_CURVE_PAX,
                toTokenEthPriceTimesGasPrice
            );
            for (uint i = 0; i < distribution.length; i++) {
                distribution[i] = distribution[i].add(dist[i] << 8);
            }
            return (returnAmount, estimateGasAmount + estimateGasAmount2, distribution);
        }

        return super.getExpectedReturnRespectingGas(
            fromToken,
            toToken,
            amount,
            parts,
            flags,
            toTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitMultiPath is OneSplitBaseWrap, OneSplitMultiPathBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        IERC20 midToken = _getMultiPathToken(flags);

        if (midToken != IERC20(0)) {
            uint256[] memory dist = new uint256[](distribution.length);
            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = distribution[i] & 0xFF;
            }
            super._swap(
                fromToken,
                midToken,
                amount,
                dist,
                flags
            );

            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = (distribution[i] >> 8) & 0xFF;
            }
            super._swap(
                midToken,
                toToken,
                midToken.universalBalanceOf(address(this)),
                dist,
                flags
            );
            return;
        }

        super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            flags
        );
    }
}
