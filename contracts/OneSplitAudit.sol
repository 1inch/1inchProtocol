pragma solidity ^0.5.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./interface/IWETH.sol";
import "./interface/IUniswapV2Exchange.sol";
import "./IOneSplit.sol";
import "./UniversalERC20.sol";


contract IFreeFromUpTo is IERC20 {
    function freeFromUpTo(address from, uint256 value) external returns(uint256 freed);
}

interface IReferralGasSponsor {
    function makeGasDiscount(
        uint256 gasSpent,
        uint256 returnAmount,
        bytes calldata msgSenderCalldata
    ) external;
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

    IWETH constant internal weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    IOneSplit public oneSplitImpl;

    event ImplementationUpdated(address indexed newImpl);

    event Swapped(
        IERC20 indexed fromToken,
        IERC20 indexed destToken,
        uint256 fromTokenAmount,
        uint256 destTokenAmount,
        uint256 minReturn,
        uint256[] distribution,
        uint256 flags,
        address referral
    );

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
        (returnAmount, , distribution) = getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    /// @notice Calculate expected returning amount of `destToken`
    /// @param fromToken (IERC20) Address of token or `address(0)` for Ether
    /// @param destToken (IERC20) Address of token or `address(0)` for Ether
    /// @param amount (uint256) Amount for `fromToken`
    /// @param parts (uint256) Number of pieces source volume could be splitted,
    /// works like granularity, higly affects gas usage. Should be called offchain,
    /// but could be called onchain if user swaps not his own funds, but this is still considered as not safe.
    /// @param flags (uint256) Flags for enabling and disabling some features, default 0
    /// @param destTokenEthPriceTimesGasPrice (uint256) destToken price to ETH multiplied by gas price
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return oneSplitImpl.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
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
    ) public payable returns(uint256 returnAmount) {
        require(_fromToken() != _destToken() && amount > 0, "OneSplit: swap makes no sense");
        require((msg.value != 0) == _fromToken().isETH(), "OneSplit: msg.value should be used only for ETH swap");
        require(feePercent <= 0.03e18, "OneSplit: feePercent out of range");

        uint256 gasStart = gasleft();

        Balances memory beforeBalances = Balances({
            ofFromToken: uint128(_fromToken().universalBalanceOf(address(this)).sub(msg.value)),
            ofDestToken: uint128(_destToken().universalBalanceOf(address(this)))
        });

        // Transfer From
        _fromToken().universalTransferFromSenderToThis(amount);
        uint256 confirmed = _fromToken().universalBalanceOf(address(this)).sub(beforeBalances.ofFromToken);

        // Swap
        _fromToken().universalApprove(address(oneSplitImpl), confirmed);
        oneSplitImpl.swap.value(_fromToken().isETH() ? confirmed : 0)(
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

        emit Swapped(
            _fromToken(),
            _destToken(),
            amount,
            returnAmount,
            minReturn,
            distribution,
            flags,
            referral
        );

        // Return remainder
        if (afterBalances.ofFromToken > beforeBalances.ofFromToken) {
            _fromToken().universalTransfer(msg.sender, uint256(afterBalances.ofFromToken).sub(beforeBalances.ofFromToken));
        }

        if ((flags & FLAG_ENABLE_CHI_BURN) > 0) {
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            _chiBurnOrSell((gasSpent + 14154) / 41947);
        }
        else if ((flags & FLAG_ENABLE_REFERRAL_GAS_SPONSORSHIP) > 0) {
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            IReferralGasSponsor(referral).makeGasDiscount(gasSpent, returnAmount, msg.data);
        }
    }

    function claimAsset(IERC20 asset, uint256 amount) public onlyOwner {
        asset.universalTransfer(msg.sender, amount);
    }

    function _chiBurnOrSell(uint256 amount) internal {
        IUniswapV2Exchange exchange = IUniswapV2Exchange(0xa6f3ef841d371a82ca757FaD08efc0DeE2F1f5e2);
        uint256 sellRefund = UniswapV2ExchangeLib.getReturn(exchange, chi, weth, amount);
        uint256 burnRefund = amount.mul(18_000).mul(tx.gasprice);

        if (sellRefund < burnRefund.add(tx.gasprice.mul(36_000))) {
            chi.freeFromUpTo(msg.sender, amount);
        }
        else {
            chi.transferFrom(msg.sender, address(exchange), amount);
            exchange.swap(0, sellRefund, address(this), "");
            weth.withdraw(weth.balanceOf(address(this)));
            msg.sender.transfer(address(this).balance);
        }
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
