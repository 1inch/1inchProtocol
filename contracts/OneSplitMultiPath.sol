pragma solidity ^0.5.0;

import "./OneSplitBase.sol";

contract OneSplitMultiPath is OneSplitBase {

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
            return (amount, new uint256[](4));
        }

        if (!fromToken.isETH() && !toToken.isETH() && !disableFlags.disabledReserve(FLAG_MULTI_PATH_ETH)) {
            (returnAmount, distribution) = super.getExpectedReturn(
                fromToken,
                ETH_ADDRESS,
                amount,
                parts,
                disableFlags | FLAG_BANCOR
            );

            uint256[] memory dist;
            (returnAmount, dist) = super.getExpectedReturn(
                ETH_ADDRESS,
                toToken,
                returnAmount,
                parts,
                disableFlags | FLAG_BANCOR
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

    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) internal {
        if (!fromToken.isETH() && !toToken.isETH() && !disableFlags.disabledReserve(FLAG_MULTI_PATH_ETH)) {
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

        super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            disableFlags
        );
    }
}
