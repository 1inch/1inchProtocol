// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IKyber.sol";
import "../IOneRouter.sol";
import "../ISource.sol";
import "../OneRouterConstants.sol";

import "../libraries/UniERC20.sol";
import "../libraries/FlagsChecker.sol";


library KyberHelper {
    using UniERC20 for IERC20;

    IKyberNetworkProxy constant public PROXY = IKyberNetworkProxy(0x9AAb3f75489902f3a48495025729a0AF77d4b11e);
    IKyberStorage constant public STORAGE = IKyberStorage(0xC8fb12402cB16970F3C5F4b48Ff68Eb9D1289301);
    IKyberHintHandler constant public HINT_HANDLER = IKyberHintHandler(0xa1C0Fa73c39CFBcC11ec9Eb1Afc665aba9996E2C);

    // https://github.com/CryptoManiacsZone/1inchProtocol/blob/master/KyberReserves.md
    bytes1 constant public RESERVE_BRIDGE_PREFIX = 0xbb;
    bytes32 constant public RESERVE_ID_1 = 0xff4b796265722046707200000000000000000000000000000000000000000000; // 0x63825c174ab367968EC60f061753D3bbD36A0D8F
    bytes32 constant public RESERVE_ID_2 = 0xffabcd0000000000000000000000000000000000000000000000000000000000; // 0x7a3370075a54B187d7bD5DceBf0ff2B5552d4F7D
    bytes32 constant public RESERVE_ID_3 = 0xff4f6e65426974205175616e7400000000000000000000000000000000000000; // 0x4f32BbE8dFc9efD54345Fc936f9fEF1048746fCF

    function getReserveId(IERC20 fromToken, IERC20 destToken) internal view returns(bytes32) {
        if (fromToken.isETH() || destToken.isETH()) {
            bytes32[] memory reserveIds = STORAGE.getReserveIdsPerTokenSrc(
                fromToken.isETH() ? destToken : fromToken
            );

            for (uint i = 0; i < reserveIds.length; i++) {
                if (reserveIds[i][0] != RESERVE_BRIDGE_PREFIX &&
                    reserveIds[i] != RESERVE_ID_1 &&
                    reserveIds[i] != RESERVE_ID_2 &&
                    reserveIds[i] != RESERVE_ID_3)
                {
                    return reserveIds[i];
                }
            }
        }
    }
}


contract KyberSourceView is OneRouterConstants {
    using SafeMath for uint256;
    using UniERC20 for IERC20;
    using FlagsChecker for uint256;

    function _calculateKyber1(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateKyber(fromToken, amounts, swap, KyberHelper.RESERVE_ID_1);
    }

    function _calculateKyber2(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateKyber(fromToken, amounts, swap, KyberHelper.RESERVE_ID_2);
    }

    function _calculateKyber3(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateKyber(fromToken, amounts, swap, KyberHelper.RESERVE_ID_3);
    }

    function _calculateKyber4(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        bytes32 reserveId = KyberHelper.getReserveId(fromToken, swap.destToken);
        if (reserveId != 0) {
            return _calculateKyber(fromToken, amounts, swap, reserveId);
        }
    }

    // Fix for "Stack too deep"
    struct Decimals {
        uint256 fromTokenDecimals;
        uint256 destTokenDecimals;
    }

    function _calculateKyber(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap, bytes32 reserveId) private view returns(uint256[] memory rets, address dex, uint256 gas) {
        rets = new uint256[](amounts.length);

        IKyberReserve reserve = KyberHelper.STORAGE.getReserveAddressesByReserveId(reserveId)[0];

        Decimals memory decimals = Decimals({
            fromTokenDecimals: 10 ** IERC20(fromToken).uniDecimals(),
            destTokenDecimals: 10 ** IERC20(swap.destToken).uniDecimals()
        });
        for (uint i = 0; i < amounts.length; i++) {
            if (i > 0 && rets[i - 1] == 0) {
                break;
            }

            uint256 amount = amounts[0].mul(uint256(1e18).sub((swap.flags >> 255) * 1e15)).div(1e18);
            try reserve.getConversionRate(
                fromToken.isETH() ? UniERC20.ETH_ADDRESS : fromToken,
                swap.destToken.isETH() ? UniERC20.ETH_ADDRESS : swap.destToken,
                amount,
                block.number
            )
            returns(uint256 rate) {
                uint256 preResult = amounts[i].mul(rate).mul(decimals.destTokenDecimals);
                rets[i] = preResult.div(decimals.fromTokenDecimals).div(1e18);
            } catch {
            }
        }

        return (rets, address(reserve), 100_000);
    }
}


contract KyberSourceSwap {
    using UniERC20 for IERC20;

    function _swapOnKyber1(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) internal {
        _swapOnKyber(fromToken, destToken, amount, flags, KyberHelper.RESERVE_ID_1);
    }

    function _swapOnKyber2(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) internal {
        _swapOnKyber(fromToken, destToken, amount, flags, KyberHelper.RESERVE_ID_2);
    }

    function _swapOnKyber3(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) internal {
        _swapOnKyber(fromToken, destToken, amount, flags, KyberHelper.RESERVE_ID_3);
    }

    function _swapOnKyber4(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) internal {
        _swapOnKyber(fromToken, destToken, amount, flags, KyberHelper.getReserveId(fromToken, destToken));
    }

    function _swapOnKyber(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags, bytes32 reserveId) internal {
        bytes32[] memory reserveIds = new bytes32[](1);
        reserveIds[0] = reserveId;

        bytes memory hint;
        if (fromToken.isETH()) {
            hint = KyberHelper.HINT_HANDLER.buildEthToTokenHint(destToken, IKyberHintHandler.TradeType.MaskIn, reserveIds, new uint256[](0));
        }
        else {
            hint = KyberHelper.HINT_HANDLER.buildTokenToEthHint(fromToken, IKyberHintHandler.TradeType.MaskIn, reserveIds, new uint256[](0));
        }

        fromToken.uniApprove(address(KyberHelper.PROXY), amount);
        KyberHelper.PROXY.tradeWithHintAndFee{ value: fromToken.isETH() ? amount : 0 }(
            fromToken,
            amount,
            destToken,
            payable(address(this)),
            uint256(-1),
            0,
            0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5,
            (flags >> 255) * 10,
            hint
        );
    }

    function _kyberGetHint(IERC20 fromToken, IERC20 destToken, bytes32 reserveId) private view returns(bytes memory) {
        bytes32[] memory reserveIds = new bytes32[](1);
        reserveIds[0] = reserveId;

        if (fromToken.isETH()) {
            try KyberHelper.HINT_HANDLER.buildEthToTokenHint(destToken, IKyberHintHandler.TradeType.MaskIn, reserveIds, new uint256[](0))
            returns (bytes memory data) {
                return data;
            } catch {}
        }

        if (destToken.isETH()) {
            try KyberHelper.HINT_HANDLER.buildTokenToEthHint(fromToken, IKyberHintHandler.TradeType.MaskIn, reserveIds, new uint256[](0))
            returns (bytes memory data) {
                return data;
            } catch {}
        }
    }
}


contract KyberSourcePublic1 is ISource, KyberSourceView, KyberSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateKyber1(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnKyber1(fromToken, destToken, amount, flags);
    }
}


contract KyberSourcePublic2 is ISource, KyberSourceView, KyberSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateKyber2(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnKyber2(fromToken, destToken, amount, flags);
    }
}


contract KyberSourcePublic3 is ISource, KyberSourceView, KyberSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateKyber3(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnKyber3(fromToken, destToken, amount, flags);
    }
}


contract KyberSourcePublic4 is ISource, KyberSourceView, KyberSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateKyber4(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnKyber4(fromToken, destToken, amount, flags);
    }
}
