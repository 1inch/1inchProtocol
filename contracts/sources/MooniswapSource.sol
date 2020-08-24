// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IMooniswap.sol";
import "../IOneRouter.sol";
import "../ISource.sol";

import "../libraries/UniERC20.sol";


library MooniswapHelper {
    IMooniswapRegistry constant public REGISTRY = IMooniswapRegistry(0x71CD6666064C3A1354a3B4dca5fA1E2D3ee7D303);
}


contract MooniswapSourceView {
    using SafeMath for uint256;
    using UniERC20 for IERC20;

    function _calculateMooniswap(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        rets = new uint256[](amounts.length);

        IMooniswap mooniswap = MooniswapHelper.REGISTRY.pools(
            fromToken.isETH() ? UniERC20.ZERO_ADDRESS : fromToken,
            swap.destToken.isETH() ? UniERC20.ZERO_ADDRESS : swap.destToken
        );
        if (mooniswap == IMooniswap(0)) {
            return (rets, address(0), 0);
        }

        for (uint t = 0; t < swap.disabledDexes.length; t++) {
            if (swap.disabledDexes[t] == address(mooniswap)) {
                return (rets, address(0), 0);
            }
        }

        uint256 fee = mooniswap.fee();
        uint256 fromBalance = mooniswap.getBalanceForAddition(fromToken.isETH() ? UniERC20.ZERO_ADDRESS : fromToken);
        uint256 destBalance = mooniswap.getBalanceForRemoval(swap.destToken.isETH() ? UniERC20.ZERO_ADDRESS : swap.destToken);
        if (fromBalance == 0 || destBalance == 0) {
            return (rets, address(0), 0);
        }

        for (uint i = 0; i < amounts.length; i++) {
            uint256 amount = amounts[i].sub(amounts[i].mul(fee).div(1e18));
            rets[i] = amount.mul(destBalance).div(
                fromBalance.add(amount)
            );
        }

        return (rets, address(mooniswap), (fromToken.isETH() || swap.destToken.isETH()) ? 80_000 : 110_000);
    }
}


contract MooniswapSourceSwap {
    using UniERC20 for IERC20;

    function _swapOnMooniswap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        IMooniswap mooniswap = MooniswapHelper.REGISTRY.pools(
            fromToken.isETH() ? UniERC20.ZERO_ADDRESS : fromToken,
            destToken.isETH() ? UniERC20.ZERO_ADDRESS : destToken
        );

        fromToken.uniApprove(address(mooniswap), amount);
        mooniswap.swap{ value: fromToken.isETH() ? amount : 0 }(
            fromToken.isETH() ? UniERC20.ZERO_ADDRESS : fromToken,
            destToken.isETH() ? UniERC20.ZERO_ADDRESS : destToken,
            amount,
            0,
            0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5
        );
    }
}


contract MooniswapSourcePublic is ISource, MooniswapSourceView, MooniswapSourceSwap {
    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "ETH deposit rejected");
    }

    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateMooniswap(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnMooniswap(fromToken, destToken, amount, flags);
    }
}
