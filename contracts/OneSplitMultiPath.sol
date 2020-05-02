pragma solidity ^0.5.0;

import "./OneSplitBase.sol";


contract OneSplitMultiPathView is OneSplitViewWrapBase {
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

        if (!fromToken.isETH() && !toToken.isETH() && flags.check(FLAG_ENABLE_MULTI_PATH_ETH)) {
            (returnAmount, distribution) = super.getExpectedReturn(
                fromToken,
                ETH_ADDRESS,
                amount,
                parts,
                flags | FLAG_DISABLE_BANCOR | FLAG_DISABLE_CURVE_COMPOUND | FLAG_DISABLE_CURVE_USDT | FLAG_DISABLE_CURVE_Y | FLAG_DISABLE_CURVE_BINANCE
            );

            uint256[] memory dist;
            (returnAmount, dist) = super.getExpectedReturn(
                ETH_ADDRESS,
                toToken,
                returnAmount,
                parts,
                flags | FLAG_DISABLE_BANCOR | FLAG_DISABLE_CURVE_COMPOUND | FLAG_DISABLE_CURVE_USDT | FLAG_DISABLE_CURVE_Y | FLAG_DISABLE_CURVE_BINANCE
            );
            for (uint i = 0; i < distribution.length; i++) {
                distribution[i] = distribution[i].add(dist[i] << 8);
            }
            return (returnAmount, distribution);
        }

        if (fromToken != dai && toToken != dai && flags.check(FLAG_ENABLE_MULTI_PATH_DAI)) {
            (returnAmount, distribution) = super.getExpectedReturn(
                fromToken,
                dai,
                amount,
                parts,
                flags
            );

            uint256[] memory dist;
            (returnAmount, dist) = super.getExpectedReturn(
                dai,
                toToken,
                returnAmount,
                parts,
                flags
            );
            for (uint i = 0; i < distribution.length; i++) {
                distribution[i] = distribution[i].add(dist[i] << 8);
            }
            return (returnAmount, distribution);
        }

        if (fromToken != usdc && toToken != usdc && flags.check(FLAG_ENABLE_MULTI_PATH_USDC)) {
            (returnAmount, distribution) = super.getExpectedReturn(
                fromToken,
                usdc,
                amount,
                parts,
                flags
            );

            uint256[] memory dist;
            (returnAmount, dist) = super.getExpectedReturn(
                usdc,
                toToken,
                returnAmount,
                parts,
                flags
            );
            for (uint i = 0; i < distribution.length; i++) {
                distribution[i] = distribution[i].add(dist[i] << 8);
            }
            return (returnAmount, distribution);
        }

        return super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            flags
        );
    }
}


contract OneSplitMultiPath is OneSplitBaseWrap {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (!fromToken.isETH() && !toToken.isETH() && flags.check(FLAG_ENABLE_MULTI_PATH_ETH)) {
            uint256[] memory dist = new uint256[](distribution.length);
            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = distribution[i] & 0xFF;
            }
            super._swap(
                fromToken,
                ETH_ADDRESS,
                amount,
                dist,
                flags
            );

            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = (distribution[i] >> 8) & 0xFF;
            }
            super._swap(
                ETH_ADDRESS,
                toToken,
                address(this).balance,
                dist,
                flags
            );
            return;
        }

        if (fromToken != dai && toToken != dai && flags.check(FLAG_ENABLE_MULTI_PATH_DAI)) {
            uint256[] memory dist = new uint256[](distribution.length);
            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = distribution[i] & 0xFF;
            }
            super._swap(
                fromToken,
                dai,
                amount,
                dist,
                flags
            );

            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = (distribution[i] >> 8) & 0xFF;
            }
            super._swap(
                dai,
                toToken,
                dai.balanceOf(address(this)),
                dist,
                flags
            );
            return;
        }

        if (fromToken != usdc && toToken != usdc && flags.check(FLAG_ENABLE_MULTI_PATH_USDC)) {
            uint256[] memory dist = new uint256[](distribution.length);
            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = distribution[i] & 0xFF;
            }
            super._swap(
                fromToken,
                usdc,
                amount,
                dist,
                flags
            );

            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = (distribution[i] >> 8) & 0xFF;
            }
            super._swap(
                usdc,
                toToken,
                usdc.balanceOf(address(this)),
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
