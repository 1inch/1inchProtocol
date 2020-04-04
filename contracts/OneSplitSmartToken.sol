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
    IERC20 usdbToken = IERC20(0x309627af60F0926daa6041B8279484312f2bf060);

    IERC20 public susd = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    IERC20 public acientSUSD = IERC20(0x57Ab1E02fEE23774580C119740129eAC7081e9D3);

    struct TokenWithRatio {
        IERC20 token;
        uint256 ratio;
    }

    struct SmartTokenDetails {
        TokenWithRatio[] tokens;
        address converter;
        uint256 totalRatio;
    }

    function _getSmartTokenDetails(ISmartToken smartToken)
        internal
        view
        returns(SmartTokenDetails memory details)
    {
        ISmartTokenConverter converter = smartToken.owner();
        details.converter = address(converter);
        details.tokens = new TokenWithRatio[](converter.connectorTokenCount());

        for (uint256 i = 0; i < details.tokens.length; i++) {
            details.tokens[i].token = converter.connectorTokens(i);
            details.tokens[i].ratio = _getReserveRatio(converter, details.tokens[i].token);
            details.totalRatio = details.totalRatio.add(details.tokens[i].ratio);
        }
    }

    function _getReserveRatio(
        ISmartTokenConverter converter,
        IERC20 token
    )
        internal
        view
        returns (uint256)
    {
        (bool success, bytes memory data) = address(converter).staticcall.gas(10000)(
            abi.encodeWithSelector(
                converter.getReserveRatio.selector,
                token
            )
        );

        if (success) {
            return abi.decode(data, (uint256));
        }

        (, uint32 ratio, , ,) = converter.connectors(address(token));

        return uint256(ratio);
    }

    function _canonicalSUSD(IERC20 token) internal view returns(IERC20) {
        return token == acientSUSD ? susd : token;
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
                    0
                );

                (
                    uint256 returnSmartTokenToAmount,
                    uint256[] memory smartTokenToDistribution
                ) = _getExpectedReturnToSmartToken(
                    bntToken,
                    toToken,
                    returnBntAmount,
                    parts,
                    0
                );

                for (uint i = 0; i < smartTokenToDistribution.length; i++) {
                    smartTokenFromDistribution[i] |= smartTokenToDistribution[i] << 128;
                }

                return (returnSmartTokenToAmount, smartTokenFromDistribution);
            }

            if (isSmartTokenFrom) {
                return _getExpectedReturnFromSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    0
                );
            }

            if (isSmartTokenTo) {
                return _getExpectedReturnToSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    0
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
        IERC20 smartToken,
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

        SmartTokenDetails memory details = _getSmartTokenDetails(ISmartToken(address(smartToken)));

        for (uint i = 0; i < details.tokens.length; i++) {
            uint256 srcAmount = smartTokenFormula.calculateLiquidateReturn(
                smartToken.totalSupply(),
                details.tokens[i].token.balanceOf(details.converter),
                uint32(details.totalRatio),
                amount
            );

            if (details.tokens[i].token == toToken) {
                returnAmount = returnAmount.add(srcAmount);
                continue;
            }

            (uint256 ret, uint256[] memory dist) = getExpectedReturn(
                _canonicalSUSD(details.tokens[i].token),
                toToken,
                srcAmount,
                parts,
                disableFlags
            );

            returnAmount = returnAmount.add(ret);
            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        return (returnAmount, distribution);
    }

    function _getExpectedReturnToSmartToken(
        IERC20 fromToken,
        IERC20 smartToken,
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

        SmartTokenDetails memory details = _getSmartTokenDetails(ISmartToken(address(smartToken)));

        uint256[] memory tokenAmounts;
        uint256[] memory dist;
        uint256[] memory fundAmounts = new uint256[](details.tokens.length);

        for (uint i = 0; i < details.tokens.length; i++) {
            uint256 exchangeAmount = amount
                .mul(details.tokens[i].ratio)
                .div(details.totalRatio);

            if (details.tokens[i].token != fromToken) {
                (tokenAmounts[i], dist) = getExpectedReturn(
                    fromToken,
                    _canonicalSUSD(details.tokens[i].token),
                    exchangeAmount,
                    parts,
                    disableFlags
                );

                for (uint j = 0; j < distribution.length; j++) {
                    distribution[j] |= dist[j] << (i * 8);
                }
            } else {
                tokenAmounts[i] = exchangeAmount;
            }

            fundAmounts[i] = smartTokenFormula.calculatePurchaseReturn(
                smartToken.totalSupply(),
                details.tokens[i].token.balanceOf(details.converter),
                uint32(details.totalRatio),
                tokenAmounts[i]
            );

            if (fundAmounts[i] < minFundAmount) {
                minFundAmount = fundAmounts[i];
            }
        }

        uint256 _minFundAmount = minFundAmount;
        IERC20 _smartToken = smartToken;

        // Swap leftovers for SmartToken
        for (uint i = 0; i < details.tokens.length; i++) {
            if (_minFundAmount == fundAmounts[i]) {
                continue;
            }

            uint256 leftover = tokenAmounts[i].sub(
                smartTokenFormula.calculateLiquidateReturn(
                    _smartToken.totalSupply(),
                    details.tokens[i].token.balanceOf(details.converter),
                    uint32(details.totalRatio),
                    fundAmounts[i]
                )
            );

            uint256 tokenRet = calculateBancorReturn(
                _canonicalSUSD(details.tokens[i].token),
                _smartToken,
                leftover,
                disableFlags
            );

            minFundAmount = minFundAmount.add(tokenRet);
        }

        return (minFundAmount, distribution);
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
                    0
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
                    0
                );
            }

            if (isSmartTokenFrom) {
                return _swapFromSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    0
                );
            }

            if (isSmartTokenTo) {
                return _swapToSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    0
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
        IERC20 smartToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) private {
        SmartTokenDetails memory details = _getSmartTokenDetails(ISmartToken(address(smartToken)));

        ISmartTokenConverter(details.converter).liquidate(amount);

        uint256[] memory dist = new uint256[](distribution.length);

        for (uint i = 0; i < details.tokens.length; i++) {
            if (details.tokens[i].token == toToken) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            this.swap(
                _canonicalSUSD(details.tokens[i].token),
                toToken,
                details.tokens[i].token.balanceOf(address(this)),
                0,
                dist,
                disableFlags
            );
        }
    }

    function _swapToSmartToken(
        IERC20 fromToken,
        IERC20 smartToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) private {

        uint256[] memory dist = new uint256[](distribution.length);
        uint256 minFundAmount = uint256(-1);

        SmartTokenDetails memory details = _getSmartTokenDetails(ISmartToken(address(smartToken)));

        uint256 curFundAmount;
        for (uint i = 0; i < details.tokens.length; i++) {
            uint256 exchangeAmount = amount
                .mul(details.tokens[i].ratio)
                .div(details.totalRatio);

            if (details.tokens[i].token != fromToken) {

                uint256 tokenBalanceBefore = details.tokens[i].token.balanceOf(address(this));

                for (uint j = 0; j < distribution.length; j++) {
                    dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
                }

                super._swap(
                    fromToken,
                    _canonicalSUSD(details.tokens[i].token),
                    exchangeAmount,
                    dist,
                    disableFlags
                );

                uint256 tokenBalanceAfter = details.tokens[i].token.balanceOf(address(this));

                curFundAmount = smartTokenFormula.calculatePurchaseReturn(
                    smartToken.totalSupply(),
                    details.tokens[i].token.balanceOf(details.converter),
                    uint32(details.totalRatio),
                    tokenBalanceAfter.sub(tokenBalanceBefore)
                );
            } else {
                curFundAmount = smartTokenFormula.calculatePurchaseReturn(
                    smartToken.totalSupply(),
                    details.tokens[i].token.balanceOf(details.converter),
                    uint32(details.totalRatio),
                    exchangeAmount
                );
            }

            if (curFundAmount < minFundAmount) {
                minFundAmount = curFundAmount;
            }

            _infiniteApproveIfNeeded(details.tokens[i].token, details.converter);
        }

        ISmartTokenConverter(details.converter).fund(minFundAmount);

        // Swap leftovers for SmartToken
        for (uint i = 0; i < details.tokens.length; i++) {
            _swapOnBancorSafe(
                _canonicalSUSD(details.tokens[i].token),
                smartToken,
                details.tokens[i].token.balanceOf(address(this))
            );
        }
    }
}
