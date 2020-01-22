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
            return (amount, new uint256[](4));
        }

        if (disableFlags.enabled(FLAG_SMART_TOKEN)) {
            distribution = new uint256[](4);
            if (smartTokenRegistry.isSmartToken(fromToken)) {
                // ISmartTokenConverter converter = ISmartToken(address(fromToken)).owner();

                // TokensWithRatio memory tokens = _getTokens(converter);

                // for (uint256 i = 0; i < tokens.tokens.length; i++) {
                //     uint256 srcAmount = smartTokenFormula.calculateLiquidateReturn(
                //         toToken.totalSupply(),
                //         tokens.tokens[i].balanceOf(address(converter)),
                //         uint32(tokens.totalRatio),
                //         amount
                //     );

                //     (uint256 ret, uint256[] memory dist) = super.getExpectedReturn(
                //         tokens.tokens[i],
                //         toToken,
                //         srcAmount,
                //         parts,
                //         disableFlags
                //     );

                //     returnAmount = returnAmount.add(ret);
                //     for (uint j = 0; j < distribution.length; j++) {
                //         distribution[j] = distribution[j].add(dist[j] << (i * 8));
                //     }
                // }
                // return (returnAmount, distribution);
            }

            if (smartTokenRegistry.isSmartToken(toToken)) {
                // ISmartTokenConverter converter = ISmartToken(address(fromToken)).owner();

                // TokensWithRatio memory tokens = _getTokens(converter);

                // uint256 minFundAmount = uint256(-1);
                // uint256[] memory fundAmounts = new uint256[](tokens.tokens.length);
                // for (uint256 i = 0; i < tokens.tokens.length; i++) {
                //     (uint256 tokenAmount, uint256[] memory dist) = super.getExpectedReturn(
                //         fromToken,
                //         tokens.tokens[i],
                //         amount.mul(tokens.ratios[i]).div(tokens.totalRatio),
                //         parts,
                //         disableFlags | FLAG_BANCOR
                //     );
                //     for (uint j = 0; j < distribution.length; j++) {
                //         distribution[j] = distribution[j].add(dist[j] << (i * 8));
                //     }

                //     fundAmounts[i] = toToken.totalSupply()
                //         .mul(tokenAmount)
                //         .div(tokens.tokens[i].balanceOf(address(converter)));

                //     if (fundAmounts[i] < minFundAmount) {
                //         minFundAmount = fundAmounts[i];
                //     }
                // }

                // // Swap leftovers for SmartToken
                // for (uint256 i = 0; i < tokens.tokens.length; i++) {
                //     uint256 leftover = fundAmounts[i].sub(minFundAmount)
                //         .mul(tokens.tokens[i].balanceOf(address(converter)))
                //         .div(toToken.totalSupply());

                //     if (leftover > 0) {
                //         minFundAmount = minFundAmount.add(
                //             smartTokenFormula.calculatePurchaseReturn(
                //                 toToken.totalSupply(),
                //                 tokens.tokens[i].balanceOf(address(converter)),
                //                 uint32(tokens.totalRatio),
                //                 leftover
                //             )
                //         );
                //     }
                // }

                // return (minFundAmount, distribution);
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

    struct TokensWithRatio {
        IERC20[] tokens;
        uint256[] ratios;
        uint256 totalRatio;
    }

    function _getTokens(
        ISmartTokenConverter converter
    )
        private
        view
        returns(TokensWithRatio memory tokens)
    {
        tokens.tokens = new IERC20[](converter.connectorTokenCount());
        tokens.ratios = new uint256[](tokens.tokens.length);
        for (uint256 i = 0; i < tokens.tokens.length; i++) {
            tokens.tokens[i] = converter.connectorTokens(i);
            tokens.ratios[i] = converter.getReserveRatio(tokens.tokens[i]);
            tokens.totalRatio = tokens.totalRatio.add(tokens.ratios[i]);
        }
    }
}
