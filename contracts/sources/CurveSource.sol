// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/ICurve.sol";
import "../IOneRouter.sol";
import "../ISource.sol";
import "../OneRouterConstants.sol";

import "../libraries/UniERC20.sol";
import "../libraries/FlagsChecker.sol";


library CurveHelper {
    ICurve constant public CURVE_COMPOUND = ICurve(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56);
    ICurve constant public CURVE_USDT = ICurve(0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C);
    ICurve constant public CURVE_Y = ICurve(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    ICurve constant public CURVE_BINANCE = ICurve(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27);
    ICurve constant public CURVE_SYNTHETIX = ICurve(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);
    ICurve constant public CURVE_PAX = ICurve(0x06364f10B501e868329afBc005b3492902d6C763);
    ICurve constant public CURVE_RENBTC = ICurve(0x93054188d876f558f4a66B2EF1d97d16eDf0895B);
    ICurve constant public CURVE_SBTC = ICurve(0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714);

    function dynarr(IERC20[2] memory tokens) internal pure returns(IERC20[] memory result) {
        result = new IERC20[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            result[i] = tokens[i];
        }
    }

    function dynarr(IERC20[3] memory tokens) internal pure returns(IERC20[] memory result) {
        result = new IERC20[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            result[i] = tokens[i];
        }
    }

    function dynarr(IERC20[4] memory tokens) internal pure returns(IERC20[] memory result) {
        result = new IERC20[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            result[i] = tokens[i];
        }
    }
}


contract CurveSourceView is OneRouterConstants {
    using SafeMath for uint256;
    using UniERC20 for IERC20;
    using FlagsChecker for uint256;

    ICurveCalculator constant private _CURVE_CALCULATOR = ICurveCalculator(0xc1DB00a8E5Ef7bfa476395cdbcc98235477cDE4E);
    ICurveRegistry constant private _CURVE_REGISTRY = ICurveRegistry(0x7002B727Ef8F5571Cb5F9D70D13DBEEb4dFAe9d1);

    function _calculateCurveCompound(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap.destToken, amounts, CurveHelper.CURVE_COMPOUND, true, CurveHelper.dynarr([_DAI, _USDC])), address(CurveHelper.CURVE_COMPOUND), 720_000);
    }

    function _calculateCurveUSDT(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap.destToken, amounts, CurveHelper.CURVE_USDT, true, CurveHelper.dynarr([_DAI, _USDC, _USDT])), address(CurveHelper.CURVE_USDT), 720_000);
    }

    function _calculateCurveY(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap.destToken, amounts, CurveHelper.CURVE_Y, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _TUSD])), address(CurveHelper.CURVE_Y), 1_400_000);
    }

    function _calculateCurveBinance(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap.destToken, amounts, CurveHelper.CURVE_BINANCE, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _BUSD])), address(CurveHelper.CURVE_BINANCE), 1_400_000);
    }

    function _calculateCurveSynthetix(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap.destToken, amounts, CurveHelper.CURVE_SYNTHETIX, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _SUSD])), address(CurveHelper.CURVE_SYNTHETIX), 200_000);
    }

    function _calculateCurvePAX(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap.destToken, amounts, CurveHelper.CURVE_PAX, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _PAX])), address(CurveHelper.CURVE_PAX), 1_000_000);
    }

    function _calculateCurveRENBTC(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap.destToken, amounts, CurveHelper.CURVE_RENBTC, false, CurveHelper.dynarr([_RENBTC, _WBTC])), address(CurveHelper.CURVE_RENBTC), 130_000);
    }

    function _calculateCurveSBTC(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap.destToken, amounts, CurveHelper.CURVE_SBTC, false, CurveHelper.dynarr([_RENBTC, _WBTC, _SBTC])), address(CurveHelper.CURVE_SBTC), 150_000);
    }

    function _calculateCurveSelector(
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts,
        ICurve curve,
        bool haveUnderlying,
        IERC20[] memory tokens
    ) private view returns(uint256[] memory rets) {
        rets = new uint256[](amounts.length);

        int128 i = 0;
        int128 j = 0;
        for (uint t = 0; t < tokens.length; t++) {
            if (fromToken == tokens[t]) {
                i = int128(t + 1);
            }
            if (destToken == tokens[t]) {
                j = int128(t + 1);
            }
        }

        if (i == 0 || j == 0) {
            return rets;
        }

        bytes memory data = abi.encodePacked(
            uint256(haveUnderlying ? 1 : 0),
            uint256(i - 1),
            uint256(j - 1),
            _toFixedArray100(amounts)
        );

        (
            uint256[8] memory balances,
            uint256[8] memory precisions,
            uint256[8] memory rates,
            uint256 amp,
            uint256 fee
        ) = _getCurvePoolInfo(curve, haveUnderlying);

        bool success;
        (success, data) = address(_CURVE_CALCULATOR).staticcall(
            abi.encodePacked(
                abi.encodeWithSelector(
                    _CURVE_CALCULATOR.get_dy.selector,
                    tokens.length,
                    balances,
                    amp,
                    fee,
                    rates,
                    precisions
                ),
                data
            )
        );

        if (!success || data.length == 0) {
            return rets;
        }

        uint256[100] memory dy = abi.decode(data, (uint256[100]));
        for (uint t = 0; t < amounts.length; t++) {
            rets[t] = dy[t];
        }
    }

    function _getCurvePoolInfo(
        ICurve curve,
        bool haveUnderlying
    ) private view returns(
        uint256[8] memory balances,
        uint256[8] memory precisions,
        uint256[8] memory rates,
        uint256 amp,
        uint256 fee
    ) {
        uint256[8] memory underlyingBalances;
        uint256[8] memory decimals;
        uint256[8] memory underlyingDecimals;

        (
            balances,
            underlyingBalances,
            decimals,
            underlyingDecimals,
            /*address lpToken*/,
            amp,
            fee
        ) = _CURVE_REGISTRY.get_pool_info(address(curve));

        for (uint k = 0; k < 8 && balances[k] > 0; k++) {
            precisions[k] = 10 ** (18 - (haveUnderlying ? underlyingDecimals : decimals)[k]);
            if (haveUnderlying) {
                rates[k] = underlyingBalances[k].mul(1e18).div(balances[k]);
            } else {
                rates[k] = 1e18;
            }
        }
    }

    function _toFixedArray100(uint256[] memory values) private pure returns(uint256[100] memory rets) {
        for (uint i = 0; i < values.length; i++) {
            rets[i] = values[i];
        }
    }
}


contract CurveSourceSwap is OneRouterConstants {
    using UniERC20 for IERC20;

    function _swapOnCurveCompound(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_COMPOUND, true, CurveHelper.dynarr([_DAI, _USDC]), fromToken, destToken, amount);
    }

    function _swapOnCurveUSDT(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_USDT, true, CurveHelper.dynarr([_DAI, _USDC, _USDT]), fromToken, destToken, amount);
    }

    function _swapOnCurveY(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_Y, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _TUSD]), fromToken, destToken, amount);
    }

    function _swapOnCurveBinance(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_BINANCE, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _BUSD]), fromToken, destToken, amount);
    }

    function _swapOnCurveSynthetix(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_SYNTHETIX, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _SUSD]), fromToken, destToken, amount);
    }

    function _swapOnCurvePAX(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_PAX, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _PAX]), fromToken, destToken, amount);
    }

    function _swapOnCurveRENBTC(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_RENBTC, false, CurveHelper.dynarr([_RENBTC, _WBTC]), fromToken, destToken, amount);
    }

    function _swapOnCurveSBTC(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_SBTC, false, CurveHelper.dynarr([_RENBTC, _WBTC, _SBTC]), fromToken, destToken, amount);
    }

    function _swapOnCurve(
        ICurve curve,
        bool underlying,
        IERC20[] memory tokens,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) private {
        int128 i = 0;
        int128 j = 0;
        for (uint t = 0; t < tokens.length; t++) {
            if (fromToken == tokens[t]) {
                i = int128(t + 1);
            }
            if (destToken == tokens[t]) {
                j = int128(t + 1);
            }
        }

        fromToken.uniApprove(address(curve), amount);
        if (underlying) {
            curve.exchange_underlying(i - 1, j - 1, amount, 0);
        } else {
            curve.exchange(i - 1, j - 1, amount, 0);
        }
    }
}


contract CurveourcePublicCompound is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurveCompound(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurveCompound(fromToken, destToken, amount, flags);
    }
}


contract CurveourcePublicUSDT is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurveUSDT(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurveUSDT(fromToken, destToken, amount, flags);
    }
}


contract CurveourcePublicY is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurveY(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurveY(fromToken, destToken, amount, flags);
    }
}


contract CurveourcePublicBinance is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurveBinance(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurveBinance(fromToken, destToken, amount, flags);
    }
}


contract CurveourcePublicSynthetix is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurveSynthetix(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurveSynthetix(fromToken, destToken, amount, flags);
    }
}


contract CurveourcePublicPAX is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurvePAX(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurvePAX(fromToken, destToken, amount, flags);
    }
}


contract CurveourcePublicRENBTC is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurveRENBTC(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurveRENBTC(fromToken, destToken, amount, flags);
    }
}


contract CurveourcePublicSBTC is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurveSBTC(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurveSBTC(fromToken, destToken, amount, flags);
    }
}
