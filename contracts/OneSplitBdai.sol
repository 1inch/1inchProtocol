pragma solidity ^0.5.0;

import "./interface/IBdai.sol";
import "./OneSplitBase.sol";


contract OneSplitBdaiBase {
    IBdai public bdai = IBdai(0x6a4FFAafa8DD400676Df8076AD6c724867b0e2e8);
    IERC20 public btu = IERC20(0xb683D83a532e2Cb7DFa5275eED3698436371cc9f);
}


contract OneSplitBdaiView is OneSplitViewWrapBase, OneSplitBdaiBase {
    function getExpectedReturnRespectingGas(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 toTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_BDAI)) {
            if (fromToken == IERC20(bdai)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnRespectingGas(
                    dai,
                    toToken,
                    amount,
                    parts,
                    flags,
                    toTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 227_000, distribution);
            }

            if (toToken == IERC20(bdai)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnRespectingGas(
                    fromToken,
                    dai,
                    amount,
                    parts,
                    flags,
                    toTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 295_000, distribution);
            }
        }

        return super.getExpectedReturnRespectingGas(
            fromToken,
            toToken,
            amount,
            parts,
            flags,
            toTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitBdai is OneSplitBaseWrap, OneSplitBdaiBase {
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

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_BDAI)) {
            if (fromToken == IERC20(bdai)) {
                bdai.exit(amount);

                uint256 btuBalance = btu.balanceOf(address(this));
                if (btuBalance > 0) {
                    (,uint256[] memory btuDistribution) = getExpectedReturn(
                        btu,
                        toToken,
                        btuBalance,
                        1,
                        flags
                    );

                    _swap(
                        btu,
                        toToken,
                        btuBalance,
                        btuDistribution,
                        flags
                    );
                }

                return super._swap(
                    dai,
                    toToken,
                    amount,
                    distribution,
                    flags
                );
            }

            if (toToken == IERC20(bdai)) {
                super._swap(fromToken, dai, amount, distribution, flags);

                _infiniteApproveIfNeeded(dai, address(bdai));
                bdai.join(dai.balanceOf(address(this)));
                return;
            }
        }

        return super._swap(fromToken, toToken, amount, distribution, flags);
    }
}
