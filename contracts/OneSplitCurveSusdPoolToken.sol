pragma solidity ^0.5.0;

import "./OneSplitBase.sol";
import "./interface/ICurve.sol";


contract OneSplitCurveSusdPoolTokenBase {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    ISusdCurve curve = ISusdCurve(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);
    IERC20 curveSusdToken = IERC20(0xC25a3A3b969415c80451098fa907EC722572917F);

    struct TokenInfo {
        IERC20 token;
        uint256 reserveBalance;
    }

    struct PoolTokenDetails {
        TokenInfo[] tokens;
        uint256 totalSupply;
    }

    function _getPoolDetails()
        internal
        view
        returns(PoolTokenDetails memory details)
    {
        details.tokens = new TokenInfo[](4);
        details.totalSupply = curveSusdToken.totalSupply();
        for (uint256 i = 0; i < 4; i++) {
            details.tokens[i].token = IERC20(curve.coins(int128(i)));
            details.tokens[i].reserveBalance = curve.balances(int128(i));
        }
    }

}

contract OneSplitCurveSusdPoolTokenView is OneSplitBaseView, OneSplitCurveSusdPoolTokenBase {

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        internal
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }


        if (!disableFlags.check(FLAG_DISABLE_CURVE_SUSD_POOL_TOKEN)) {
            if (fromToken == curveSusdToken) {
                return _getExpectedReturnFromCurveSusdPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_CURVE_SUSD_POOL_TOKEN
                );
            }

            if (toToken == curveSusdToken) {
                return _getExpectedReturnToCurveSusdPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_CURVE_SUSD_POOL_TOKEN
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

    function _getExpectedReturnFromCurveSusdPoolToken(
        IERC20, // poolToken
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        private
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        PoolTokenDetails memory details = _getPoolDetails();

        uint256 ratio = amount.mul(1e18).div(details.totalSupply);
        for (uint i = 0; i < 4; i++) {
            uint256 tokenAmountOut = details.tokens[i].reserveBalance.mul(ratio).div(1e18);

            if (details.tokens[i].token == toToken) {
                returnAmount = returnAmount.add(tokenAmountOut);
                continue;
            }

            (uint256 ret, uint256[] memory dist) = getExpectedReturn(
                details.tokens[i].token,
                toToken,
                tokenAmountOut,
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

    function _getExpectedReturnToCurveSusdPoolToken(
        IERC20 fromToken,
        IERC20, // poolToken
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        private
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        PoolTokenDetails memory details = _getPoolDetails();

        uint256[4] memory tokenAmounts;
        uint256[] memory dist;
        uint256 exchangeAmountPart = amount.div(4);
        for (uint i = 0; i < 4; i++) {

            if (details.tokens[i].token != fromToken) {
                (tokenAmounts[i], dist) = getExpectedReturn(
                    fromToken,
                    details.tokens[i].token,
                    i != 3 ? exchangeAmountPart : exchangeAmountPart.add(exchangeAmountPart % 4),
                    parts,
                    disableFlags
                );

                for (uint j = 0; j < distribution.length; j++) {
                    distribution[j] |= dist[j] << (i * 8);
                }
            } else {
                tokenAmounts[i] = i != 3 ? exchangeAmountPart : exchangeAmountPart.add(exchangeAmountPart % 4);
            }
        }

        returnAmount = curve.calc_token_amount(tokenAmounts, true);

        return (returnAmount, distribution);
    }

}


contract OneSplitCurveSusdPoolToken is OneSplitBase, OneSplitCurveSusdPoolTokenBase {
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

        if (!disableFlags.check(FLAG_DISABLE_CURVE_SUSD_POOL_TOKEN)) {
            if (fromToken == curveSusdToken) {
                return _swapFromCurveSusdPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_CURVE_SUSD_POOL_TOKEN
                );
            }

            if (toToken == curveSusdToken) {
                return _swapToCurveSusdPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_CURVE_SUSD_POOL_TOKEN
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

    function _swapFromCurveSusdPoolToken(
        IERC20, // poolToken
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) private {

        PoolTokenDetails memory details = _getPoolDetails();

        uint256 ratio = amount.mul(1e18).div(details.totalSupply);

        uint256[4] memory minAmountsOut;
        for (uint i = 0; i < 4; i++) {
            minAmountsOut[i] = details.tokens[i].reserveBalance.mul(ratio).div(1e18).mul(995).div(1000); // 0.5% slippage;
        }

        curve.remove_liquidity(amount, minAmountsOut);

        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < 4; i++) {

            if (details.tokens[i].token == toToken) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            uint256 exchangeTokenAmount = details.tokens[i].token.balanceOf(address(this));

            this.swap(
                details.tokens[i].token,
                toToken,
                exchangeTokenAmount,
                0,
                dist,
                disableFlags
            );
        }

    }

    function _swapToCurveSusdPoolToken(
        IERC20 fromToken,
        IERC20, // poolToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) private {
        uint256[] memory dist = new uint256[](distribution.length);

        PoolTokenDetails memory details = _getPoolDetails();

        uint256[4] memory tokenAmounts;
        uint256 exchangeAmountPart = amount.div(4);
        for (uint i = 0; i < 4; i++) {

            if (details.tokens[i].token != fromToken) {
                uint256 tokenBalanceBefore = details.tokens[i].token.balanceOf(address(this));

                for (uint j = 0; j < distribution.length; j++) {
                    dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
                }

                this.swap(
                    fromToken,
                    details.tokens[i].token,
                    i != 3 ? exchangeAmountPart : exchangeAmountPart.add(exchangeAmountPart % 4),
                    0,
                    dist,
                    disableFlags
                );

                uint256 tokenBalanceAfter = details.tokens[i].token.balanceOf(address(this));

                tokenAmounts[i] = tokenBalanceAfter.sub(tokenBalanceBefore);
            } else {
                tokenAmounts[i] = i != 3 ? exchangeAmountPart : exchangeAmountPart.add(exchangeAmountPart % 4);
            }

            _infiniteApproveIfNeeded(details.tokens[i].token, address(curve));
        }

        uint256 minAmount = curve.calc_token_amount(tokenAmounts, true);

        // 0.5% slippage
        curve.add_liquidity(tokenAmounts, minAmount.mul(995).div(1000));
    }
}
