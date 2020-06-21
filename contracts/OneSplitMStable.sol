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
            if (fromToken == IERC20(musd)) {
                if (destToken == usdc || destToken == dai || destToken == usdt || destToken == tusd) {
                    (,, returnAmount) = musd_helper.getRedeemValidity(fromToken, amount, destToken);
                    return (returnAmount, 300_000, new uint256[](DEXES_COUNT));
                }
                else {
                    (,, returnAmount) = musd_helper.getRedeemValidity(fromToken, amount, dai);
                    (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                        dai,
                        destToken,
                        returnAmount,
                        parts,
                        flags,
                        destTokenEthPriceTimesGasPrice
                    );
                    return (returnAmount, estimateGasAmount + 300_000, distribution);
                }
            }

            if (destToken == IERC20(musd)) {
                if (fromToken == usdc || fromToken == dai || fromToken == usdt || fromToken == tusd) {
                    (,, returnAmount) = musd.getSwapOutput(fromToken, destToken, amount);
                    return (returnAmount, 300_000, new uint256[](DEXES_COUNT));
                }
                else {
                    IERC20 _destToken = destToken;
                    (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                        fromToken,
                        dai,
                        amount,
                        parts,
                        flags,
                        destTokenEthPriceTimesGasPrice
                            .mul(_cheapGetPrice(ETH_ADDRESS, dai, 1e16))
                            .div(_cheapGetPrice(ETH_ADDRESS, _destToken, 1e16))
                    );
                    (,, returnAmount) = musd_helper.getRedeemValidity(dai, returnAmount, destToken);
                    return (returnAmount, estimateGasAmount + 300_000, distribution);
                }
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
                fromToken.universalApprove(address(musd), amount);
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
