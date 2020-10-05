// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/ICompound.sol";
import "../IOneRouterView.sol";
import "../ISource.sol";

import "../libraries/UniERC20.sol";


library CompoundLib {
    ICompoundRegistry constant public COMPOUND_REGISTRY = ICompoundRegistry(0xF451Dbd7Ba14BFa7B1B78A766D3Ed438F79EE1D1);
    ICompoundEther constant public CETH = ICompoundEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
}

contract CompoundSourceView {
    using UniERC20 for IERC20;
    using SafeMath for uint256;

    function _calculateCompound(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        rets = new uint256[](amounts.length);

        if (CompoundLib.COMPOUND_REGISTRY.tokenByCToken(fromToken).eq(swap.destToken)) {
            uint256 rate = ICompoundToken(address(fromToken)).exchangeRateStored();
            for (uint i = 0; i < amounts.length; i++) {
                rets[i] = amounts[i].mul(rate).div(1e18);
            }
            dex = address(fromToken);
            gas = 295_000;
        }
        else if (CompoundLib.COMPOUND_REGISTRY.cTokenByToken(fromToken).eq(swap.destToken)) {
            uint256 rate = ICompoundToken(address(swap.destToken)).exchangeRateStored();
            for (uint i = 0; i < amounts.length; i++) {
                rets[i] = amounts[i].mul(1e18).div(rate);
            }
            dex = address(swap.destToken);
            gas = 430_000;
        }
    }
}

contract CompoundSourceSwap {
    using UniERC20 for IERC20;
    using SafeMath for uint256;

    function _swapOnCompound(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        if (CompoundLib.COMPOUND_REGISTRY.tokenByCToken(fromToken).eq(destToken)) {
            ICompoundToken(address(fromToken)).redeem(amount);
        }
        else if (CompoundLib.COMPOUND_REGISTRY.cTokenByToken(fromToken).eq(destToken)) {
            if (fromToken.isETH()) {
                CompoundLib.CETH.mint{ value: amount }();
            } else {
                fromToken.uniApprove(address(destToken), amount);
                ICompoundToken(address(destToken)).mint(amount);
            }
        }
    }
}

contract CompoundSourcePublic is ISource, CompoundSourceView, CompoundSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCompound(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCompound(fromToken, destToken, amount, flags);
    }
}
