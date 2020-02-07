pragma solidity ^0.5.0;

import "./interface/IBdai.sol";
import "./OneSplitBase.sol";

contract OneSplitBdai is OneSplitBase {
    IBdai public bdai = IBdai(0x6a4FFAafa8DD400676Df8076AD6c724867b0e2e8);
    IERC20 public btu = IERC20(0xb683D83a532e2Cb7DFa5275eED3698436371cc9f);

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
            return (amount, new uint256[](4));
        }

        if (disableFlags.enabled(FLAG_BDAI)) {
            if (fromToken == IERC20(bdai)) {
                return
                    super.getExpectedReturn(
                        dai,
                        toToken,
                        amount,
                        parts,
                        disableFlags
                    );
            }

            if (toToken == IERC20(bdai)) {
                return
                    super.getExpectedReturn(
                        fromToken,
                        dai,
                        amount,
                        parts,
                        disableFlags
                    );
            }
        }

        return
            super.getExpectedReturn(
                fromToken,
                toToken,
                amount,
                parts,
                disableFlags
            );
    }

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

        if (disableFlags.enabled(FLAG_BDAI)) {
            if (fromToken == IERC20(bdai)) {
                bdai.exit(amount);
                btu.universalTransfer(msg.sender, btu.balanceOf(address(this)));

                return
                    super._swap(
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

        return
            super._swap(fromToken, toToken, amount, distribution, disableFlags);
    }
}
