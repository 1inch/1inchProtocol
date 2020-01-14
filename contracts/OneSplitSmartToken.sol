pragma solidity ^0.5.0;

import "./interface/ISmartToken.sol";
import "./interface/ISmartTokenRegistry.sol";
import "./interface/ISmartTokenConverter.sol";
import "./interface/ISmartTokenFormula.sol";
import "./OneSplitBase.sol";


contract OneSplitSmartToken is OneSplitBase {
    ISmartTokenRegistry smartTokenRegistry = ISmartTokenRegistry(0xf6E2D7F616B67E46D708e4410746E9AAb3a4C518);
    ISmartTokenFormula smartTokenFormula = ISmartTokenFormula(0x524619EB9b4cdFFa7DA13029b33f24635478AFc0);

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
            return (amount, distribution);
        }

        if (disableFlags.enabled(FLAG_SMART_TOKEN)) {
            if (smartTokenRegistry.isSmartToken(fromToken)) {
                ISmartTokenConverter converter = ISmartToken(address(fromToken)).owner();

                IERC20[] memory tokens = new IERC20[](converter.connectorTokenCount());
                uint256[] memory ratios = new uint256[](tokens.length);
                uint256 totalRatio = 0;
                for (uint256 i = 0; i < tokens.length; i++) {
                    tokens[i] = converter.connectorTokens(i);
                    ratios[i] = converter.getReserveRatio(tokens[i]);
                    totalRatio = totalRatio.add(ratios[i]);
                }

                for (uint256 i = 0; i < tokens.length; i++) {
                    uint256 srcAmount = smartTokenFormula.calculateLiquidateReturn(
                        toToken.totalSupply(),
                        tokens[i].balanceOf(address(converter)),
                        uint32(totalRatio),
                        amount
                    );

                    (uint256 ret, uint256[] memory dist) = super.getExpectedReturn(
                        tokens[i],
                        toToken,
                        srcAmount,
                        parts,
                        disableFlags
                    );

                    returnAmount = returnAmount.add(ret);
                    for (uint j = 0; j < distribution.length; j++) {
                        distribution[j] = distribution[j].add(dist[j] << (i * 8));
                    }
                }
                for (uint j = 0; j < distribution.length; j++) {
                    distribution[j] = distribution[j].add(1 << 255);
                }
                return (returnAmount, distribution);
            }

            // if (smartTokenRegistry.isSmartToken(toToken)) {
            //     ISmartTokenConverter converter = ISmartToken(address(fromToken)).owner();

            //     IERC20[] memory tokens = new IERC20[](converter.connectorTokenCount());
            //     uint256[] memory ratios = new uint256[](tokens.length);
            //     uint256 totalRatio = 0;
            //     for (uint256 i = 0; i < tokens.length; i++) {
            //         tokens[i] = converter.connectorTokens(i);
            //         ratios[i] = converter.getReserveRatio(tokens[i]);
            //         totalRatio = totalRatio.add(ratios[i]);
            //     }

            //     uint256 minFundAmount = uint256(-1);
            //     uint256[] memory fundAmounts = new uint256[](tokens.length);
            //     for (uint256 i = 0; i < tokens.length; i++) {
            //         (uint256 tokenAmount, uint256[] memory dist) = super.getExpectedReturn(
            //             fromToken,
            //             tokens[i],
            //             amount.mul(ratios[i]).div(totalRatio),
            //             parts,
            //             disableFlags | FLAG_BANCOR
            //         );
            //         for (uint j = 0; j < distribution.length; j++) {
            //             distribution[j] = distribution[j].add(dist[j] << (i * 8));
            //         }

            //         fundAmounts[i] = toToken.totalSupply()
            //             .mul(tokenAmount)
            //             .div(tokens[i].balanceOf(address(converter)));

            //         if (fundAmounts[i] < minFundAmount) {
            //             minFundAmount = fundAmounts[i];
            //         }
            //     }

            //     // Swap leftovers for SmartToken
            //     for (uint256 i = 0; i < tokens.length; i++) {
            //         uint256 leftover = fundAmounts[i].sub(minFundAmount)
            //             .mul(tokens[i].balanceOf(address(converter)))
            //             .div(toToken.totalSupply());

            //         minFundAmount = minFundAmount.add(
            //             smartTokenFormula.calculatePurchaseReturn(
            //                 toToken.totalSupply(),
            //                 tokens[i].balanceOf(address(converter)),
            //                 uint32(totalRatio),
            //                 leftover
            //             )
            //         );
            //     }

            //     return (minFundAmount, distribution);
            // }
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
        if (fromToken == toToken) {
            return;
        }

        

        return super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            disableFlags
        );
    }
}
