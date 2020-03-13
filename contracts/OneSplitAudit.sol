pragma solidity ^0.5.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./IOneSplit.sol";
import "./UniversalERC20.sol";


//
// Security assumptions:
// 1. It is safe to have infinite approves of any tokens to this smart contract,
//    since it could only call `transferFrom()` with first argument equal to msg.sender
// 2. It is safe to call `swap()` and `goodSwap()` with reliable `minReturn` argument,
//    if returning amount will not reach `minReturn` value whole swap will be reverted.
//
contract OneSplitAudit is IOneSplit, Ownable {

    using UniversalERC20 for IERC20;

    IOneSplit public oneSplitImpl;

    event ImplementationUpdated(address indexed newImpl);

    constructor(IOneSplit impl) public {
        setNewImpl(impl);
    }

    function() external payable {
        require(msg.sender != tx.origin, "OneSplit: do not send ETH directly");
    }

    function setNewImpl(IOneSplit impl) public onlyOwner {
        oneSplitImpl = impl;
        emit ImplementationUpdated(address(impl));
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
        return oneSplitImpl.getExpectedReturn(
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
        fromToken.universalApprove(address(oneSplitImpl), amount);

        oneSplitImpl.swap.value(msg.value)(
            fromToken,
            toToken,
            amount,
            minReturn,
            distribution,
            disableFlags
        );

        uint256 returnAmount = toToken.universalBalanceOf(address(this));
        require(returnAmount >= minReturn, "OneSplit: actual return amount is less than minReturn");
        toToken.universalTransfer(msg.sender, returnAmount);
        fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
    }

    function goodSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256 parts,
        uint256 disableFlags // 1 - Uniswap, 2 - Kyber, 4 - Bancor, 8 - Oasis, 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken, 1024 - bDAI
    ) public payable {
        (, uint256[] memory distribution) = getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );
        swap(
            fromToken,
            toToken,
            amount,
            minReturn,
            distribution,
            disableFlags
        );
    }
}
