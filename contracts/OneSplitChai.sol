pragma solidity ^0.5.0;

import "./interface/IChai.sol";
import "./OneSplitBase.sol";


contract OneSplitChaiView is OneSplitViewWrapBase {
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

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_CHAI)) {
            if (fromToken == IERC20(chai)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnRespectingGas(
                    dai,
                    toToken,
                    chai.chaiToDai(amount),
                    parts,
                    flags,
                    toTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 197_000, distribution);
            }

            if (toToken == IERC20(chai)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnRespectingGas(
                    fromToken,
                    dai,
                    amount,
                    parts,
                    flags,
                    toTokenEthPriceTimesGasPrice
                );
                return (chai.daiToChai(returnAmount), estimateGasAmount + 168_000, distribution);
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


contract OneSplitChai is OneSplitBaseWrap {
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

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_CHAI)) {
            if (fromToken == IERC20(chai)) {
                chai.exit(address(this), amount);

                return super._swap(
                    dai,
                    toToken,
                    dai.balanceOf(address(this)),
                    distribution,
                    flags
                );
            }

            if (toToken == IERC20(chai)) {
                super._swap(
                    fromToken,
                    dai,
                    amount,
                    distribution,
                    flags
                );

                uint256 daiBalance = dai.balanceOf(address(this));
                dai.universalApprove(address(chai), daiBalance);
                chai.join(address(this), daiBalance);
                return;
            }
        }

        return super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            flags
        );
    }
}
