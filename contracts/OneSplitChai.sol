pragma solidity ^0.5.0;

import "./interface/IChai.sol";
import "./OneSplitBase.sol";


contract OneSplitChaiView is OneSplitViewWrapBase {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_CHAI)) {
            if (fromToken == IERC20(chai)) {
                return super.getExpectedReturn(
                    dai,
                    toToken,
                    chai.chaiToDai(amount),
                    parts,
                    flags
                );
            }

            if (toToken == IERC20(chai)) {
                (returnAmount, distribution) = super.getExpectedReturn(
                    fromToken,
                    dai,
                    amount,
                    parts,
                    flags
                );
                return (chai.daiToChai(returnAmount), distribution);
            }
        }

        return super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            flags
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

                _infiniteApproveIfNeeded(dai, address(chai));
                chai.join(address(this), dai.balanceOf(address(this)));
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
