pragma solidity ^0.5.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./IOneSplit.sol";
import "./UniversalERC20.sol";


//
// Security assumptions:
// 1. It is safe to have infinite approves of any tokens to this smart contract,
//    since it could only call `transferFrom()` with first argument equal to msg.sender
// 2. It is safe to call `swap()` with reliable `minReturn` argument,
//    if returning amount will not reach `minReturn` value whole swap will be reverted.
//
contract OneSplitAudit is IOneSplit, Ownable {

    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    IOneSplit public oneSplitImpl;

    event ImplementationUpdated(address indexed newImpl);

    constructor(IOneSplit impl) public {
        setNewImpl(impl);
    }

    function() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin, "OneSplit: do not send ETH directly");
    }

    function setNewImpl(IOneSplit impl) public onlyOwner {
        oneSplitImpl = impl;
        emit ImplementationUpdated(address(impl));
    }

    /// @notice Calculate expected returning amount of `toToken`
    /// @param fromToken (IERC20) Address of token or `address(0)` for Ether
    /// @param toToken (IERC20) Address of token or `address(0)` for Ether
    /// @param amount (uint256) Amount for `fromToken`
    /// @param parts (uint256) Number of pieces source volume could be splitted,
    /// works like granularity, higly affects gas usage. Should be called offchain,
    /// but could be called onchain if user swaps not his own funds, but this is still considered as not safe.
    /// @param featureFlags (uint256) Flags for enabling and disabling some features, default 0
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 featureFlags // See contants in IOneSplit.sol
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        return oneSplitImpl.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            featureFlags
        );
    }

    /// @notice Swap `amount` of `fromToken` to `toToken`
    /// @param fromToken (IERC20) Address of token or `address(0)` for Ether
    /// @param toToken (IERC20) Address of token or `address(0)` for Ether
    /// @param amount (uint256) Amount for `fromToken`
    /// @param minReturn (uint256) Minimum expected return, else revert
    /// @param distribution (uint256[]) Array of weights for volume distribution returned by `getExpectedReturn`
    /// @param featureFlags (uint256) Flags for enabling and disabling some features, default 0
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 featureFlags // See contants in IOneSplit.sol
    ) public payable {
        require(fromToken != toToken && amount > 0, "OneSplit: swap makes no sense");
        require((msg.value != 0) == fromToken.isETH(), "OneSplit: msg.value shoule be used only for ETH swap");

        uint256 fromTokenBalanceBefore = fromToken.universalBalanceOf(address(this)).sub(msg.value);
        uint256 toTokenBalanceBefore = toToken.universalBalanceOf(address(this));

        fromToken.universalTransferFromSenderToThis(amount);
        fromToken.universalApprove(address(oneSplitImpl), amount);

        oneSplitImpl.swap.value(msg.value)(
            fromToken,
            toToken,
            amount,
            minReturn,
            distribution,
            featureFlags
        );

        uint256 fromTokenBalanceAfter = fromToken.universalBalanceOf(address(this));
        uint256 toTokenBalanceAfter = toToken.universalBalanceOf(address(this));

        uint256 returnAmount = toTokenBalanceAfter.sub(toTokenBalanceBefore);
        require(returnAmount >= minReturn, "OneSplit: actual return amount is less than minReturn");
        toToken.universalTransfer(msg.sender, returnAmount);

        if (fromTokenBalanceAfter > fromTokenBalanceBefore) {
            fromToken.universalTransfer(msg.sender, fromTokenBalanceAfter.sub(fromTokenBalanceBefore));
        }
    }

    function claimAsset(IERC20 asset, uint256 amount) public onlyOwner {
        asset.universalTransfer(msg.sender, amount);
    }
}
