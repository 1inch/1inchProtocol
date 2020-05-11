pragma solidity ^0.5.0;

import "./OneSplitBase.sol";
import "./interface/ICurve.sol";


contract OneSplitCurveSusdPoolTokenBase {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    IERC20 constant curveSusdToken = IERC20(0xC25a3A3b969415c80451098fa907EC722572917F);
    ICurve constant curve = ICurve(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);

    struct CurveSusdTokenInfo {
        IERC20 token;
        uint256 weightedReserveBalance;
    }

    struct CurveSusdPoolTokenDetails {
        CurveSusdTokenInfo[] tokens;
        uint256 totalWeightedBalance;
    }

    function _getPoolDetails()
        internal
        view
        returns(CurveSusdPoolTokenDetails memory details)
    {
        details.tokens = new CurveSusdTokenInfo[](4);
        for (uint256 i = 0; i < 4; i++) {
            details.tokens[i].token = IERC20(curve.coins(int128(i)));
            details.tokens[i].weightedReserveBalance = curve.balances(int128(i))
                .mul(1e18).div(10 ** details.tokens[i].token.universalDecimals());
            details.totalWeightedBalance = details.totalWeightedBalance.add(
                details.tokens[i].weightedReserveBalance
            );
        }
    }
}


contract OneSplitCurveSusdPoolTokenView is OneSplitViewWrapBase, OneSplitCurveSusdPoolTokenBase {
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
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        private
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        uint256 totalSupply = poolToken.totalSupply();
        for (uint i = 0; i < 4; i++) {
            IERC20 coin = IERC20(curve.coins(int128(i)));

            uint256 tokenAmountOut = curve.balances(int128(i))
                .mul(amount)
                .div(totalSupply);

            if (coin == toToken) {
                returnAmount = returnAmount.add(tokenAmountOut);
                continue;
            }

            (uint256 ret, uint256[] memory dist) = this.getExpectedReturn(
                coin,
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
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        CurveSusdPoolTokenDetails memory details = _getPoolDetails();

        uint256[4] memory tokenAmounts;
        uint256[] memory dist;
        for (uint i = 0; i < 4; i++) {
            uint256 exchangeAmount = amount
                .mul(details.tokens[i].weightedReserveBalance)
                .div(details.totalWeightedBalance);

            if (details.tokens[i].token == fromToken) {
                tokenAmounts[i] = exchangeAmount;
                continue;
            }

            (tokenAmounts[i], dist) = this.getExpectedReturn(
                fromToken,
                details.tokens[i].token,
                exchangeAmount,
                parts,
                disableFlags
            );

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        returnAmount = curve.calc_token_amount(tokenAmounts, true);

        return (returnAmount, distribution);
    }
}


contract OneSplitCurveSusdPoolToken is OneSplitBaseWrap, OneSplitCurveSusdPoolTokenBase {
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
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) private {

        uint256 totalSupply = poolToken.totalSupply();
        uint256[4] memory minAmountsOut;
        for (uint i = 0; i < 4; i++) {
            minAmountsOut[i] = curve.balances(int128(i))
                .mul(amount)
                .div(totalSupply)
                .mul(995).div(1000); // 0.5% slippage;
        }

        curve.remove_liquidity(amount, minAmountsOut);

        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < 4; i++) {
            IERC20 coin = IERC20(curve.coins(int128(i)));

            if (coin == toToken) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            uint256 exchangeTokenAmount = coin.universalBalanceOf(address(this));

            this.swap(
                coin,
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

        CurveSusdPoolTokenDetails memory details = _getPoolDetails();

        uint256[4] memory tokenAmounts;
        for (uint i = 0; i < 4; i++) {
            uint256 exchangeAmount = amount
                .mul(details.tokens[i].weightedReserveBalance)
                .div(details.totalWeightedBalance);

            _infiniteApproveIfNeeded(details.tokens[i].token, address(curve));

            if (details.tokens[i].token == fromToken) {
                tokenAmounts[i] = exchangeAmount;
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            this.swap(
                fromToken,
                details.tokens[i].token,
                exchangeAmount,
                0,
                dist,
                disableFlags
            );

            tokenAmounts[i] = details.tokens[i].token.universalBalanceOf(address(this));
        }

        curve.add_liquidity(tokenAmounts, 0);
    }
}
