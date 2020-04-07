pragma solidity ^0.5.0;

import "./IOneSplit.sol";
import "./OneSplitBase.sol";
import "./OneSplitMultiPath.sol";
import "./OneSplitCompound.sol";
import "./OneSplitFulcrum.sol";
import "./OneSplitChai.sol";
import "./OneSplitBdai.sol";
import "./OneSplitIearn.sol";
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
    OneSplitWethView
    //OneSplitSmartTokenView
{
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
            uint256 returnAmount,
            uint256[] memory distribution // [Uniswap, Kyber, Bancor, Oasis]
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
}


contract OneSplit is
    IOneSplit,
    OneSplitBase,
    OneSplitMultiPath,
    OneSplitChai,
    OneSplitBdai,
    OneSplitAave,
    OneSplitFulcrum,
    OneSplitCompound,
    OneSplitIearn,
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
            uint256 returnAmount,
            uint256[] memory distribution // [Uniswap, Kyber, Bancor, Oasis]
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

    // DEPERECATED:

    function getAllRatesForDEX(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    ) public view returns(uint256[] memory results) {
        results = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            (results[i],) = getExpectedReturn(
                fromToken,
                toToken,
                amount.mul(i + 1).div(parts),
                1,
                disableFlags
            );
        }
    }
}
