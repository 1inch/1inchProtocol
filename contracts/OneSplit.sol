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


contract OneSplitView is
    IOneSplitView,
    OneSplitBaseView,
    OneSplitMultiPathView,
    OneSplitChaiView,
    OneSplitBdaiView,
    OneSplitAaveView,
    OneSplitFulcrumView,
    OneSplitCompoundView,
    OneSplitIearnView,
    OneSplitIdleView(0x23E4D1536c449e4D79E5903B4A9ddc3655be8609),
    OneSplitWethView
    //OneSplitSmartTokenView
{
    function() external {
        if (msg.sig == IOneSplit(0).getExpectedReturn.selector) {
            (
                ,
                IERC20 fromToken,
                IERC20 toToken,
                uint256 amount,
                uint256 parts,
                uint256 disableFlags
            ) = abi.decode(
                abi.encodePacked(bytes28(0), msg.data),
                (uint256,IERC20,IERC20,uint256,uint256,uint256)
            );

            (
                uint256 returnAmount,
                uint256[] memory distribution
            ) = getExpectedReturn(
                fromToken,
                toToken,
                amount,
                parts,
                disableFlags
            );

            bytes memory result = abi.encodePacked(returnAmount, distribution);
            assembly {
                return(add(result, 32), sload(result))
            }
        }
    }

    function getExpectedReturn(
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
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }

        super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );
    }
}


contract OneSplit is
    OneSplitBase,
    OneSplitMultiPath,
    OneSplitChai,
    OneSplitBdai,
    OneSplitAave,
    OneSplitFulcrum,
    OneSplitCompound,
    OneSplitIearn,
    OneSplitIdle(0x23E4D1536c449e4D79E5903B4A9ddc3655be8609),
    OneSplitWeth
    //OneSplitSmartToken
{
    IOneSplitView public oneSplitView;

    constructor(IOneSplitView _oneSplitView) public {
        oneSplitView = _oneSplitView;
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
        (bool success, bytes memory data) = address(oneSplitView).staticcall(
            abi.encodeWithSelector(
                this.getExpectedReturn.selector,
                fromToken,
                toToken,
                amount,
                parts,
                disableFlags
            )
        );

        assembly {
            switch success
                // delegatecall returns 0 on error.
                case 0 { revert(add(data, 32), returndatasize) }
                default { return(add(data, 32), returndatasize) }
        }
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

    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution, // [Uniswap, Kyber, Bancor, Oasis]
        uint256 disableFlags // 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken, 1024 - bDAI
    ) internal {
        if (fromToken == toToken) {
            return;
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
