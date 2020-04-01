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

    struct TokenWithRatio {
        IERC20 token;
        uint256 ratio;
    }

    struct SmartTokenDetails {
        TokenWithRatio[] reserveTokenList;
        address converter;
        uint256 totalReserveTokensRatio;
    }

    function _getSmartTokenDetails(ISmartToken smartToken) internal view returns (SmartTokenDetails memory details) {
        ISmartTokenConverter converter = smartToken.owner();
        (TokenWithRatio[] memory reserveTokenList, uint256 totalReserveTokensRatio) = _getTokens(converter);

        details.reserveTokenList = reserveTokenList;
        details.converter = address(converter);
        details.totalReserveTokensRatio = totalReserveTokensRatio;

        return details;
    }

    function _getTokens(
        ISmartTokenConverter converter
    )
        internal
        view
        returns(TokenWithRatio[] memory reserveTokenList, uint256 totalRatio)
    {
        reserveTokenList = new TokenWithRatio[](converter.connectorTokenCount());
        for (uint256 i = 0; i < reserveTokenList.length; i++) {
            reserveTokenList[i].token = converter.connectorTokens(i);
            reserveTokenList[i].ratio = _getReserveRatio(converter, reserveTokenList[i].token);
            totalRatio = totalRatio.add(reserveTokenList[i].ratio);
        }
        return (reserveTokenList, totalRatio);
    }

    function _getReserveRatio(
        ISmartTokenConverter converter,
        IERC20 token
    )
        internal
        view
        returns (uint256)
    {
        if (converter.version() >= 22) {
            return converter.getReserveRatio(token);
        }

        return uint256(converter.reserves(address(token)).ratio);
    }

    function _calcExchangeAmount(uint256 amount, uint256 ratio, uint256 totalRatio) internal pure returns (uint256) {
        return amount.mul(ratio).div(totalRatio);
    }

}


contract OneSplitSmartTokenView is OneSplitBaseView, OneSplitSmartTokenBase {

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
            uint256,
            uint256[] memory
        )
    {

        if (fromToken == toToken) {
            return (amount, new uint256[](9));
        }

        if (!disableFlags.check(FLAG_DISABLE_SMART_TOKEN)) {

            if (smartTokenRegistry.isSmartToken(fromToken)) {

                return _getExpectedReturnFromSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    disableFlags
                );

            }

            if (smartTokenRegistry.isSmartToken(toToken)) {

                return _getExpectedReturnToSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    disableFlags
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

    function _getExpectedReturnFromSmartToken(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](9);

        SmartTokenDetails memory smartTokenDetails = _getSmartTokenDetails(ISmartToken(address(fromToken)));

        for (uint16 i = 0; i < smartTokenDetails.reserveTokenList.length; i++) {
            uint256 srcAmount = smartTokenFormula.calculateLiquidateReturn(
                fromToken.totalSupply(),
                smartTokenDetails.reserveTokenList[i].token.balanceOf(smartTokenDetails.converter),
                uint32(smartTokenDetails.totalReserveTokensRatio),
                amount
            );

            (uint256 ret, uint256[] memory dist) = super.getExpectedReturn(
                smartTokenDetails.reserveTokenList[i].token,
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

    function _getExpectedReturnToSmartToken(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        private
        view
        returns(
            uint256 minFundAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](9);
        minFundAmount = uint256(-1);

        SmartTokenDetails memory smartTokenDetails = _getSmartTokenDetails(ISmartToken(address(toToken)));

        uint256[] memory fundAmounts = new uint256[](smartTokenDetails.reserveTokenList.length);
        for (uint16 i = 0; i < smartTokenDetails.reserveTokenList.length; i++) {

            uint256 exchangeAmount = _calcExchangeAmount(
                amount,
                smartTokenDetails.reserveTokenList[i].ratio,
                smartTokenDetails.totalReserveTokensRatio
            );

            (uint256 tokenAmount, uint256[] memory dist) = super.getExpectedReturn(
                fromToken,
                smartTokenDetails.reserveTokenList[i].token,
                exchangeAmount,
                parts,
                disableFlags | FLAG_DISABLE_BANCOR
            );

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] = distribution[j].add(dist[j] << (i * 8));
            }

            fundAmounts[i] = toToken.totalSupply()
                .mul(tokenAmount)
                .div(smartTokenDetails.reserveTokenList[i].token.balanceOf(smartTokenDetails.converter));

            if (fundAmounts[i] < minFundAmount) {
                minFundAmount = fundAmounts[i];
            }
        }

        // Swap leftovers for SmartToken
        for (uint16 i = 0; i < smartTokenDetails.reserveTokenList.length; i++) {
            uint256 reserveBalance = smartTokenDetails.reserveTokenList[i].token.balanceOf(smartTokenDetails.converter);

            uint256 leftover = fundAmounts[i].sub(minFundAmount)
                .mul(reserveBalance)
                .div(toToken.totalSupply());

            if (leftover > 0) {
                minFundAmount = minFundAmount.add(
                    smartTokenFormula.calculatePurchaseReturn(
                        toToken.totalSupply(),
                        reserveBalance,
                        uint32(smartTokenDetails.totalReserveTokensRatio),
                        leftover
                    )
                );
            }
        }

        return (minFundAmount, distribution);
    }

}


contract OneSplitSmartToken is OneSplitBase, OneSplitSmartTokenBase {

    // todo: think about smart tokens with one token in reserve
    // todo: think about the case when toToken == reserveToken
    // todo: think about the case when fromToken == reserveToken
    // todo: think about the case when fromToken == smartToken1, toToken == smartToken2
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

        if (!disableFlags.check(FLAG_DISABLE_SMART_TOKEN)) {

            if (smartTokenRegistry.isSmartToken(fromToken)) {

                return _swapFromSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    disableFlags
                );

            }

            if (smartTokenRegistry.isSmartToken(toToken)) {

                return _swapToSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    disableFlags
                );

            }
        }

        return super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            disableFlags
        );
    }

    function _swapFromSmartToken(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) private {

        SmartTokenDetails memory smartTokenDetails = _getSmartTokenDetails(ISmartToken(address(fromToken)));

        uint256[] memory tokenBalanceBefore = new uint256[](smartTokenDetails.reserveTokenList.length);
        uint256[][] memory dist = new uint256[][](smartTokenDetails.reserveTokenList.length);
        for (uint16 i = 0; i < smartTokenDetails.reserveTokenList.length; i++) {
            dist[i] = new uint256[](distribution.length);

            tokenBalanceBefore[i] = smartTokenDetails.reserveTokenList[i].token.balanceOf(address(this));

            for (uint j = 0; j < distribution.length; j++) {
                dist[i][j] = (distribution[j] >> (i * 8)) & 0xFF;
            }
        }

        ISmartTokenConverter(smartTokenDetails.converter).liquidate(amount);

        for (uint16 i = 0; i < smartTokenDetails.reserveTokenList.length; i++) {
            uint256 tokenBalanceAfter = smartTokenDetails.reserveTokenList[i].token.balanceOf(address(this));

            return super._swap(
                smartTokenDetails.reserveTokenList[i].token,
                toToken,
                tokenBalanceAfter.sub(tokenBalanceBefore[i]),
                dist[i],
                disableFlags
            );
        }

    }

    function _swapToSmartToken(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) private {

        uint256 minFundAmount = uint256(-1);

        SmartTokenDetails memory smartTokenDetails = _getSmartTokenDetails(ISmartToken(address(toToken)));

        uint256[] memory dist = new uint256[](distribution.length);
        uint256[] memory fundAmounts = new uint256[](smartTokenDetails.reserveTokenList.length);
        for (uint16 i = 0; i < smartTokenDetails.reserveTokenList.length; i++) {

            uint256 exchangeAmount = _calcExchangeAmount(
                amount,
                smartTokenDetails.reserveTokenList[i].ratio,
                smartTokenDetails.totalReserveTokensRatio
            );

            uint256 tokenBalanceBefore = smartTokenDetails.reserveTokenList[i].token.balanceOf(address(this));

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            super._swap(
                fromToken,
                smartTokenDetails.reserveTokenList[i].token,
                exchangeAmount,
                dist,
                disableFlags
            );

            uint256 tokenBalanceAfter = smartTokenDetails.reserveTokenList[i].token.balanceOf(address(this));

            fundAmounts[i] = toToken.totalSupply()
                .mul(tokenBalanceAfter.sub(tokenBalanceBefore))
                .div(smartTokenDetails.reserveTokenList[i].token.balanceOf(smartTokenDetails.converter));

            if (fundAmounts[i] < minFundAmount) {
                minFundAmount = fundAmounts[i];
            }

            _infiniteApproveIfNeeded(smartTokenDetails.reserveTokenList[i].token, smartTokenDetails.converter);
        }

        ISmartTokenConverter(smartTokenDetails.converter).fund(minFundAmount);

        // Swap leftovers for SmartToken
        for (uint16 i = 0; i < smartTokenDetails.reserveTokenList.length; i++) {
            uint256 reserveBalance = smartTokenDetails.reserveTokenList[i].token.balanceOf(smartTokenDetails.converter);

            uint256 leftover = fundAmounts[i].sub(minFundAmount)
                .mul(reserveBalance)
                .div(toToken.totalSupply());

            if (leftover > 0) {

                convert(
                    ISmartTokenConverter(smartTokenDetails.converter),
                    smartTokenDetails.reserveTokenList[i].token,
                    toToken,
                    leftover
                );

            }
        }

    }

    function convert(
        ISmartTokenConverter converter,
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _amount
    )
        private
        returns (uint256)
    {
        // todo: think about minReturn, affiliateAccount, affiliateFee
        if (converter.version() >= 16) {
            return converter.convert2(_fromToken, _toToken, _amount, 0, address(0), 0);
        }

        return converter.convert(_fromToken, _toToken, _amount, 0);
    }

}
