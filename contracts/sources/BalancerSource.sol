// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IBalancer.sol";
import "../interfaces/IWETH.sol";
import "../IOneRouter.sol";
import "../ISource.sol";
import "../OneRouterConstants.sol";

import "../libraries/UniERC20.sol";
import "../libraries/BalancerLib.sol";
import "../libraries/FlagsChecker.sol";


library BalancerHelper {
    IWETH constant public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IBalancerRegistry constant public REGISTRY = IBalancerRegistry(0x65e67cbc342712DF67494ACEfc06fe951EE93982);
}


contract BalancerSourceView is OneRouterConstants {
    using SafeMath for uint256;
    using UniERC20 for IERC20;
    using FlagsChecker for uint256;

    struct BalancerPoolInfo {
        uint256 swapFee;
        uint256 fromBalance;
        uint256 destBalance;
        uint256 fromWeight;
        uint256 destWeight;
    }

    function _calculateBalancer1(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateBalancer(fromToken, swap.destToken, amounts, swap.flags, 0);
    }

    function _calculateBalancer2(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateBalancer(fromToken, swap.destToken, amounts, swap.flags, 1);
    }

    function _calculateBalancer3(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateBalancer(fromToken, swap.destToken, amounts, swap.flags, 2);
    }

    function _calculateBalancer(
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts,
        uint256 flags,
        uint256 poolIndex
    ) private view returns(uint256[] memory rets, address dex, uint256 gas) {
        rets = new uint256[](amounts.length);
        if (flags.check(_FLAG_DISABLE_ALL_SOURCES) != flags.check(_FLAG_DISABLE_BALANCER_ALL)) {
            return (rets, address(0), 0);
        }

        IERC20 fromTokenWrapped = fromToken.isETH() ? BalancerHelper.WETH : fromToken;
        IERC20 destTokenWrapped = destToken.isETH() ? BalancerHelper.WETH : destToken;
        IBalancerPool[] memory pools = BalancerHelper.REGISTRY.getBestPoolsWithLimit(fromTokenWrapped, destTokenWrapped, poolIndex + 1);
        if (poolIndex < pools.length) {
            BalancerPoolInfo memory info = BalancerPoolInfo({
                swapFee: pools[poolIndex].getSwapFee(),
                fromBalance: pools[poolIndex].getBalance(fromTokenWrapped),
                destBalance: pools[poolIndex].getBalance(destTokenWrapped),
                fromWeight: pools[poolIndex].getDenormalizedWeight(fromTokenWrapped),
                destWeight: pools[poolIndex].getDenormalizedWeight(destTokenWrapped)
            });

            for (uint i = 0; i < amounts.length && amounts[i].mul(2) <= info.fromBalance; i++) {
                rets[i] = BalancerLib.calcOutGivenIn(
                    info.fromBalance,
                    info.fromWeight,
                    info.destBalance,
                    info.destWeight,
                    amounts[i],
                    info.swapFee
                );
            }
            return (rets, address(pools[poolIndex]), 75_000 + (fromToken.isETH() || destToken.isETH() ? 0 : 30_000));
        }
    }
}


contract BalancerSourceSwap {
    using UniERC20 for IERC20;

    function _swapOnBalancer1(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) internal {
        _swapOnBalancer(fromToken, destToken, amount, flags, 0);
    }

    function _swapOnBalancer2(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) internal {
        _swapOnBalancer(fromToken, destToken, amount, flags, 1);
    }

    function _swapOnBalancer3(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) internal {
        _swapOnBalancer(fromToken, destToken, amount, flags, 2);
    }

    function _swapOnBalancer(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags,
        uint256 poolIndex
    ) private {
        if (fromToken.isETH()) {
            BalancerHelper.WETH.deposit{ value: amount }();
        }

        _swapOnBalancerWrapped(
            fromToken.isETH() ? BalancerHelper.WETH : fromToken,
            destToken.isETH() ? BalancerHelper.WETH : destToken,
            amount,
            flags,
            poolIndex
        );

        if (destToken.isETH()) {
            BalancerHelper.WETH.withdraw(BalancerHelper.WETH.balanceOf(address(this)));
        }
    }

    function _swapOnBalancerWrapped(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/,
        uint256 poolIndex
    ) private {
        IBalancerPool[] memory pools = BalancerHelper.REGISTRY.getBestPoolsWithLimit(fromToken, destToken, poolIndex + 1);
        fromToken.uniApprove(address(pools[poolIndex]), amount);
        IBalancerPool(pools[poolIndex]).swapExactAmountIn(
            fromToken,
            amount,
            destToken,
            0,
            uint256(-1)
        );
    }
}


contract BalancerSourcePublic1 is ISource, BalancerSourceView, BalancerSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateBalancer1(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnBalancer1(fromToken, destToken, amount, flags);
    }
}


contract BalancerSourcePublic2 is ISource, BalancerSourceView, BalancerSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateBalancer2(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnBalancer2(fromToken, destToken, amount, flags);
    }
}


contract BalancerSourcePublic3 is ISource, BalancerSourceView, BalancerSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateBalancer3(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnBalancer3(fromToken, destToken, amount, flags);
    }
}
