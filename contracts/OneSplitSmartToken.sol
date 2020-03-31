pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./interface/ISmartToken.sol";
import "./interface/ISmartTokenRegistry.sol";
import "./interface/ISmartTokenConverter.sol";
import "./interface/ISmartTokenFormula.sol";
import "./OneSplitBase.sol";


contract OneSplitSmartTokenBase {
    using SafeMath for uint256;

    ISmartTokenRegistry smartTokenRegistry = ISmartTokenRegistry(0xf6E2D7F616B67E46D708e4410746E9AAb3a4C518);
    ISmartTokenFormula smartTokenFormula = ISmartTokenFormula(0x524619EB9b4cdFFa7DA13029b33f24635478AFc0);

    struct TokensWithRatio {
        IERC20[] tokens;
        uint256[] ratios;
        uint256 totalRatio;
    }

    function _getTokens(
        ISmartTokenConverter converter
    )
        internal
        view
        returns(TokensWithRatio memory tokens)
    {
        tokens.tokens = new IERC20[](converter.connectorTokenCount());
        tokens.ratios = new uint256[](tokens.tokens.length);
        for (uint256 i = 0; i < tokens.tokens.length; i++) {
            tokens.tokens[i] = converter.connectorTokens(i);
            tokens.ratios[i] = _getReserveRatio(converter, tokens.tokens[i]);
            tokens.totalRatio = tokens.totalRatio.add(tokens.ratios[i]);
        }
        return tokens;
    }

    function _getReserveRatio(
        ISmartTokenConverter converter,
        IERC20 token
    )
        internal
        view
        returns (uint256)
    {
        uint16 version = converter.version();

        if (version >= 22) {
            return converter.getReserveRatio(token);
        }

        return uint256(converter.reserves(address(token)).ratio);
    }
}


contract OneSplitSmartTokenView is OneSplitBaseView, OneSplitSmartTokenBase {

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 parts,
        uint256 disableFlags,
        uint256 amount
    )
        public
        view
        returns(
            uint256,
            uint256[] memory distribution
        )
    {

        if (fromToken == toToken) {
            return (amount, new uint256[](9));
        }

        if (!disableFlags.check(FLAG_DISABLE_SMART_TOKEN)) {
            distribution = new uint256[](9);
            if (smartTokenRegistry.isSmartToken(fromToken)) {
                ISmartTokenConverter converter = ISmartToken(address(fromToken)).owner();

                TokensWithRatio memory tokens = _getTokens(converter);

                uint256 returnAmount = 0;
                for (uint256 i = 0; i < tokens.tokens.length; i++) {
                    uint256 srcAmount = smartTokenFormula.calculateLiquidateReturn(
                        fromToken.totalSupply(),
                        tokens.tokens[i].balanceOf(address(converter)),
                        uint32(tokens.totalRatio),
                        amount
                    );

                    (uint256 ret, uint256[] memory dist) = super.getExpectedReturn(
                        tokens.tokens[i],
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
                return (returnAmount, distribution);
            }

            if (smartTokenRegistry.isSmartToken(toToken)) {
                ISmartTokenConverter converter = ISmartToken(address(toToken)).owner();

                TokensWithRatio memory tokens = _getTokens(
                    converter
                );

                uint256[] memory fundAmounts = new uint256[](tokens.tokens.length + 1);
                fundAmounts[0] = uint256(-1);
                for (uint256 i = 0; i < 1; i++) {
                    (uint256 tokenAmount, uint256[] memory dist) = super.getExpectedReturn(
                        fromToken,
                        tokens.tokens[i],
                        amount.mul(tokens.ratios[i]).div(tokens.totalRatio),
                        parts,
                        disableFlags | FLAG_DISABLE_BANCOR
                    );

                    for (uint j = 0; j < distribution.length; j++) {
                        distribution[j] = distribution[j].add(dist[j] << (i * 8));
                    }

                    fundAmounts[i + 1] = toToken.totalSupply()
                        .mul(tokenAmount)
                        .div(tokens.tokens[i].balanceOf(address(converter)));

                    if (fundAmounts[i + 1] < fundAmounts[0]) {
                        fundAmounts[0] = fundAmounts[i + 1];
                    }
                }

                // Swap leftovers for SmartToken
                for (uint i = 0; i < 1; i++) {
                    uint256 leftover = fundAmounts[i + 1].sub(fundAmounts[0])
                        .mul(tokens.tokens[i].balanceOf(address(converter)))
                        .div(toToken.totalSupply());

                    if (leftover > 0) {
                        fundAmounts[0] = fundAmounts[0].add(
                            smartTokenFormula.calculatePurchaseReturn(
                                toToken.totalSupply(),
                                tokens.tokens[i].balanceOf(address(converter)),
                                uint32(tokens.totalRatio),
                                leftover
                            )
                        );
                    }
                }

                return (fundAmounts[0], distribution);
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

}


contract OneSplitSmartToken is OneSplitBase, OneSplitSmartTokenBase {
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

        // TODO:

        return super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            disableFlags
        );
    }
}
