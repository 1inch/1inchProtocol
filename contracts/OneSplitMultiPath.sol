pragma solidity ^0.5.0;

import "./OneSplitBase.sol";


contract OneSplitMultiPathBase is IOneSplitConsts, OneSplitRoot {
    function _getMultiPathToken(uint256 flags) internal pure returns(IERC20 midToken) {
        uint256[8] memory allFlags = [
            FLAG_ENABLE_MULTI_PATH_ETH,
            FLAG_ENABLE_MULTI_PATH_DAI,
            FLAG_ENABLE_MULTI_PATH_USDC,
            FLAG_ENABLE_MULTI_PATH_USDT,
            FLAG_ENABLE_MULTI_PATH_WBTC,
            FLAG_ENABLE_MULTI_PATH_TBTC,
            FLAG_ENABLE_MULTI_PATH_RENBTC,
            FLAG_ENABLE_MULTI_PATH_COMP
        ];

        IERC20[8] memory allMidTokens = [
            ETH_ADDRESS,
            dai,
            usdc,
            usdt,
            wbtc,
            tbtc,
            renbtc,
            comp
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
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        IERC20 midToken = _getMultiPathToken(flags);

        if (midToken != IERC20(0)) {
            if (_tokensEqual(fromToken, midToken) || _tokensEqual(midToken, destToken)) {
                return super.getExpectedReturnWithGas(
                    fromToken,
                    destToken,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
            }

            // Stack too deep
            uint256 _flags = flags;
            IERC20 _destToken = destToken;
            uint256 _destTokenEthPriceTimesGasPrice = destTokenEthPriceTimesGasPrice;

            (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                fromToken,
                midToken,
                amount,
                parts,
                _flags,
                _scaleDestTokenEthPriceTimesGasPrice(
                    _destToken,
                    midToken,
                    _destTokenEthPriceTimesGasPrice
                )
            );

            uint256[] memory dist;
            uint256 estimateGasAmount2;
            (returnAmount, estimateGasAmount2, dist) = super.getExpectedReturnWithGas(
                midToken,
                destToken,
                returnAmount,
                parts,
                _flags, // Double tap into the same source is not an issue since price wouldn't be worse
                destTokenEthPriceTimesGasPrice
            );
            for (uint i = 0; i < distribution.length; i++) {
                distribution[i] = distribution[i].add(dist[i] << 8);
            }
            return (returnAmount, estimateGasAmount + estimateGasAmount2, distribution);
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitMultiPath is OneSplitBaseWrap, OneSplitMultiPathBase {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        IERC20 midToken = _getMultiPathToken(flags);

        if (midToken != IERC20(0) && !_tokensEqual(fromToken, midToken) && !_tokensEqual(midToken, destToken)) {
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
                destToken,
                midToken.universalBalanceOf(address(this)),
                dist,
                flags
            );
            return;
        }

        super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}
