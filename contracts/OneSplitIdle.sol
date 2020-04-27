pragma solidity ^0.5.0;

import "./interface/IIdle.sol";
import "./OneSplitBase.sol";


contract OneSplitIdleBase {
    function _idleTokens() internal pure returns(IIdle[2] memory) {
        return [
            IIdle(0x10eC0D497824e342bCB0EDcE00959142aAa766dD),
            IIdle(0xeB66ACc3d011056B00ea521F8203580C2E5d3991)
        ];
    }
}


contract OneSplitIdleView is OneSplitViewWrapBase, OneSplitIdleBase {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        public
        view
        returns (uint256 /*returnAmount*/, uint256[] memory /*distribution*/)
    {
        return _idleGetExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );
    }

    function _idleGetExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        public
        returns (uint256 returnAmount, uint256[] memory distribution)
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }

        IIdle[2] memory tokens = _idleTokens();

        for (uint i = 0; i < tokens.length; i++) {
            if (fromToken == IERC20(tokens[i])) {
                return _idleGetExpectedReturn(
                    tokens[i].token(),
                    toToken,
                    amount.mul(tokens[i].tokenPrice()).div(1e18),
                    parts,
                    disableFlags
                );
            }
        }

        for (uint i = 0; i < tokens.length; i++) {
            if (toToken == IERC20(tokens[i])) {
                (uint256 ret, uint256[] memory dist) = super.getExpectedReturn(
                    fromToken,
                    tokens[i].token(),
                    amount,
                    parts,
                    disableFlags
                );

                return (
                    ret.mul(1e18).div(tokens[i].tokenPrice()),
                    dist
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


contract OneSplitIdle is OneSplitBaseWrap, OneSplitIdleBase {
    function _superOneSplitIdleSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] calldata distribution,
        uint256 disableFlags
    )
        external
    {
        require(msg.sender == address(this));
        return super._swap(fromToken, toToken, amount, distribution, disableFlags);
    }

    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) internal {
        _idleSwap(
            fromToken,
            toToken,
            amount,
            distribution,
            disableFlags
        );
    }

    function _idleSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) public payable {
        IIdle[2] memory tokens = _idleTokens();

        for (uint i = 0; i < tokens.length; i++) {
            if (fromToken == IERC20(tokens[i])) {
                IERC20 underlying = tokens[i].token();
                uint256 minted = tokens[i].redeemIdleToken(amount, true, new uint256[](0));
                _idleSwap(underlying, toToken, minted, distribution, disableFlags);
                return;
            }
        }

        for (uint i = 0; i < tokens.length; i++) {
            if (toToken == IERC20(tokens[i])) {
                IERC20 underlying = tokens[i].token();
                super._swap(fromToken, underlying, amount, distribution, disableFlags);
                _infiniteApproveIfNeeded(underlying, address(tokens[i]));
                tokens[i].mintIdleToken(underlying.balanceOf(address(this)), new uint256[](0));
                return;
            }
        }

        return super._swap(fromToken, toToken, amount, distribution, disableFlags);
    }
}
