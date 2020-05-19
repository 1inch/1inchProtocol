pragma solidity ^0.5.0;

import "./interface/ISmartToken.sol";
import "./interface/ISmartTokenRegistry.sol";
import "./interface/ISmartTokenConverter.sol";
import "./interface/ISmartTokenFormula.sol";
import "./OneSplitBase.sol";


contract OneSplitSmartTokenBase {
    using SafeMath for uint256;

    ISmartTokenRegistry constant smartTokenRegistry = ISmartTokenRegistry(0xf6E2D7F616B67E46D708e4410746E9AAb3a4C518);
    ISmartTokenFormula constant smartTokenFormula = ISmartTokenFormula(0x524619EB9b4cdFFa7DA13029b33f24635478AFc0);
    IERC20 constant bntToken = IERC20(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);
    IERC20 constant usdbToken = IERC20(0x309627af60F0926daa6041B8279484312f2bf060);

    IERC20 constant susd = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    IERC20 constant acientSUSD = IERC20(0x57Ab1E02fEE23774580C119740129eAC7081e9D3);

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

        if (!success) {
            (, uint32 ratio, , ,) = converter.connectors(address(token));

            return uint256(ratio);
        }

        return abi.decode(data, (uint256));
    }

    function _canonicalSUSD(IERC20 token) internal pure returns(IERC20) {
        return token == acientSUSD ? susd : token;
    }
}


contract OneSplitSmartTokenView is OneSplitViewWrapBase, OneSplitSmartTokenBase {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256,
            uint256[] memory
        )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }

        if (!flags.check(FLAG_DISABLE_SMART_TOKEN)) {
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
                    FLAG_DISABLE_SMART_TOKEN
                );

                (
                    uint256 returnSmartTokenToAmount,
                    uint256[] memory smartTokenToDistribution
                ) = _getExpectedReturnToSmartToken(
                    bntToken,
                    toToken,
                    returnBntAmount,
                    parts,
                    FLAG_DISABLE_SMART_TOKEN
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
                    FLAG_DISABLE_SMART_TOKEN
                );
            }

            if (isSmartTokenTo) {
                return _getExpectedReturnToSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_SMART_TOKEN
                );
            }
        }

        return super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            flags
        );
    }

    function _getExpectedReturnFromSmartToken(
        IERC20 smartToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        SmartTokenDetails memory details = _getSmartTokenDetails(ISmartToken(address(smartToken)));

        for (uint i = 0; i < details.tokens.length; i++) {
            uint256 srcAmount = smartTokenFormula.calculateLiquidateReturn(
                smartToken.totalSupply(),
                _canonicalSUSD(details.tokens[i].token).balanceOf(details.converter),
                uint32(details.totalRatio),
                amount
            );

            if (details.tokens[i].token == toToken) {
                returnAmount = returnAmount.add(srcAmount);
                continue;
            }

            (uint256 ret, uint256[] memory dist) = this.getExpectedReturn(
                _canonicalSUSD(details.tokens[i].token),
                toToken,
                srcAmount,
                parts,
                flags
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
        uint256 flags
    )
        private
        view
        returns(
            uint256 minFundAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);
        minFundAmount = uint256(-1);

        SmartTokenDetails memory details = _getSmartTokenDetails(ISmartToken(address(smartToken)));

        uint256[] memory tokenAmounts = new uint256[](details.tokens.length);
        uint256[] memory dist;
        uint256[] memory fundAmounts = new uint256[](details.tokens.length);

        for (uint i = 0; i < details.tokens.length; i++) {
            uint256 exchangeAmount = amount
                .mul(details.tokens[i].ratio)
                .div(details.totalRatio);

            if (details.tokens[i].token != fromToken) {
                (tokenAmounts[i], dist) = this.getExpectedReturn(
                    fromToken,
                    _canonicalSUSD(details.tokens[i].token),
                    exchangeAmount,
                    parts,
                    flags
                );

                for (uint j = 0; j < distribution.length; j++) {
                    distribution[j] |= dist[j] << (i * 8);
                }
            } else {
                tokenAmounts[i] = exchangeAmount;
            }

            fundAmounts[i] = smartTokenFormula.calculatePurchaseReturn(
                smartToken.totalSupply(),
                _canonicalSUSD(details.tokens[i].token).balanceOf(details.converter),
                uint32(details.totalRatio),
                tokenAmounts[i]
            );

            if (fundAmounts[i] < minFundAmount) {
                minFundAmount = fundAmounts[i];
            }
        }

        return (minFundAmount, distribution);
    }
}


contract OneSplitSmartToken is OneSplitBaseWrap, OneSplitSmartTokenBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken == toToken) {
            return;
        }

        if (!flags.check(FLAG_DISABLE_SMART_TOKEN)) {

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
                    FLAG_DISABLE_SMART_TOKEN
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
                    FLAG_DISABLE_SMART_TOKEN
                );
            }

            if (isSmartTokenFrom) {
                return _swapFromSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_SMART_TOKEN
                );
            }

            if (isSmartTokenTo) {
                return _swapToSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_SMART_TOKEN
                );
            }
        }

        return super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            flags
        );
    }

    function _swapFromSmartToken(
        IERC20 smartToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
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
                _canonicalSUSD(details.tokens[i].token).balanceOf(address(this)),
                0,
                dist,
                flags
            );
        }
    }

    function _swapToSmartToken(
        IERC20 fromToken,
        IERC20 smartToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
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

                uint256 tokenBalanceBefore = _canonicalSUSD(details.tokens[i].token).balanceOf(address(this));

                for (uint j = 0; j < distribution.length; j++) {
                    dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
                }

                this.swap(
                    fromToken,
                    _canonicalSUSD(details.tokens[i].token),
                    exchangeAmount,
                    0,
                    dist,
                    flags
                );

                uint256 tokenBalanceAfter = _canonicalSUSD(details.tokens[i].token).balanceOf(address(this));

                curFundAmount = smartTokenFormula.calculatePurchaseReturn(
                    smartToken.totalSupply(),
                    _canonicalSUSD(details.tokens[i].token).balanceOf(details.converter),
                    uint32(details.totalRatio),
                    tokenBalanceAfter.sub(tokenBalanceBefore)
                );
            } else {
                curFundAmount = smartTokenFormula.calculatePurchaseReturn(
                    smartToken.totalSupply(),
                    _canonicalSUSD(details.tokens[i].token).balanceOf(details.converter),
                    uint32(details.totalRatio),
                    exchangeAmount
                );
            }

            if (curFundAmount < minFundAmount) {
                minFundAmount = curFundAmount;
            }

            _infiniteApproveIfNeeded(_canonicalSUSD(details.tokens[i].token), details.converter);
        }

        ISmartTokenConverter(details.converter).fund(minFundAmount);

        for (uint i = 0; i < details.tokens.length; i++) {
            IERC20 reserveToken = _canonicalSUSD(details.tokens[i].token);
            reserveToken.universalTransfer(
                msg.sender,
                reserveToken.universalBalanceOf(address(this))
            );
        }
    }
}
