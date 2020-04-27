pragma solidity ^0.5.0;

import "./interface/IBdai.sol";
import "./OneSplitBase.sol";


contract OneSplitBdaiBase {
    IBdai public bdai = IBdai(0x6a4FFAafa8DD400676Df8076AD6c724867b0e2e8);
    IERC20 public btu = IERC20(0xb683D83a532e2Cb7DFa5275eED3698436371cc9f);
}


contract OneSplitBdaiView is OneSplitViewWrapBase, OneSplitBdaiBase {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        public
        view
        returns (uint256 returnAmount, uint256[] memory distribution)
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }

        if (!disableFlags.check(FLAG_DISABLE_BDAI)) {
            if (fromToken == IERC20(bdai)) {
                return super.getExpectedReturn(
                    dai,
                    toToken,
                    amount,
                    parts,
                    disableFlags
                );
            }

            if (toToken == IERC20(bdai)) {
                return super.getExpectedReturn(
                    fromToken,
                    dai,
                    amount,
                    parts,
                    disableFlags
                );
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


contract OneSplitBdai is OneSplitBaseWrap, OneSplitBdaiBase {
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

        if (!disableFlags.check(FLAG_DISABLE_BDAI)) {
            if (fromToken == IERC20(bdai)) {
                bdai.exit(amount);

                uint256 btuBalance = btu.balanceOf(address(this));
                if (btuBalance > 0) {
                    (,uint256[] memory btuDistribution) = getExpectedReturn(
                        btu,
                        toToken,
                        btuBalance,
                        1,
                        disableFlags
                    );

                    _swap(
                        btu,
                        toToken,
                        btuBalance,
                        btuDistribution,
                        disableFlags
                    );
                }

                return super._swap(
                    dai,
                    toToken,
                    amount,
                    distribution,
                    disableFlags
                );
            }

            if (toToken == IERC20(bdai)) {
                super._swap(fromToken, dai, amount, distribution, disableFlags);

                _infiniteApproveIfNeeded(dai, address(bdai));
                bdai.join(dai.balanceOf(address(this)));
                return;
            }
        }

        return super._swap(fromToken, toToken, amount, distribution, disableFlags);
    }
}
