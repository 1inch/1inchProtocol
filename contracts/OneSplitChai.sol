pragma solidity ^0.5.0;

import "./interface/IChai.sol";
import "./OneSplitBase.sol";


contract OneSplitChaiView is OneSplitViewWrapBase {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
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

        if (!disableFlags.check(FLAG_DISABLE_CHAI)) {
            if (fromToken == IERC20(chai)) {
                return super.getExpectedReturn(
                    dai,
                    toToken,
                    chai.chaiToDai(amount),
                    parts,
                    disableFlags
                );
            }

            if (toToken == IERC20(chai)) {
                (returnAmount, distribution) = super.getExpectedReturn(
                    fromToken,
                    dai,
                    amount,
                    parts,
                    disableFlags
                );
                return (chai.daiToChai(returnAmount), distribution);
            }
        }

        return super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );
    }
}


contract OneSplitChai is OneSplitBaseWrap {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) internal {
        if (fromToken == toToken) {
            return;
        }

        if (!disableFlags.check(FLAG_DISABLE_CHAI)) {
            if (fromToken == IERC20(chai)) {
                chai.exit(address(this), amount);

                return super._swap(
                    dai,
                    toToken,
                    dai.balanceOf(address(this)),
                    distribution,
                    disableFlags
                );
            }

            if (toToken == IERC20(chai)) {
                super._swap(
                    fromToken,
                    dai,
                    amount,
                    distribution,
                    disableFlags
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
            disableFlags
        );
    }
}
