pragma solidity ^0.5.0;

import "./IOneSplit.sol";
import "./OneSplitBase.sol";
import "./OneSplitMultiPath.sol";
import "./OneSplitCompound.sol";
import "./OneSplitFulcrum.sol";
import "./OneSplitChai.sol";
import "./OneSplitBdai.sol";
import "./OneSplitIearn.sol";
import "./OneSplitIdle.sol";
import "./OneSplitAave.sol";
import "./OneSplitWeth.sol";
//import "./OneSplitSmartToken.sol";


contract OneSplitViewWrap is
    OneSplitViewWrapBase,
    OneSplitMultiPathView,
    OneSplitChaiView,
    OneSplitBdaiView,
    OneSplitAaveView,
    OneSplitFulcrumView,
    OneSplitCompoundView,
    OneSplitIearnView,
    OneSplitIdleView,
    OneSplitWethView
    //OneSplitSmartTokenView
{
    IOneSplitView public oneSplitView;

    constructor(IOneSplitView _oneSplit) public {
        oneSplitView = _oneSplit;
    }

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

        return super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );
    }

    function getExpectedReturnFloor(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        internal
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        return oneSplitView.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );
    }
}


contract OneSplitWrap is
    OneSplitBaseWrap,
    OneSplitMultiPath,
    OneSplitChai,
    OneSplitBdai,
    OneSplitAave,
    OneSplitFulcrum,
    OneSplitCompound,
    OneSplitIearn,
    OneSplitIdle,
    OneSplitWeth
    //OneSplitSmartToken
{
    IOneSplitView public oneSplitView;
    IOneSplit public oneSplit;

    constructor(IOneSplitView _oneSplitView, IOneSplit _oneSplit) public {
        oneSplitView = _oneSplitView;
        oneSplit = _oneSplit;
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags // 1 - Uniswap, 2 - Kyber, 4 - Bancor, 8 - Oasis, 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken, 1024 - bDAI
    )
        public
        view
        returns(
            uint256 /*returnAmount*/,
            uint256[] memory /*distribution*/
        )
    {
        return oneSplitView.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution, // [Uniswap, Kyber, Bancor, Oasis]
        uint256 disableFlags // 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken, 1024 - bDAI
    ) public payable {
        fromToken.universalTransferFrom(msg.sender, address(this), amount);

        _swap(fromToken, toToken, amount, distribution, disableFlags);

        uint256 returnAmount = toToken.universalBalanceOf(address(this));
        require(returnAmount >= minReturn, "OneSplit: actual return amount is less than minReturn");
        toToken.universalTransfer(msg.sender, returnAmount);
        fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
    }

    function _swapFloor(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 disableFlags
    ) internal {
        (bool success, bytes memory data) = address(oneSplit).delegatecall(
            abi.encodeWithSelector(
                this.swap.selector,
                fromToken,
                toToken,
                amount,
                minReturn,
                distribution,
                disableFlags
            )
        );

        assembly {
            switch success
                // delegatecall returns 0 on error.
                case 0 { revert(add(data, 32), returndatasize) }
        }
    }
}
