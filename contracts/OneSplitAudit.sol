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
// 3. Additionally CHI tokens could be burned from caller if FLAG_ENABLE_CHI_BURN flag
//    is presented: (flags & 0x10000000000) != 0. Burned amount would refund up to 43% of gas fees.
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
            uint256 gasSpent = 21000 + gasStart - gasleft() + 5 * msg.data.length;
            chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
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

    /// @notice Calculate expected returning amount of `destToken`
    /// @param fromToken (IERC20) Address of token or `address(0)` for Ether
    /// @param destToken (IERC20) Address of token or `address(0)` for Ether
    /// @param amount (uint256) Amount for `fromToken`
    /// @param parts (uint256) Number of pieces source volume could be splitted,
    /// works like granularity, higly affects gas usage. Should be called offchain,
    /// but could be called onchain if user swaps not his own funds, but this is still considered as not safe.
    /// @param flags (uint256) Flags for enabling and disabling some features, default 0
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
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
            destToken,
            amount,
            parts,
            flags
        );
    }

    /// @notice Swap `amount` of `fromToken` to `destToken`
    /// @param fromToken (IERC20) Address of token or `address(0)` for Ether
    /// @param destToken (IERC20) Address of token or `address(0)` for Ether
    /// @param amount (uint256) Amount for `fromToken`
    /// @param minReturn (uint256) Minimum expected return, else revert
    /// @param distribution (uint256[]) Array of weights for volume distribution returned by `getExpectedReturn`
    /// @param flags (uint256) Flags for enabling and disabling some features, default 0
    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags // See contants in IOneSplit.sol
    ) public payable returns(uint256 returnAmount) {
        return swapWithReferral(
            fromToken,
            destToken,
            amount,
            minReturn,
            distribution,
            flags,
            address(0),
            0
        );
    }

    struct Balances {
        uint128 ofFromToken;
        uint128 ofDestToken;
    }

    /// @notice Swap `amount` of `fromToken` to `destToken`
    /// param fromToken (IERC20) Address of token or `address(0)` for Ether
    /// param destToken (IERC20) Address of token or `address(0)` for Ether
    /// @param amount (uint256) Amount for `fromToken`
    /// @param minReturn (uint256) Minimum expected return, else revert
    /// @param distribution (uint256[]) Array of weights for volume distribution returned by `getExpectedReturn`
    /// @param flags (uint256) Flags for enabling and disabling some features, default 0
    /// @param referral (address) Address of referral
    /// @param feePercent (uint256) Fees percents normalized to 1e18, limited to 0.03e18 (3%)
    function swapWithReferral(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags, // See contants in IOneSplit.sol
        address referral,
        uint256 feePercent
    ) public payable makeGasDiscount(flags) returns(uint256 returnAmount) {
        require(_fromToken() != _destToken() && amount > 0, "OneSplit: swap makes no sense");
        require((msg.value != 0) == _fromToken().isETH(), "OneSplit: msg.value should be used only for ETH swap");
        require(feePercent <= 0.03e18, "OneSplit: feePercent out of range");

        Balances memory beforeBalances = Balances({
            ofFromToken: uint128(_fromToken().universalBalanceOf(address(this)).sub(msg.value)),
            ofDestToken: uint128(_destToken().universalBalanceOf(address(this)))
        });

        // Transfer From
        _fromToken().universalTransferFromSenderToThis(amount);
        uint256 confirmed = _fromToken().universalBalanceOf(address(this)).sub(beforeBalances.ofFromToken);

        // Approve if needed
        if (!_fromToken().isETH() && _fromToken().allowance(address(this), address(oneSplitImpl)) < confirmed) {
            _fromToken().universalApprove(address(oneSplitImpl), confirmed);
        }

        // Swap
        oneSplitImpl.swap.value(msg.value)(
            _fromToken(),
            _destToken(),
            confirmed,
            minReturn,
            distribution,
            flags
        );

        Balances memory afterBalances = Balances({
            ofFromToken: uint128(_fromToken().universalBalanceOf(address(this))),
            ofDestToken: uint128(_destToken().universalBalanceOf(address(this)))
        });

        // Return
        returnAmount = uint256(afterBalances.ofDestToken).sub(beforeBalances.ofDestToken);
        require(returnAmount >= minReturn, "OneSplit: actual return amount is less than minReturn");
        _destToken().universalTransfer(referral, returnAmount.mul(feePercent).div(1e18));
        _destToken().universalTransfer(msg.sender, returnAmount.sub(returnAmount.mul(feePercent).div(1e18)));

        // Return remainder
        if (afterBalances.ofFromToken > beforeBalances.ofFromToken) {
            _fromToken().universalTransfer(msg.sender, uint256(afterBalances.ofFromToken).sub(beforeBalances.ofFromToken));
        }
    }

    function claimAsset(IERC20 asset, uint256 amount) public onlyOwner {
        asset.universalTransfer(msg.sender, amount);
    }

    // Helps to avoid "Stack too deep" in swap() method
    function _fromToken() private pure returns(IERC20 token) {
        assembly {
            token := calldataload(4)
        }
    }

    // Helps to avoid "Stack too deep" in swap() method
    function _destToken() private pure returns(IERC20 token) {
        assembly {
            token := calldataload(36)
        }
    }
}
