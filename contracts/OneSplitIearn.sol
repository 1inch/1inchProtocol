pragma solidity ^0.5.0;

import "./interface/IIearn.sol";
import "./OneSplitBase.sol";


contract OneSplitIearnBase {
    function _yTokens() internal pure returns(IIearn[7] memory) {
        return [
            IIearn(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01),
            IIearn(0x04Aa51bbcB46541455cCF1B8bef2ebc5d3787EC9),
            IIearn(0x73a052500105205d34Daf004eAb301916DA8190f),
            IIearn(0x83f798e925BcD4017Eb265844FDDAbb448f1707D),
            IIearn(0xd6aD7a6750A7593E092a9B218d66C0A814a3436e),
            IIearn(0xF61718057901F84C4eEC4339EF8f0D86D2B45600),
            IIearn(0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE)
        ];
    }
}


contract OneSplitIearnView is OneSplitBaseView, OneSplitIearnBase {
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
        return _iearnGetExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );
    }

    function _iearnGetExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        private
        view
        returns (uint256 returnAmount, uint256[] memory distribution)
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](4));
        }

        IIearn[7] memory yTokens = _yTokens();

        if (disableFlags.enabled(FLAG_IEARN)) {
            for (uint i = 0; i < yTokens.length; i++) {
                if (fromToken == IERC20(yTokens[i])) {
                    return _iearnGetExpectedReturn(
                        yTokens[i].token(),
                        toToken,
                        amount
                            .mul(yTokens[i].calcPoolValueInToken())
                            .div(yTokens[i].totalSupply()),
                        parts,
                        disableFlags
                    );
                }
            }

            for (uint i = 0; i < yTokens.length; i++) {
                if (toToken == IERC20(yTokens[i])) {
                    (uint256 ret, uint256[] memory dist) = super.getExpectedReturn(
                        fromToken,
                        yTokens[i].token(),
                        amount,
                        parts,
                        disableFlags
                    );

                    return (
                        ret
                            .mul(yTokens[i].totalSupply())
                            .div(yTokens[i].calcPoolValueInToken()),
                        dist
                    );
                }
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


contract OneSplitIearn is OneSplitBase, OneSplitIearnBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) internal {
        _iearnSwap(
            fromToken,
            toToken,
            amount,
            distribution,
            disableFlags
        );
    }

    function _iearnSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) private {
        if (fromToken == toToken) {
            return;
        }

        IIearn[7] memory yTokens = _yTokens();

        if (disableFlags.enabled(FLAG_IEARN)) {
            for (uint i = 0; i < yTokens.length; i++) {
                if (fromToken == IERC20(yTokens[i])) {
                    IERC20 underlying = yTokens[i].token();
                    yTokens[i].withdraw(amount);
                    _iearnSwap(underlying, toToken, underlying.balanceOf(address(this)), distribution, disableFlags);
                    return;
                }
            }

            for (uint i = 0; i < yTokens.length; i++) {
                if (toToken == IERC20(yTokens[i])) {
                    IERC20 underlying = yTokens[i].token();
                    super._swap(fromToken, underlying, amount, distribution, disableFlags);
                    _infiniteApproveIfNeeded(underlying, address(yTokens[i]));
                    yTokens[i].deposit(underlying.balanceOf(address(this)));
                    return;
                }
            }
        }

        return super._swap(fromToken, toToken, amount, distribution, disableFlags);
    }
}
