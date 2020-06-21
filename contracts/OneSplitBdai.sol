pragma solidity ^0.5.0;

import "./interface/IBdai.sol";
import "./OneSplitBase.sol";


contract OneSplitBdaiBase {
    IBdai internal constant bdai = IBdai(0x6a4FFAafa8DD400676Df8076AD6c724867b0e2e8);
    IERC20 internal constant btu = IERC20(0xb683D83a532e2Cb7DFa5275eED3698436371cc9f);
}


contract OneSplitBdaiView is OneSplitViewWrapBase, OneSplitBdaiBase {
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

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_BDAI)) {
            if (fromToken == IERC20(bdai)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    dai,
                    destToken,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 227_000, distribution);
            }

            if (destToken == IERC20(bdai)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    fromToken,
                    dai,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 295_000, distribution);
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


contract OneSplitBdai is OneSplitBaseWrap, OneSplitBdaiBase {
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

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_BDAI)) {
            if (fromToken == IERC20(bdai)) {
                bdai.exit(amount);

                uint256 btuBalance = btu.balanceOf(address(this));
                if (btuBalance > 0) {
                    (,uint256[] memory btuDistribution) = getExpectedReturn(
                        btu,
                        destToken,
                        btuBalance,
                        1,
                        flags
                    );

                    _swap(
                        btu,
                        destToken,
                        btuBalance,
                        btuDistribution,
                        flags
                    );
                }

                return super._swap(
                    dai,
                    destToken,
                    amount,
                    distribution,
                    flags
                );
            }

            if (destToken == IERC20(bdai)) {
                super._swap(fromToken, dai, amount, distribution, flags);

                uint256 daiBalance = dai.balanceOf(address(this));
                dai.universalApprove(address(bdai), daiBalance);
                bdai.join(daiBalance);
                return;
            }
        }

        return super._swap(fromToken, destToken, amount, distribution, flags);
    }
}
