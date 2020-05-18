pragma solidity ^0.5.0;

import "./OneSplitBase.sol";
import "./interface/ICurve.sol";


contract OneSplitCurvePoolTokenBase {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    IERC20 constant curveSusdToken = IERC20(0xC25a3A3b969415c80451098fa907EC722572917F);
    IERC20 constant curveIearnToken = IERC20(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
    IERC20 constant curveCompoundToken = IERC20(0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2);
    IERC20 constant curveUsdtToken = IERC20(0x9fC689CCaDa600B6DF723D9E47D84d76664a1F23);
    IERC20 constant curveBinanceToken = IERC20(0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B);
    IERC20 constant curvePaxToken = IERC20(0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8);
    IERC20 constant curveRenBtcToken = IERC20(0x7771F704490F9C0C3B06aFe8960dBB6c58CBC812);
    IERC20 constant curveTBtcToken = IERC20(0x1f2a662FB513441f06b8dB91ebD9a1466462b275);

    ICurve constant curveSusd = ICurve(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);
    ICurve constant curveIearn = ICurve(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    ICurve constant curveCompound = ICurve(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56);
    ICurve constant curveUsdt = ICurve(0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C);
    ICurve constant curveBinance = ICurve(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27);
    ICurve constant curvePax = ICurve(0x06364f10B501e868329afBc005b3492902d6C763);
    ICurve constant curveRenBtc = ICurve(0x8474c1236F0Bc23830A23a41aBB81B2764bA9f4F);
    ICurve constant curveTBtc = ICurve(0x9726e9314eF1b96E45f40056bEd61A088897313E);

    struct CurveTokenInfo {
        IERC20 token;
        uint256 weightedReserveBalance;
    }

    struct CurveInfo {
        ICurve curve;
        uint256 tokenCount;
    }

    struct CurvePoolTokenDetails {
        CurveTokenInfo[] tokens;
        uint256 totalWeightedBalance;
    }

    function _isPoolToken(IERC20 token)
        internal
        pure
        returns (bool)
    {
        if (
            token == curveSusdToken ||
            token == curveIearnToken ||
            token == curveCompoundToken ||
            token == curveUsdtToken ||
            token == curveBinanceToken ||
            token == curvePaxToken ||
            token == curveRenBtcToken ||
            token == curveTBtcToken
        ) {
            return true;
        }
        return false;
    }

    function _getCurve(IERC20 poolToken)
        internal
        pure
        returns (CurveInfo memory curveInfo)
    {
        if (poolToken == curveSusdToken) {
            curveInfo.curve = curveSusd;
            curveInfo.tokenCount = 4;
            return curveInfo;
        }

        if (poolToken == curveIearnToken) {
            curveInfo.curve = curveIearn;
            curveInfo.tokenCount = 4;
            return curveInfo;
        }

        if (poolToken == curveCompoundToken) {
            curveInfo.curve = curveCompound;
            curveInfo.tokenCount = 2;
            return curveInfo;
        }

        if (poolToken == curveUsdtToken) {
            curveInfo.curve = curveUsdt;
            curveInfo.tokenCount = 3;
            return curveInfo;
        }

        if (poolToken == curveBinanceToken) {
            curveInfo.curve = curveBinance;
            curveInfo.tokenCount = 4;
            return curveInfo;
        }

        if (poolToken == curvePaxToken) {
            curveInfo.curve = curvePax;
            curveInfo.tokenCount = 4;
            return curveInfo;
        }

        if (poolToken == curveRenBtcToken) {
            curveInfo.curve = curveRenBtc;
            curveInfo.tokenCount = 2;
            return curveInfo;
        }

        if (poolToken == curveTBtcToken) {
            curveInfo.curve = curveTBtc;
            curveInfo.tokenCount = 3;
            return curveInfo;
        }

        revert();
    }

    function _getCurveCalcTokenAmountSelector(uint256 tokenCount)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(
            "calc_token_amount(uint256[", uint8(48 + tokenCount) ,"],bool)"
        )));
    }

    function _getCurveRemoveLiquiditySelector(uint256 tokenCount)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(
            "remove_liquidity(uint256,uint256[", uint8(48 + tokenCount) ,"])"
        )));
    }

    function _getCurveAddLiquiditySelector(uint256 tokenCount)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(
            "add_liquidity(uint256[", uint8(48 + tokenCount) ,"],uint256)"
        )));
    }

    function _getPoolDetails(ICurve curve, uint256 tokenCount)
        internal
        view
        returns(CurvePoolTokenDetails memory details)
    {
        details.tokens = new CurveTokenInfo[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            details.tokens[i].token = IERC20(curve.coins(int128(i)));
            details.tokens[i].weightedReserveBalance = curve.balances(int128(i))
                .mul(1e18).div(10 ** details.tokens[i].token.universalDecimals());
            details.totalWeightedBalance = details.totalWeightedBalance.add(
                details.tokens[i].weightedReserveBalance
            );
        }
    }
}


contract OneSplitCurvePoolTokenView is OneSplitViewWrapBase, OneSplitCurvePoolTokenBase {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
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


        if (!flags.check(FLAG_DISABLE_CURVE_ZAP)) {
            if (_isPoolToken(fromToken)) {
                return _getExpectedReturnFromCurvePoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_CURVE_ZAP
                );
            }

            if (_isPoolToken(toToken)) {
                return _getExpectedReturnToCurvePoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_CURVE_ZAP
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

    function _getExpectedReturnFromCurvePoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        CurveInfo memory curveInfo = _getCurve(poolToken);
        uint256 totalSupply = poolToken.totalSupply();
        for (uint i = 0; i < curveInfo.tokenCount; i++) {
            IERC20 coin = IERC20(curveInfo.curve.coins(int128(i)));

            uint256 tokenAmountOut = curveInfo.curve.balances(int128(i))
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
                flags
            );

            returnAmount = returnAmount.add(ret);

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        return (returnAmount, distribution);
    }

    function _getExpectedReturnToCurvePoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        CurveInfo memory curveInfo = _getCurve(poolToken);
        CurvePoolTokenDetails memory details = _getPoolDetails(
            curveInfo.curve,
            curveInfo.tokenCount
        );

        bytes memory tokenAmounts;
        for (uint i = 0; i < curveInfo.tokenCount; i++) {
            uint256 exchangeAmount = amount
                .mul(details.tokens[i].weightedReserveBalance)
                .div(details.totalWeightedBalance);

            if (details.tokens[i].token == fromToken) {
                tokenAmounts = abi.encodePacked(tokenAmounts, exchangeAmount);
                continue;
            }

            (uint256 tokenAmount, uint256[] memory dist) = this.getExpectedReturn(
                fromToken,
                details.tokens[i].token,
                exchangeAmount,
                parts,
                flags
            );

            tokenAmounts = abi.encodePacked(tokenAmounts, tokenAmount);

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        (bool success, bytes memory data) = address(curveInfo.curve).staticcall(
            abi.encodePacked(
                _getCurveCalcTokenAmountSelector(curveInfo.tokenCount),
                tokenAmounts,
                uint256(1)
            )
        );

        require(success, 'calc_token_amount failed');

        return (abi.decode(data, (uint256)), distribution);
    }
}


contract OneSplitCurvePoolToken is OneSplitBaseWrap, OneSplitCurvePoolTokenBase {
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

        if (!flags.check(FLAG_DISABLE_CURVE_ZAP)) {
            if (_isPoolToken(fromToken)) {
                return _swapFromCurvePoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_CURVE_ZAP
                );
            }

            if (_isPoolToken(toToken)) {
                return _swapToCurvePoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_CURVE_ZAP
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

    function _swapFromCurvePoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        CurveInfo memory curveInfo = _getCurve(poolToken);

        bytes memory minAmountsOut;
        for (uint i = 0; i < curveInfo.tokenCount; i++) {
            minAmountsOut = abi.encodePacked(minAmountsOut, uint256(1));
        }

        (bool success,) = address(curveInfo.curve).call(
            abi.encodePacked(
                _getCurveRemoveLiquiditySelector(curveInfo.tokenCount),
                amount,
                minAmountsOut
            )
        );

        require(success, 'remove_liquidity failed');

        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < curveInfo.tokenCount; i++) {
            IERC20 coin = IERC20(curveInfo.curve.coins(int128(i)));

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
                flags
            );
        }
    }

    function _swapToCurvePoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        uint256[] memory dist = new uint256[](distribution.length);

        CurveInfo memory curveInfo = _getCurve(poolToken);
        CurvePoolTokenDetails memory details = _getPoolDetails(
            curveInfo.curve,
            curveInfo.tokenCount
        );

        bytes memory tokenAmounts;
        for (uint i = 0; i < curveInfo.tokenCount; i++) {
            uint256 exchangeAmount = amount
                .mul(details.tokens[i].weightedReserveBalance)
                .div(details.totalWeightedBalance);

            _infiniteApproveIfNeeded(details.tokens[i].token, address(curveInfo.curve));

            if (details.tokens[i].token == fromToken) {
                tokenAmounts = abi.encodePacked(tokenAmounts, exchangeAmount);
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
                flags
            );

            tokenAmounts = abi.encodePacked(
                tokenAmounts,
                details.tokens[i].token.universalBalanceOf(address(this))
            );
        }

        (bool success,) = address(curveInfo.curve).call(
            abi.encodePacked(
                _getCurveAddLiquiditySelector(curveInfo.tokenCount),
                tokenAmounts,
                uint256(0)
            )
        );

        require(success, 'add_liquidity failed');
    }
}
