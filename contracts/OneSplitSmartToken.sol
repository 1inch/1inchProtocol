pragma solidity ^0.5.0;

import "./interface/ISmartToken.sol";
import "./interface/ISmartTokenRegistry.sol";
import "./interface/ISmartTokenConverter.sol";
import "./interface/ISmartTokenFormula.sol";
import "./OneSplitBase.sol";

contract OneSplitSmartTokenBase {
    using SafeMath for uint256;

    ISmartTokenRegistry smartTokenRegistry = ISmartTokenRegistry(0xf6E2D7F616B67E46D708e4410746E9AAb3a4C518);
    ISmartTokenFormula smartTokenFormula = ISmartTokenFormula(0x524619EB9b4cdFFa7DA13029b33f24635478AFc0);
    IERC20 bntToken = IERC20(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);

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

        (bool ok, bytes memory data) = address(converter).staticcall.gas(10000)(
            abi.encodeWithSelector(
                converter.getReserveRatio.selector,
                token
            )
        );

        if (ok) {
            return abi.decode(data, (uint256));
        }

        (, uint32 ratio, , ,) = converter.connectors(address(token));

        return uint256(ratio);
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

            bool isSmartTokenFrom = smartTokenRegistry.isSmartToken(fromToken);
            bool isSmartTokenTo = smartTokenRegistry.isSmartToken(toToken);

            if (isSmartTokenFrom && isSmartTokenTo) {

                (
                    uint256 returnBntAmount,
                    uint256[] memory smartTokenFromDistribution
                ) = _getExpectedReturnFromSmartToken(
                    fromToken,
                    bntToken,
                    amount,
                    parts,
                    disableFlags
                );

                (
                    uint256 returnSmartTokenToAmount,
                    uint256[] memory smartTokenToDistribution
                ) = _getExpectedReturnToSmartToken(
                    bntToken,
                    toToken,
                    returnBntAmount,
                    parts,
                    disableFlags
                );

                for (uint i = 0; i < smartTokenToDistribution.length; i++) {
                    smartTokenFromDistribution[i] += smartTokenFromDistribution[i]
                        .add(smartTokenToDistribution[i] << 128);
                }

                return (returnSmartTokenToAmount, smartTokenFromDistribution);

            }

            if (isSmartTokenFrom) {

                return _getExpectedReturnFromSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    disableFlags
                );

            }

            if (isSmartTokenTo) {

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

            if (smartTokenDetails.reserveTokenList[i].token == toToken) {
                returnAmount = returnAmount.add(srcAmount);
                continue;
            }

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

        uint256 tokenAmount;
        uint256[] memory dist;
        uint256[] memory fundAmounts = new uint256[](smartTokenDetails.reserveTokenList.length);
        for (uint16 i = 0; i < smartTokenDetails.reserveTokenList.length; i++) {

            uint256 exchangeAmount = _calcExchangeAmount(
                amount,
                smartTokenDetails.reserveTokenList[i].ratio,
                smartTokenDetails.totalReserveTokensRatio
            );

            if (smartTokenDetails.reserveTokenList[i].token != fromToken) {

                (tokenAmount, dist) = _findBestSwapPrice(
                    fromToken,
                    smartTokenDetails.reserveTokenList[i].token,
                    exchangeAmount,
                    parts,
                    disableFlags
                );

                for (uint j = 0; j < distribution.length; j++) {
                    distribution[j] = distribution[j].add(dist[j] << (i * 8));
                }

            } else {

                tokenAmount = exchangeAmount;

            }

            fundAmounts[i] = toToken.totalSupply()
                .mul(tokenAmount)
                .div(smartTokenDetails.reserveTokenList[i].token.balanceOf(smartTokenDetails.converter));

            if (fundAmounts[i] < minFundAmount) {
                minFundAmount = fundAmounts[i];
            }

        }

        uint256 _minFundAmount = minFundAmount;

        // Swap leftovers for SmartToken
        for (uint16 i = 0; i < smartTokenDetails.reserveTokenList.length; i++) {

            uint256 reserveBalance = smartTokenDetails.reserveTokenList[i].token.balanceOf(smartTokenDetails.converter);
            uint256 totalSupply = toToken.totalSupply();

            uint256 leftover = fundAmounts[i].sub(_minFundAmount)
                .mul(reserveBalance)
                .div(totalSupply);

            if (leftover > 0) {

                minFundAmount = minFundAmount.add(
                    smartTokenFormula.calculatePurchaseReturn(
                        totalSupply,
                        reserveBalance,
                        uint32(smartTokenDetails.totalReserveTokensRatio),
                        leftover
                    )
                );

            }

        }

        return (minFundAmount, distribution);
    }

    function _findBestSwapPrice(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        private
        view
        returns (uint256, uint256[] memory)
    {

        (uint256 tokenAmountWithBancor, uint256[] memory distWithBancor) = super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );

        (uint256 tokenAmount, uint256[] memory dist) = super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags | FLAG_DISABLE_BANCOR
        );

        if (tokenAmountWithBancor > tokenAmount) {
            return (tokenAmountWithBancor, distWithBancor);
        }

        return (tokenAmount, dist);

    }

}


contract OneSplitSmartToken is OneSplitBase, OneSplitSmartTokenBase {

    struct Amounts {
        uint256[] fund;
        uint256[] reserveTokenAmounts;
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

        if (!disableFlags.check(FLAG_DISABLE_SMART_TOKEN)) {

            bool isSmartTokenFrom = smartTokenRegistry.isSmartToken(fromToken);
            bool isSmartTokenTo = smartTokenRegistry.isSmartToken(toToken);

            if (isSmartTokenFrom && isSmartTokenTo) {

                uint256[] memory dist = new uint256[](distribution.length);
                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] & ((1 << 128) - 1);
                }

                uint256 bntBalanceBefore = bntToken.balanceOf(address(this));

                _swapFromSmartToken(
                    fromToken,
                    bntToken,
                    amount,
                    dist,
                    disableFlags
                );

                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] >> 128;
                }

                uint256 bntBalanceAfter = bntToken.balanceOf(address(this));

                return _swapToSmartToken(
                    bntToken,
                    toToken,
                    bntBalanceAfter.sub(bntBalanceBefore),
                    dist,
                    disableFlags
                );

            }

            if (isSmartTokenFrom) {

                return _swapFromSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    disableFlags
                );

            }

            if (isSmartTokenTo) {

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
        for (uint16 i = 0; i < smartTokenDetails.reserveTokenList.length; i++) {

            if (smartTokenDetails.reserveTokenList[i].token == toToken) {
                continue;
            }

            tokenBalanceBefore[i] = smartTokenDetails.reserveTokenList[i].token.balanceOf(address(this));

        }

        ISmartTokenConverter(smartTokenDetails.converter).liquidate(amount);

        uint256[] memory dist = new uint256[](distribution.length);
        for (uint16 i = 0; i < smartTokenDetails.reserveTokenList.length; i++) {

            if (smartTokenDetails.reserveTokenList[i].token == toToken) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            uint256 tokenBalanceAfter = smartTokenDetails.reserveTokenList[i].token.balanceOf(address(this));

            super._swap(
                smartTokenDetails.reserveTokenList[i].token == originalSUSD
                    ? susd : smartTokenDetails.reserveTokenList[i].token,
                toToken,
                tokenBalanceAfter.sub(tokenBalanceBefore[i]),
                dist,
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

        uint256[] memory dist = new uint256[](distribution.length);
        uint256 minFundAmount = uint256(-1);

        SmartTokenDetails memory smartTokenDetails = _getSmartTokenDetails(ISmartToken(address(toToken)));

        uint256 curFundAmount;
        for (uint16 i = 0; i < smartTokenDetails.reserveTokenList.length; i++) {

            uint256 exchangeAmount = _calcExchangeAmount(
                amount,
                smartTokenDetails.reserveTokenList[i].ratio,
                smartTokenDetails.totalReserveTokensRatio
            );

            if (smartTokenDetails.reserveTokenList[i].token != fromToken) {

                uint256 tokenBalanceBefore = smartTokenDetails.reserveTokenList[i].token.balanceOf(address(this));

                for (uint j = 0; j < distribution.length; j++) {
                    dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
                }

                super._swap(
                    fromToken,
                    smartTokenDetails.reserveTokenList[i].token == originalSUSD
                        ? susd : smartTokenDetails.reserveTokenList[i].token,
                    exchangeAmount,
                    dist,
                    disableFlags
                );

                uint256 tokenBalanceAfter = smartTokenDetails.reserveTokenList[i].token.balanceOf(address(this));

                curFundAmount = toToken.totalSupply()
                    .mul(tokenBalanceAfter.sub(tokenBalanceBefore))
                    .div(smartTokenDetails.reserveTokenList[i].token.balanceOf(smartTokenDetails.converter));

            } else {

                curFundAmount = toToken.totalSupply()
                    .mul(exchangeAmount)
                    .div(smartTokenDetails.reserveTokenList[i].token.balanceOf(smartTokenDetails.converter));

            }

            if (curFundAmount < minFundAmount) {
                minFundAmount = curFundAmount;
            }

            _infiniteApproveIfNeeded(smartTokenDetails.reserveTokenList[i].token, smartTokenDetails.converter);

        }

        smartTokenDetails.converter.call.gas(600000)(
            abi.encodeWithSelector(
                ISmartTokenConverter(smartTokenDetails.converter).fund.selector,
                minFundAmount
            )
        );

        dist = new uint256[](distribution.length);
        dist[2] = 1;

        // Swap leftovers for SmartToken
        for (uint16 i = 0; i < smartTokenDetails.reserveTokenList.length; i++) {

            uint256 tokenBalance =  smartTokenDetails.reserveTokenList[i].token.balanceOf(address(this));

            if (tokenBalance > 0) {

                super._swap(
                    smartTokenDetails.reserveTokenList[i].token == originalSUSD
                        ? susd : smartTokenDetails.reserveTokenList[i].token,
                    toToken,
                    tokenBalance,
                    dist,
                    FLAG_DISABLE_ALL_DEXES - FLAG_DISABLE_BANCOR
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
        (bool ok, bytes memory data) = address(converter).call.gas(300000)(
            abi.encodeWithSelector(
                converter.convert2.selector,
                _fromToken, _toToken, _amount, 1, address(0), 0
            )
        );

        if (ok) {
            return abi.decode(data, (uint256));
        }

        return converter.convert(_fromToken, _toToken, _amount, 1);
    }

}
