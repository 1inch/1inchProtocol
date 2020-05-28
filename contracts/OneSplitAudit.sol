pragma solidity ^0.5.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./IOneSplit.sol";
import "./UniversalERC20.sol";


interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}


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

    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    IOneSplit public oneSplitImpl;

    event ImplementationUpdated(address indexed newImpl);

    modifier makeGasDiscount(uint256 flags) {
        uint256 gasStart = gasleft();
        _;
        if ((flags & FLAG_ENABLE_CHI_BURN) > 0) {
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
        }
    }

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
    /// @param flags (uint256) Flags for enabling and disabling some features, default 0
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See contants in IOneSplit.sol
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
            flags
        );
    }

    /// @notice Swap `amount` of `fromToken` to `toToken`
    /// @param fromToken (IERC20) Address of token or `address(0)` for Ether
    /// @param toToken (IERC20) Address of token or `address(0)` for Ether
    /// @param amount (uint256) Amount for `fromToken`
    /// @param minReturn (uint256) Minimum expected return, else revert
    /// @param distribution (uint256[]) Array of weights for volume distribution returned by `getExpectedReturn`
    /// @param flags (uint256) Flags for enabling and disabling some features, default 0
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags // See contants in IOneSplit.sol
    ) public payable {
        swapWithReferral(
            fromToken,
            toToken,
            amount,
            minReturn,
            distribution,
            flags,
            address(0),
            0
        );
    }

    /// @notice Swap `amount` of `fromToken` to `toToken`
    /// @param fromToken (IERC20) Address of token or `address(0)` for Ether
    /// @param toToken (IERC20) Address of token or `address(0)` for Ether
    /// @param amount (uint256) Amount for `fromToken`
    /// @param minReturn (uint256) Minimum expected return, else revert
    /// @param distribution (uint256[]) Array of weights for volume distribution returned by `getExpectedReturn`
    /// @param flags (uint256) Flags for enabling and disabling some features, default 0
    /// @param referral (address) Address of referral
    /// @param feePercent (uint256) Fees percents normalized to 1e18, limited to 0.03e18 (3%)
    function swapWithReferral(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags, // See contants in IOneSplit.sol
        address referral,
        uint256 feePercent
    ) public payable /*makeGasDiscount(flags)*/ {
        require(fromToken != toToken && amount > 0, "OneSplit: swap makes no sense");
        require((msg.value != 0) == fromToken.isETH(), "OneSplit: msg.value shoule be used only for ETH swap");
        require(feePercent <= 0.03e18, "OneSplit: feePercent out of range");

        uint256 fromTokenBalanceBefore = fromToken.universalBalanceOf(address(this)).sub(msg.value);
        uint256 toTokenBalanceBefore = toToken.universalBalanceOf(address(this));

        fromToken.universalTransferFromSenderToThis(amount);
        uint256 confirmed = fromToken.universalBalanceOf(address(this)).sub(fromTokenBalanceBefore);
        if (!fromToken.isETH() && fromToken.allowance(address(this), address(oneSplitImpl)) > 0) {
            fromToken.universalApprove(address(oneSplitImpl), 0);
        }
        fromToken.universalApprove(address(oneSplitImpl), confirmed);

        oneSplitImpl.swap.value(msg.value)(
            fromToken,
            toToken,
            confirmed,
            minReturn,
            distribution,
            flags
        );

        uint256 fromTokenBalanceAfter = fromToken.universalBalanceOf(address(this));
        uint256 toTokenBalanceAfter = toToken.universalBalanceOf(address(this));

        uint256 returnAmount = toTokenBalanceAfter.sub(toTokenBalanceBefore);
        require(returnAmount >= minReturn, "OneSplit: actual return amount is less than minReturn");
        toToken.universalTransfer(referral, returnAmount.mul(feePercent).div(1e18));
        toToken.universalTransfer(msg.sender, returnAmount.sub(returnAmount.mul(feePercent).div(1e18)));

        IERC20 _fromToken = fromToken;

        if (fromTokenBalanceAfter > fromTokenBalanceBefore) {
            _fromToken.universalTransfer(msg.sender, fromTokenBalanceAfter.sub(fromTokenBalanceBefore));
        }
    }

    function claimAsset(IERC20 asset, uint256 amount) public onlyOwner {
        asset.universalTransfer(msg.sender, amount);
    }
}
