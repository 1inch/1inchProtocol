pragma solidity ^0.5.0;

import "./interface/IChai.sol";
import "./OneSplitBase.sol";


contract OneSplitMStableView is OneSplitViewWrapBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_MSTABLE_MUSD)) {
            if (fromToken == IERC20(musd) && ((destToken == usdc || destToken == dai || destToken == usdt || destToken == tusd))) {
                (,, uint256 result) = musd_helper.getRedeemValidity(fromToken, amount, destToken);
                return (result, 300_000, new uint256[](DEXES_COUNT));
            }

            if (destToken == IERC20(musd) && ((fromToken == usdc || fromToken == dai || fromToken == usdt || fromToken == tusd))) {
                (,, uint256 result) = musd.getSwapOutput(fromToken, destToken, amount);
                return (result, 300_000, new uint256[](DEXES_COUNT));
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitMStable is OneSplitBaseWrap {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_MSTABLE_MUSD)) {
            if (fromToken == IERC20(musd) && ((destToken == usdc || destToken == dai || destToken == usdt || destToken == tusd))) {
                (,, uint256 result) = musd_helper.getRedeemValidity(fromToken, amount, destToken);
                musd.redeem(
                    destToken,
                    result
                );
                return;
            }

            if (destToken == IERC20(musd) && ((fromToken == usdc || fromToken == dai || fromToken == usdt || fromToken == tusd))) {
                musd.swap(
                    fromToken,
                    destToken,
                    amount,
                    address(this)
                );
                return;
            }
        }

        return super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}
