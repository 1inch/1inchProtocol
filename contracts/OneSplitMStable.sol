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
                {
                    (bool valid1,, uint256 res1,) = musd_helper.getRedeemValidity(musd, amount, destToken);
                    if (valid1) {
                        return (res1, 300_000, new uint256[](DEXES_COUNT));
                    }
                }

                (bool valid,, address token) = musd_helper.suggestRedeemAsset(musd);
                if (valid) {
                    (,, returnAmount,) = musd_helper.getRedeemValidity(musd, amount, IERC20(token));
                    if (IERC20(token) != destToken) {
                        (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                            IERC20(token),
                            destToken,
                            returnAmount,
                            parts,
                            flags,
                            destTokenEthPriceTimesGasPrice
                        );
                    } else {
                        distribution = new uint256[](DEXES_COUNT);
                    }

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
                    (bool valid,, address token) = musd_helper.suggestMintAsset(_destToken);
                    if (valid) {
                        if (IERC20(token) != fromToken) {
                            (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                                fromToken,
                                IERC20(token),
                                amount,
                                parts,
                                flags,
                                _scaleDestTokenEthPriceTimesGasPrice(
                                    _destToken,
                                    IERC20(token),
                                    destTokenEthPriceTimesGasPrice
                                )
                            );
                        } else {
                            returnAmount = amount;
                        }
                        (,, returnAmount) = musd.getSwapOutput(IERC20(token), _destToken, returnAmount);
                        return (returnAmount, estimateGasAmount + 300_000, distribution);
                    }
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
            if (fromToken == IERC20(musd)) {
                if (destToken == usdc || destToken == dai || destToken == usdt || destToken == tusd) {
                    (,,, uint256 result) = musd_helper.getRedeemValidity(fromToken, amount, destToken);
                    musd.redeem(
                        destToken,
                        result
                    );
                }
                else {
                    (,,, uint256 result) = musd_helper.getRedeemValidity(fromToken, amount, dai);
                    musd.redeem(
                        dai,
                        result
                    );
                    super._swap(
                        dai,
                        destToken,
                        dai.balanceOf(address(this)),
                        distribution,
                        flags
                    );
                }
                return;
            }

            if (destToken == IERC20(musd)) {
                if (fromToken == usdc || fromToken == dai || fromToken == usdt || fromToken == tusd) {
                    fromToken.universalApprove(address(musd), amount);
                    musd.swap(
                        fromToken,
                        destToken,
                        amount,
                        address(this)
                    );
                }
                else {
                    super._swap(
                        fromToken,
                        dai,
                        amount,
                        distribution,
                        flags
                    );
                    musd.swap(
                        dai,
                        destToken,
                        dai.balanceOf(address(this)),
                        address(this)
                    );
                }
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
