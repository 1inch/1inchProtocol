
// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interface/IUniswapExchange.sol

pragma solidity ^0.5.0;



interface IUniswapExchange {

    function getEthToTokenInputPrice(uint256 ethSold)
        external view returns(uint256 tokensBought);

    function getTokenToEthInputPrice(uint256 tokensSold)
        external view returns (uint256 ethBought);

    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline)
        external payable returns (uint256 tokensBought);

    function tokenToEthSwapInput(uint256 tokensSold, uint256 minEth, uint256 deadline)
        external returns (uint256 ethBought);

    function tokenToTokenSwapInput(uint256 tokensSold, uint256 minTokensBought, uint256 minEthBought, uint256 deadline, address tokenAddr)
        external returns (uint256 tokensBought);

}

// File: contracts/interface/IUniswapFactory.sol

pragma solidity ^0.5.0;



interface IUniswapFactory {

    function getExchange(IERC20 token)
        external view returns(IUniswapExchange exchange);
}

// File: contracts/interface/IKyberNetworkContract.sol

pragma solidity ^0.5.0;



interface IKyberNetworkContract {

    function searchBestRate(
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        bool usePermissionless
    ) external view returns(address reserve, uint256 rate);
}

// File: contracts/interface/IKyberNetworkProxy.sol

pragma solidity ^0.5.0;



interface IKyberNetworkProxy {

    function getExpectedRate(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty
    ) external view returns(uint256 expectedRate, uint256 slippageRate);

    function tradeWithHint(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId,
        bytes calldata hint
    ) external payable returns(uint256);

    function kyberNetworkContract() external view returns (IKyberNetworkContract);

    // TODO: Limit usage by tx.gasPrice
    // function maxGasPrice() external view returns (uint256);

    // TODO: Limit usage by user cap
    // function getUserCapInWei(address user) external view returns (uint256);
    // function getUserCapInTokenWei(address user, IERC20 token) external view returns (uint256);
}

// File: contracts/interface/IKyberUniswapReserve.sol

pragma solidity ^0.5.0;


interface IKyberUniswapReserve {
    function uniswapFactory() external view returns(address);
}

// File: contracts/interface/IKyberOasisReserve.sol

pragma solidity ^0.5.0;


interface IKyberOasisReserve {
    function otc() external view returns(address);
}

// File: contracts/interface/IKyberBancorReserve.sol

pragma solidity ^0.5.0;


contract IKyberBancorReserve {
    function bancorEth() public view returns(address);
}

// File: contracts/interface/IBancorNetwork.sol

pragma solidity ^0.5.0;


interface IBancorNetwork {

    function getReturnByPath(
        address[] calldata path,
        uint256 amount
    ) external view returns(
        uint256 returnAmount,
        uint256 conversionFee
    );

    function claimAndConvert(
        address[] calldata path,
        uint256 amount,
        uint256 minReturn
    ) external returns(uint256);

    function convert(
        address[] calldata path,
        uint256 amount,
        uint256 minReturn
    ) external payable returns(uint256);
}

// File: contracts/interface/IBancorContractRegistry.sol

pragma solidity ^0.5.0;


contract IBancorContractRegistry {

    function addressOf(bytes32 contractName)
        external view returns (address);
}

// File: contracts/interface/IBancorNetworkPathFinder.sol

pragma solidity ^0.5.0;



interface IBancorNetworkPathFinder {

    function generatePath(IERC20 sourceToken, IERC20 targetToken)
        external view returns(address[] memory);
}

// File: contracts/interface/IBancorEtherToken.sol

pragma solidity ^0.5.0;



contract IBancorEtherToken is IERC20 {

    function deposit()
        external payable;

    function withdraw(uint256 amount)
        external;
}

// File: contracts/interface/IOasisExchange.sol

pragma solidity ^0.5.0;



interface IOasisExchange {

    function getBuyAmount(IERC20 buyGem, IERC20 payGem, uint256 payAmt)
        external view returns(uint256 fillAmt);

    function sellAllAmount(IERC20 payGem, uint payAmt, IERC20 buyGem, uint256 minFillAmount)
        external returns(uint256 fillAmt);
}

// File: contracts/interface/ICompound.sol

pragma solidity ^0.5.0;



contract ICompound {
    function markets(address cToken)
        external
        view
        returns(bool isListed, uint256 collateralFactorMantissa);
}


contract ICompoundToken is IERC20 {
    function underlying() external view returns(address);
    function exchangeRateStored() external view returns(uint256);

    function mint(uint256 mintAmount) external returns(uint256);
    function redeem(uint256 redeemTokens) external returns(uint256);
}


contract ICompoundEther is IERC20 {
    function mint() external payable;
    function redeem(uint256 redeemTokens) external returns(uint256);
}

// File: contracts/interface/IWETH.sol

pragma solidity ^0.5.0;



contract IWETH is IERC20 {

    function deposit()
        external payable;

    function withdraw(uint256 amount)
        external;
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/UniversalERC20.sol

pragma solidity ^0.5.0;





library UniversalERC20 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(IERC20 token, address to, uint256 amount) internal returns(bool) {
        if (amount == 0) {
            return true;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            address(uint160(to)).transfer(amount);
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            require(from == msg.sender && msg.value >= amount, "msg.value is zero");
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalApprove(IERC20 token, address to, uint256 amount) internal {
        if (token != ZERO_ADDRESS && token != ETH_ADDRESS) {
            token.safeApprove(to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function universalDecimals(IERC20 token) internal view returns (uint256) {

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall.gas(5000)(
            abi.encodeWithSignature("decimals()")
        );
        if (!success) {
            (success, data) = address(token).staticcall.gas(5000)(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return success ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS));
    }
}

// File: contracts/OneSplit.sol

pragma solidity ^0.5.0;
















contract OneSplit {

    using SafeMath for uint256;
    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;
    using UniversalERC20 for IBancorEtherToken;

    IWETH wethToken = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IBancorEtherToken bancorEtherToken = IBancorEtherToken(0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315);

    ICompound public compound = ICompound(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    ICompoundEther public cETH = ICompoundEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);

    IKyberNetworkProxy public kyberNetworkProxy = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    IUniswapFactory public uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    IBancorContractRegistry public bancorContractRegistry = IBancorContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
    IBancorNetworkPathFinder bancorNetworkPathFinder = IBancorNetworkPathFinder(0x6F0cD8C4f6F06eAB664C7E3031909452b4B72861);
    IOasisExchange public oasisExchange = IOasisExchange(0x39755357759cE0d7f32dC8dC45414CCa409AE24e);

    function log(uint256) external view {
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags // 1 - Uniswap, 2 - Kyber, 4 - Bancor, 8 - Oasis, 16 - Compound
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution // [Uniswap, Kyber, Bancor, Oasis]
        )
    {
        distribution = new uint256[](4);

        if (fromToken == toToken) {
            returnAmount = amount;
            return (returnAmount, distribution);
        }

        if ((disableFlags & 16 == 0) && _isCompoundToken(fromToken)) {
            IERC20 underlying = _compoundUnderlyingAsset(fromToken);
            uint256 compoundRate = ICompoundToken(address(fromToken)).exchangeRateStored();

            return getExpectedReturn(
                underlying,
                toToken,
                amount.mul(compoundRate).div(1e18),
                parts,
                disableFlags
            );
        }

        if ((disableFlags & 16 == 0) && _isCompoundToken(toToken)) {
            IERC20 underlying = _compoundUnderlyingAsset(toToken);
            uint256 compoundRate = ICompoundToken(address(toToken)).exchangeRateStored();

            (returnAmount, distribution) = getExpectedReturn(
                fromToken,
                underlying,
                amount,
                parts,
                disableFlags
            );

            returnAmount = returnAmount.mul(1e18).div(compoundRate);
            return (returnAmount, distribution);
        }

        function(IERC20,IERC20,uint256) view returns(uint256)[4] memory reserves = [
            uint256(disableFlags & 1) != 0 ? _calculateNoReturn : _calculateUniswapReturn,
            uint256(disableFlags & 2) != 0 ? _calculateNoReturn : _calculateKyberReturn,
            uint256(disableFlags & 4) != 0 ? _calculateNoReturn : _calculateBancorReturn,
            uint256(disableFlags & 8) != 0 ? _calculateNoReturn : _calculateOasisReturn
        ];

        uint256[4] memory rates;
        uint256[4] memory fullRates;
        for (uint i = 0; i < rates.length; i++) {
            rates[i] = reserves[i](fromToken, toToken, amount.div(parts));
            this.log(rates[i]);
            fullRates[i] = rates[i];
        }

        for (uint j = 0; j < parts; j++) {
            // Find best part
            uint256 bestIndex = 0;
            for (uint i = 1; i < rates.length; i++) {
                if (rates[i] > rates[bestIndex]) {
                    bestIndex = i;
                }
            }

            // Add best part
            returnAmount = returnAmount.add(rates[bestIndex]);
            distribution[bestIndex]++;

            // Avoid CompilerError: Stack too deep
            uint256 srcAmount = amount;

            // Recalc part if needed
            if (j + 1 < parts) {
                uint256 newRate = reserves[bestIndex](
                    fromToken,
                    toToken,
                    srcAmount.mul(distribution[bestIndex] + 1).div(parts)
                );
                rates[bestIndex] = newRate.sub(fullRates[bestIndex]);
                this.log(rates[bestIndex]);
                fullRates[bestIndex] = newRate;
            }
        }
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution, // [Uniswap, Kyber, Bancor, Oasis]
        uint256 disableFlags // 16 - Compound
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
        uint256 disableFlags // 16 - Compound
    ) internal {
        if (fromToken == toToken) {
            return;
        }

        if ((disableFlags & 16 == 0) && _isCompoundToken(fromToken)) {
            IERC20 underlying = _compoundUnderlyingAsset(fromToken);

            ICompoundToken(address(fromToken)).redeem(amount);
            uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

            return _swap(
                underlying,
                toToken,
                underlyingAmount,
                distribution,
                disableFlags
            );
        }

        if ((disableFlags & 16 == 0) && _isCompoundToken(toToken)) {
            IERC20 underlying = _compoundUnderlyingAsset(toToken);

            _swap(
                fromToken,
                underlying,
                amount,
                distribution,
                disableFlags
            );

            uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

            if (underlying.isETH()) {
                cETH.mint.value(underlyingAmount)();
            } else {
                _infiniteApproveIfNeeded(underlying, address(toToken));
                ICompoundToken(address(toToken)).mint(underlyingAmount);
            }
            return;
        }

        function(IERC20,IERC20,uint256) returns(uint256)[4] memory reserves = [
            _swapOnUniswap,
            _swapOnKyber,
            _swapOnBancor,
            _swapOnOasis
        ];

        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < reserves.length; i++) {
            if (distribution[i] > 0) {
                parts = parts.add(distribution[i]);
                lastNonZeroIndex = i;
            }
        }

        require(parts > 0, "OneSplit: distribution should contain non-zeros");

        uint256 remainingAmount = amount;
        for (uint i = 0; i < reserves.length; i++) {
            if (distribution[i] == 0) {
                continue;
            }

            uint256 swapAmount = amount.mul(distribution[i]).div(parts);
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            reserves[i](fromToken, toToken, swapAmount);
        }
    }

    function goodSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256 parts,
        uint256 disableFlags // 1 - Uniswap, 2 - Kyber, 4 - Bancor, 8 - Oasis, 16 - Compound
    ) public payable {
        (, uint256[] memory distribution) = getExpectedReturn(fromToken, toToken, amount, parts, disableFlags);
        swap(
            fromToken,
            toToken,
            amount,
            minReturn,
            distribution,
            disableFlags
        );
    }

    // View Helpers

    function _calculateUniswapReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal view returns(uint256) {
        uint256 returnAmount = amount;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(fromToken);
            if (fromExchange != IUniswapExchange(0)) {
                (bool success, bytes memory data) = address(fromExchange).staticcall.gas(200000)(
                    abi.encodeWithSelector(
                        fromExchange.getTokenToEthInputPrice.selector,
                        returnAmount
                    )
                );
                if (success) {
                    returnAmount = abi.decode(data, (uint256));
                } else {
                    returnAmount = 0;
                }
            }
        }

        if (!toToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(toToken);
            if (toExchange != IUniswapExchange(0)) {
                (bool success, bytes memory data) = address(toExchange).staticcall.gas(200000)(
                    abi.encodeWithSelector(
                        toExchange.getEthToTokenInputPrice.selector,
                        returnAmount
                    )
                );
                if (success) {
                    returnAmount = abi.decode(data, (uint256));
                } else {
                    returnAmount = 0;
                }
            }
        }

        return returnAmount;
    }

    function _calculateKyberReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal view returns(uint256) {
        (bool success, bytes memory data) = address(kyberNetworkProxy).staticcall.gas(2300)(abi.encodeWithSelector(
            kyberNetworkProxy.kyberNetworkContract.selector
        ));
        if (!success) {
            return 0;
        }

        IKyberNetworkContract kyberNetworkContract = IKyberNetworkContract(abi.decode(data, (address)));

        (success, data) = address(kyberNetworkContract).staticcall.gas(200000)(abi.encodeWithSelector(
            kyberNetworkContract.searchBestRate.selector,
            fromToken.isETH() ? IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) : fromToken,
            toToken.isETH() ? IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) : toToken,
            amount,
            true
        ));
        if (!success) {
            return 0;
        }

        (address reserve, uint256 rate) = abi.decode(data, (address,uint256));

        // Check for Uniswap, Oasis and Bancor reserves
        if (reserve == 0x54A4a1167B004b004520c605E3f01906f683413d ||
            reserve == 0xCf1394C5e2e879969fdB1f464cE1487147863dCb ||
            reserve == 0x053AA84FCC676113a57e0EbB0bD1913839874bE4)
        {
            return 0;
        }

        // Check for Uniswap reserve
        (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
            IKyberUniswapReserve(reserve).uniswapFactory.selector
        ));
        if (success) {
            return 0;
        }

        // Check for Oasis reserve
        (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
            IKyberOasisReserve(reserve).otc.selector
        ));
        if (success) {
            return 0;
        }

        // Check for Bancor reserve
        (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
            IKyberBancorReserve(reserve).bancorEth.selector
        ));
        if (success) {
            return 0;
        }

        return rate.mul(amount)
            .mul(10 ** IERC20(toToken).universalDecimals())
            .div(10 ** IERC20(fromToken).universalDecimals())
            .div(1e18);
    }

    function _calculateBancorReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal view returns(uint256) {
        IBancorNetwork bancorNetwork = IBancorNetwork(bancorContractRegistry.addressOf("BancorNetwork"));
        address[] memory path = bancorNetworkPathFinder.generatePath(
            fromToken.isETH() ? bancorEtherToken : fromToken,
            toToken.isETH() ? bancorEtherToken : toToken
        );

        (bool success, bytes memory data) = address(bancorNetwork).staticcall.gas(200000)(
            abi.encodeWithSelector(
                bancorNetwork.getReturnByPath.selector,
                path,
                amount
            )
        );
        if (!success) {
            return 0;
        }

        (uint256 returnAmount,) = abi.decode(data, (uint256,uint256));
        return returnAmount;
    }

    function _calculateOasisReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal view returns(uint256) {
        (bool success, bytes memory data) = address(oasisExchange).staticcall.gas(500000)(
            abi.encodeWithSelector(
                oasisExchange.getBuyAmount.selector,
                toToken.isETH() ? wethToken : toToken,
                fromToken.isETH() ? wethToken : fromToken,
                amount
            )
        );
        if (!success) {
            return 0;
        }

        return abi.decode(data, (uint256));
    }

    function _calculateNoReturn(
        IERC20 /*fromToken*/,
        IERC20 /*toToken*/,
        uint256 /*amount*/
    ) internal view returns(uint256) {
        this;
    }

    // Swap Helpers

    function _swapOnUniswap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {

        uint256 returnAmount = amount;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(fromToken);
            if (fromExchange != IUniswapExchange(0)) {
                _infiniteApproveIfNeeded(fromToken, address(fromExchange));
                returnAmount = fromExchange.tokenToEthSwapInput(returnAmount, 1, now);
            }
        }

        if (!toToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(toToken);
            if (toExchange != IUniswapExchange(0)) {
                returnAmount = toExchange.ethToTokenSwapInput.value(returnAmount)(1, now);
            }
        }

        return returnAmount;
    }

    function _swapOnKyber(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {
        _infiniteApproveIfNeeded(fromToken, address(kyberNetworkProxy));
        return kyberNetworkProxy.tradeWithHint.value(fromToken.isETH() ? amount : 0)(
            fromToken.isETH() ? IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) : fromToken,
            amount,
            toToken.isETH() ? IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) : toToken,
            address(this),
            1 << 255,
            0,
            address(0),
            ""
        );
    }

    function _swapOnBancor(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {
        if (fromToken.isETH()) {
            bancorEtherToken.deposit.value(amount)();
        }

        IBancorNetwork bancorNetwork = IBancorNetwork(bancorContractRegistry.addressOf("BancorNetwork"));
        address[] memory path = bancorNetworkPathFinder.generatePath(
            fromToken.isETH() ? bancorEtherToken : fromToken,
            toToken.isETH() ? bancorEtherToken : toToken
        );

        _infiniteApproveIfNeeded(fromToken.isETH() ? bancorEtherToken : fromToken, address(bancorNetwork));
        uint256 returnAmount = bancorNetwork.claimAndConvert(path, amount, 1);

        if (toToken.isETH()) {
            bancorEtherToken.withdraw(bancorEtherToken.balanceOf(address(this)));
        }

        return returnAmount;
    }

    function _swapOnOasis(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {
        if (fromToken.isETH()) {
            wethToken.deposit.value(amount)();
        }

        _infiniteApproveIfNeeded(fromToken.isETH() ? wethToken : fromToken, address(oasisExchange));
        uint256 returnAmount = oasisExchange.sellAllAmount(
            fromToken.isETH() ? wethToken : fromToken,
            amount,
            toToken.isETH() ? wethToken : toToken,
            1
        );

        if (toToken.isETH()) {
            wethToken.withdraw(wethToken.balanceOf(address(this)));
        }

        return returnAmount;
    }

    // Helpers

    function _infiniteApproveIfNeeded(IERC20 token, address to) internal {
        if (!token.isETH()) {
            if ((token.allowance(address(this), to) >> 255) == 0) {
                token.universalApprove(to, uint256(- 1));
            }
        }
    }

    function _isCompoundToken(IERC20 token) internal view returns(bool) {
        if (token == cETH) {
            return true;
        }
        (bool isListed,) = compound.markets(address(token));
        return isListed;
    }

    function _compoundUnderlyingAsset(IERC20 asset) internal view returns(IERC20) {
        if (asset == cETH) {
            return IERC20(address(0));
        }
        return IERC20(ICompoundToken(address(asset)).underlying());
    }
}
