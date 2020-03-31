pragma solidity ^0.5.0;

import "./OneSplitBase.sol";


contract OneSplitMultiPathView is OneSplitBaseView {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        public
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](11));
        }

        if (!fromToken.isETH() && !toToken.isETH() && disableFlags.check(FLAG_ENABLE_MULTI_PATH_ETH)) {
            (returnAmount, distribution) = super.getExpectedReturn(
                fromToken,
                ETH_ADDRESS,
                amount,
                parts,
                disableFlags | FLAG_DISABLE_BANCOR | FLAG_DISABLE_CURVE_COMPOUND | FLAG_DISABLE_CURVE_USDT | FLAG_DISABLE_CURVE_Y | FLAG_DISABLE_CURVE_BINANCE
            );

            uint256[] memory dist;
            (returnAmount, dist) = super.getExpectedReturn(
                ETH_ADDRESS,
                toToken,
                returnAmount,
                parts,
                disableFlags | FLAG_DISABLE_BANCOR | FLAG_DISABLE_CURVE_COMPOUND | FLAG_DISABLE_CURVE_USDT | FLAG_DISABLE_CURVE_Y | FLAG_DISABLE_CURVE_BINANCE
            );
            for (uint i = 0; i < distribution.length; i++) {
                distribution[i] = distribution[i].add(dist[i] << 8);
            }
            return (returnAmount, distribution);
        }

        if (fromToken != dai && toToken != dai && disableFlags.check(FLAG_ENABLE_MULTI_PATH_DAI)) {
            (returnAmount, distribution) = super.getExpectedReturn(
                fromToken,
                dai,
                amount,
                parts,
                disableFlags
            );

            uint256[] memory dist;
            (returnAmount, dist) = super.getExpectedReturn(
                dai,
                toToken,
                returnAmount,
                parts,
                disableFlags
            );
            for (uint i = 0; i < distribution.length; i++) {
                distribution[i] = distribution[i].add(dist[i] << 8);
            }
            return (returnAmount, distribution);
        }

        if (fromToken != usdc && toToken != usdc && disableFlags.check(FLAG_ENABLE_MULTI_PATH_USDC)) {
            (returnAmount, distribution) = super.getExpectedReturn(
                fromToken,
                usdc,
                amount,
                parts,
                disableFlags
            );

            uint256[] memory dist;
            (returnAmount, dist) = super.getExpectedReturn(
                usdc,
                toToken,
                returnAmount,
                parts,
                disableFlags
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
            disableFlags
        );
    }
}


contract OneSplitMultiPath is OneSplitBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) internal {
        if (!fromToken.isETH() && !toToken.isETH() && disableFlags.check(FLAG_ENABLE_MULTI_PATH_ETH)) {
            uint256[] memory dist = new uint256[](distribution.length);
            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = distribution[i] & 0xFF;
            }
            super._swap(
                fromToken,
                ETH_ADDRESS,
                amount,
                dist,
                disableFlags
            );

            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = (distribution[i] >> 8) & 0xFF;
            }
            super._swap(
                ETH_ADDRESS,
                toToken,
                address(this).balance,
                dist,
                disableFlags
            );
            return;
        }

        if (fromToken != dai && toToken != dai && disableFlags.check(FLAG_ENABLE_MULTI_PATH_DAI)) {
            uint256[] memory dist = new uint256[](distribution.length);
            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = distribution[i] & 0xFF;
            }
            super._swap(
                fromToken,
                dai,
                amount,
                dist,
                disableFlags
            );

            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = (distribution[i] >> 8) & 0xFF;
            }
            super._swap(
                dai,
                toToken,
                dai.balanceOf(address(this)),
                dist,
                disableFlags
            );
            return;
        }

        if (fromToken != usdc && toToken != usdc && disableFlags.check(FLAG_ENABLE_MULTI_PATH_USDC)) {
            uint256[] memory dist = new uint256[](distribution.length);
            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = distribution[i] & 0xFF;
            }
            super._swap(
                fromToken,
                usdc,
                amount,
                dist,
                disableFlags
            );

            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = (distribution[i] >> 8) & 0xFF;
            }
            super._swap(
                usdc,
                toToken,
                usdc.balanceOf(address(this)),
                dist,
                disableFlags
            );
            return;
        }

        super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            disableFlags
        );
    }
}
