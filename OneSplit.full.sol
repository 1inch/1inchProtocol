
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

// File: contracts/IOneSplit.sol

pragma solidity ^0.5.0;


//
//  [ msg.sender ]
//       | |
//       | |
//       \_/
// +---------------+ ________________________________
// | OneSplitAudit | _______________________________  \
// +---------------+                                 \ \
//       | |                      ______________      | | (staticcall)
//       | |                    /  ____________  \    | |
//       | | (call)            / /              \ \   | |
//       | |                  / /               | |   | |
//       \_/                  | |               \_/   \_/
// +--------------+           | |           +----------------------+
// | OneSplitWrap |           | |           |   OneSplitViewWrap   |
// +--------------+           | |           +----------------------+
//       | |                  | |                     | |
//       | | (delegatecall)   | | (staticcall)        | | (staticcall)
//       \_/                  | |                     \_/
// +--------------+           | |             +------------------+
// |   OneSplit   |           | |             |   OneSplitView   |
// +--------------+           | |             +------------------+
//       | |                  / /
//        \ \________________/ /
//         \__________________/
//


contract IOneSplitConsts {
    // flags = FLAG_DISABLE_UNISWAP + FLAG_DISABLE_BANCOR + ...
    uint256 internal constant FLAG_DISABLE_UNISWAP = 0x01;
    uint256 internal constant DEPRECATED_FLAG_DISABLE_KYBER = 0x02; // Deprecated
    uint256 internal constant FLAG_DISABLE_BANCOR = 0x04;
    uint256 internal constant FLAG_DISABLE_OASIS = 0x08;
    uint256 internal constant FLAG_DISABLE_COMPOUND = 0x10;
    uint256 internal constant FLAG_DISABLE_FULCRUM = 0x20;
    uint256 internal constant FLAG_DISABLE_CHAI = 0x40;
    uint256 internal constant FLAG_DISABLE_AAVE = 0x80;
    uint256 internal constant FLAG_DISABLE_SMART_TOKEN = 0x100;
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_ETH = 0x200; // Deprecated, Turned off by default
    uint256 internal constant FLAG_DISABLE_BDAI = 0x400;
    uint256 internal constant FLAG_DISABLE_IEARN = 0x800;
    uint256 internal constant FLAG_DISABLE_CURVE_COMPOUND = 0x1000;
    uint256 internal constant FLAG_DISABLE_CURVE_USDT = 0x2000;
    uint256 internal constant FLAG_DISABLE_CURVE_Y = 0x4000;
    uint256 internal constant FLAG_DISABLE_CURVE_BINANCE = 0x8000;
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_DAI = 0x10000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_USDC = 0x20000; // Deprecated, Turned off by default
    uint256 internal constant FLAG_DISABLE_CURVE_SYNTHETIX = 0x40000;
    uint256 internal constant FLAG_DISABLE_WETH = 0x80000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_COMPOUND = 0x100000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
    uint256 internal constant FLAG_DISABLE_UNISWAP_CHAI = 0x200000; // Works only when ETH<>DAI or FLAG_ENABLE_MULTI_PATH_ETH
    uint256 internal constant FLAG_DISABLE_UNISWAP_AAVE = 0x400000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
    uint256 internal constant FLAG_DISABLE_IDLE = 0x800000;
    uint256 internal constant FLAG_DISABLE_MOONISWAP = 0x1000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2 = 0x2000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_ETH = 0x4000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_DAI = 0x8000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_USDC = 0x10000000;
    uint256 internal constant FLAG_DISABLE_ALL_SPLIT_SOURCES = 0x20000000;
    uint256 internal constant FLAG_DISABLE_ALL_WRAP_SOURCES = 0x40000000;
    uint256 internal constant FLAG_DISABLE_CURVE_PAX = 0x80000000;
    uint256 internal constant FLAG_DISABLE_CURVE_RENBTC = 0x100000000;
    uint256 internal constant FLAG_DISABLE_CURVE_TBTC = 0x200000000;
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_USDT = 0x400000000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_WBTC = 0x800000000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_TBTC = 0x1000000000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_RENBTC = 0x2000000000; // Deprecated, Turned off by default
    uint256 internal constant FLAG_DISABLE_DFORCE_SWAP = 0x4000000000;
    uint256 internal constant FLAG_DISABLE_SHELL = 0x8000000000;
    uint256 internal constant FLAG_ENABLE_CHI_BURN = 0x10000000000;
    uint256 internal constant FLAG_DISABLE_MSTABLE_MUSD = 0x20000000000;
    uint256 internal constant FLAG_DISABLE_CURVE_SBTC = 0x40000000000;
    uint256 internal constant FLAG_DISABLE_DMM = 0x80000000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_ALL = 0x100000000000;
    uint256 internal constant FLAG_DISABLE_CURVE_ALL = 0x200000000000;
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_ALL = 0x400000000000;
    uint256 internal constant FLAG_DISABLE_SPLIT_RECALCULATION = 0x800000000000;
    uint256 internal constant FLAG_DISABLE_BALANCER_ALL = 0x1000000000000;
    uint256 internal constant FLAG_DISABLE_BALANCER_1 = 0x2000000000000;
    uint256 internal constant FLAG_DISABLE_BALANCER_2 = 0x4000000000000;
    uint256 internal constant FLAG_DISABLE_BALANCER_3 = 0x8000000000000;
    uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_UNISWAP_RESERVE = 0x10000000000000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_OASIS_RESERVE = 0x20000000000000; // Deprecated, Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_BANCOR_RESERVE = 0x40000000000000; // Deprecated, Turned off by default
    uint256 internal constant FLAG_ENABLE_REFERRAL_GAS_SPONSORSHIP = 0x80000000000000; // Turned off by default
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_COMP = 0x100000000000000; // Deprecated, Turned off by default
    uint256 internal constant FLAG_DISABLE_KYBER_ALL = 0x200000000000000;
    uint256 internal constant FLAG_DISABLE_KYBER_1 = 0x400000000000000;
    uint256 internal constant FLAG_DISABLE_KYBER_2 = 0x800000000000000;
    uint256 internal constant FLAG_DISABLE_KYBER_3 = 0x1000000000000000;
    uint256 internal constant FLAG_DISABLE_KYBER_4 = 0x2000000000000000;
    uint256 internal constant FLAG_ENABLE_CHI_BURN_BY_ORIGIN = 0x4000000000000000;
    uint256 internal constant FLAG_DISABLE_MOONISWAP_ALL = 0x8000000000000000;
    uint256 internal constant FLAG_DISABLE_MOONISWAP_ETH = 0x10000000000000000;
    uint256 internal constant FLAG_DISABLE_MOONISWAP_DAI = 0x20000000000000000;
    uint256 internal constant FLAG_DISABLE_MOONISWAP_USDC = 0x40000000000000000;
    uint256 internal constant FLAG_DISABLE_MOONISWAP_POOL_TOKEN = 0x80000000000000000;
}


contract IOneSplit is IOneSplitConsts {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );

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
        );

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    )
        public
        payable
        returns(uint256 returnAmount);
}


contract IOneSplitMulti is IOneSplit {
    function getExpectedReturnWithGasMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256[] memory parts,
        uint256[] memory flags,
        uint256[] memory destTokenEthPriceTimesGasPrices
    )
        public
        view
        returns(
            uint256[] memory returnAmounts,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    function swapMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256[] memory flags
    )
        public
        payable
        returns(uint256 returnAmount);
}

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

// File: contracts/interface/IUniswapExchange.sol

pragma solidity ^0.5.0;



interface IUniswapExchange {
    function getEthToTokenInputPrice(uint256 ethSold) external view returns (uint256 tokensBought);

    function getTokenToEthInputPrice(uint256 tokensSold) external view returns (uint256 ethBought);

    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline)
        external
        payable
        returns (uint256 tokensBought);

    function tokenToEthSwapInput(uint256 tokensSold, uint256 minEth, uint256 deadline)
        external
        returns (uint256 ethBought);

    function tokenToTokenSwapInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address tokenAddr
    ) external returns (uint256 tokensBought);
}

// File: contracts/interface/IUniswapFactory.sol

pragma solidity ^0.5.0;



interface IUniswapFactory {
    function getExchange(IERC20 token) external view returns (IUniswapExchange exchange);
}

// File: contracts/interface/IKyberNetworkContract.sol

pragma solidity ^0.5.0;



interface IKyberNetworkContract {
    function searchBestRate(IERC20 src, IERC20 dest, uint256 srcAmount, bool usePermissionless)
        external
        view
        returns (address reserve, uint256 rate);
}

// File: contracts/interface/IKyberNetworkProxy.sol

pragma solidity ^0.5.0;



interface IKyberNetworkProxy {
    function getExpectedRateAfterFee(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external view returns (uint256 expectedRate);

    function tradeWithHintAndFee(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable returns (uint256 destAmount);

    function kyberNetworkContract() external view returns (IKyberNetworkContract);

    // TODO: Limit usage by tx.gasPrice
    // function maxGasPrice() external view returns (uint256);

    // TODO: Limit usage by user cap
    // function getUserCapInWei(address user) external view returns (uint256);
    // function getUserCapInTokenWei(address user, IERC20 token) external view returns (uint256);
}

// File: contracts/interface/IKyberStorage.sol

pragma solidity ^0.5.0;



interface IKyberStorage {
    function getReserveIdsPerTokenSrc(
        IERC20 token
    ) external view returns (bytes32[] memory);
}

// File: contracts/interface/IKyberHintHandler.sol

pragma solidity ^0.5.0;



interface IKyberHintHandler {
    enum TradeType {
        BestOfAll,
        MaskIn,
        MaskOut,
        Split
    }

    function buildTokenToEthHint(
        IERC20 tokenSrc,
        TradeType tokenToEthType,
        bytes32[] calldata tokenToEthReserveIds,
        uint256[] calldata tokenToEthSplits
    ) external view returns (bytes memory hint);

    function buildEthToTokenHint(
        IERC20 tokenDest,
        TradeType ethToTokenType,
        bytes32[] calldata ethToTokenReserveIds,
        uint256[] calldata ethToTokenSplits
    ) external view returns (bytes memory hint);
}

// File: contracts/interface/IBancorNetwork.sol

pragma solidity ^0.5.0;


interface IBancorNetwork {
    function getReturnByPath(address[] calldata path, uint256 amount)
        external
        view
        returns (uint256 returnAmount, uint256 conversionFee);

    function claimAndConvert(address[] calldata path, uint256 amount, uint256 minReturn)
        external
        returns (uint256);

    function convert(address[] calldata path, uint256 amount, uint256 minReturn)
        external
        payable
        returns (uint256);
}

// File: contracts/interface/IBancorContractRegistry.sol

pragma solidity ^0.5.0;


contract IBancorContractRegistry {
    function addressOf(bytes32 contractName) external view returns (address);
}

// File: contracts/interface/IBancorNetworkPathFinder.sol

pragma solidity ^0.5.0;



interface IBancorNetworkPathFinder {
    function generatePath(IERC20 sourceToken, IERC20 targetToken)
        external
        view
        returns (address[] memory);
}

// File: contracts/interface/IBancorConverterRegistry.sol

pragma solidity ^0.5.0;



interface IBancorConverterRegistry {

    function getConvertibleTokenSmartTokenCount(IERC20 convertibleToken)
        external view returns(uint256);

    function getConvertibleTokenSmartTokens(IERC20 convertibleToken)
        external view returns(address[] memory);

    function getConvertibleTokenSmartToken(IERC20 convertibleToken, uint256 index)
        external view returns(address);

    function isConvertibleTokenSmartToken(IERC20 convertibleToken, address value)
        external view returns(bool);
}

// File: contracts/interface/IBancorEtherToken.sol

pragma solidity ^0.5.0;



contract IBancorEtherToken is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// File: contracts/interface/IBancorFinder.sol

pragma solidity ^0.5.0;



interface IBancorFinder {
    function buildBancorPath(
        IERC20 fromToken,
        IERC20 destToken
    )
        external
        view
        returns(address[] memory path);
}

// File: contracts/interface/IOasisExchange.sol

pragma solidity ^0.5.0;



interface IOasisExchange {
    function getBuyAmount(IERC20 buyGem, IERC20 payGem, uint256 payAmt)
        external
        view
        returns (uint256 fillAmt);

    function sellAllAmount(IERC20 payGem, uint256 payAmt, IERC20 buyGem, uint256 minFillAmount)
        external
        returns (uint256 fillAmt);
}

// File: contracts/interface/IWETH.sol

pragma solidity ^0.5.0;



contract IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// File: contracts/interface/ICurve.sol

pragma solidity ^0.5.0;


interface ICurve {
    // solium-disable-next-line mixedcase
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns(uint256 dy);

    // solium-disable-next-line mixedcase
    function get_dy(int128 i, int128 j, uint256 dx) external view returns(uint256 dy);

    // solium-disable-next-line mixedcase
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 minDy) external;

    // solium-disable-next-line mixedcase
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external;
}


contract ICurveRegistry {
    function get_pool_info(address pool)
        external
        view
        returns(
            uint256[8] memory balances,
            uint256[8] memory underlying_balances,
            uint256[8] memory decimals,
            uint256[8] memory underlying_decimals,
            address lp_token,
            uint256 A,
            uint256 fee
        );
}


contract ICurveCalculator {
    function get_dy(
        int128 nCoins,
        uint256[8] calldata balances,
        uint256 amp,
        uint256 fee,
        uint256[8] calldata rates,
        uint256[8] calldata precisions,
        bool underlying,
        int128 i,
        int128 j,
        uint256[100] calldata dx
    ) external view returns(uint256[100] memory dy);
}

// File: contracts/interface/IChai.sol

pragma solidity ^0.5.0;



interface IPot {
    function dsr() external view returns (uint256);

    function chi() external view returns (uint256);

    function rho() external view returns (uint256);

    function drip() external returns (uint256);

    function join(uint256) external;

    function exit(uint256) external;
}


contract IChai is IERC20 {
    function POT() public view returns (IPot);

    function join(address dst, uint256 wad) external;

    function exit(address src, uint256 wad) external;
}


library ChaiHelper {
    IPot private constant POT = IPot(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    uint256 private constant RAY = 10**27;

    function _mul(uint256 x, uint256 y) private pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function _rmul(uint256 x, uint256 y) private pure returns (uint256 z) {
        // always rounds down
        z = _mul(x, y) / RAY;
    }

    function _rdiv(uint256 x, uint256 y) private pure returns (uint256 z) {
        // always rounds down
        z = _mul(x, RAY) / y;
    }

    function rpow(uint256 x, uint256 n, uint256 base) private pure returns (uint256 z) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            switch x
                case 0 {
                    switch n
                        case 0 {
                            z := base
                        }
                        default {
                            z := 0
                        }
                }
                default {
                    switch mod(n, 2)
                        case 0 {
                            z := base
                        }
                        default {
                            z := x
                        }
                    let half := div(base, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if iszero(eq(div(xx, x), x)) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, base)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, base)
                        }
                    }
                }
        }
    }

    function potDrip() private view returns (uint256) {
        return _rmul(rpow(POT.dsr(), now - POT.rho(), RAY), POT.chi());
    }

    function chaiPrice(IChai chai) internal view returns(uint256) {
        return chaiToDai(chai, 1e18);
    }

    function daiToChai(
        IChai /*chai*/,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 chi = (now > POT.rho()) ? potDrip() : POT.chi();
        return _rdiv(amount, chi);
    }

    function chaiToDai(
        IChai /*chai*/,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 chi = (now > POT.rho()) ? potDrip() : POT.chi();
        return _rmul(chi, amount);
    }
}

// File: contracts/interface/ICompound.sol

pragma solidity ^0.5.0;



contract ICompound {
    function markets(address cToken)
        external
        view
        returns (bool isListed, uint256 collateralFactorMantissa);
}


contract ICompoundToken is IERC20 {
    function underlying() external view returns (address);

    function exchangeRateStored() external view returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);
}


contract ICompoundEther is IERC20 {
    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);
}

// File: contracts/interface/ICompoundRegistry.sol

pragma solidity ^0.5.0;




contract ICompoundRegistry {
    function tokenByCToken(ICompoundToken cToken) external view returns(IERC20);
    function cTokenByToken(IERC20 token) external view returns(ICompoundToken);
}

// File: contracts/interface/IAaveToken.sol

pragma solidity ^0.5.0;



contract IAaveToken is IERC20 {
    function underlyingAssetAddress() external view returns (IERC20);

    function redeem(uint256 amount) external;
}


interface IAaveLendingPool {
    function core() external view returns (address);

    function deposit(IERC20 token, uint256 amount, uint16 refCode) external payable;
}

// File: contracts/interface/IAaveRegistry.sol

pragma solidity ^0.5.0;




contract IAaveRegistry {
    function tokenByAToken(IAaveToken aToken) external view returns(IERC20);
    function aTokenByToken(IERC20 token) external view returns(IAaveToken);
}

// File: contracts/interface/IMooniswap.sol

pragma solidity ^0.5.0;



interface IMooniswapRegistry {
    function pools(IERC20 token1, IERC20 token2) external view returns(IMooniswap);
    function isPool(address addr) external view returns(bool);
}


interface IMooniswap {
    function fee() external view returns (uint256);

    function tokens(uint256 i) external view returns (IERC20);

    function deposit(uint256[] calldata amounts, uint256[] calldata minAmounts) external payable returns(uint256 fairSupply);

    function withdraw(uint256 amount, uint256[] calldata minReturns) external;

    function getBalanceForAddition(IERC20 token) external view returns(uint256);

    function getBalanceForRemoval(IERC20 token) external view returns(uint256);

    function getReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    )
        external
        view
        returns(uint256 returnAmount);

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        address referral
    )
        external
        payable
        returns(uint256 returnAmount);
}

// File: @openzeppelin/contracts/math/Math.sol

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
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
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        if (isETH(token)) {
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

        if (isETH(token)) {
            require(from == msg.sender && msg.value >= amount, "Wrong useage of ETH.universalTransferFrom()");
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

    function universalTransferFromSenderToThis(IERC20 token, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            if (msg.value > amount) {
                // Return remainder if exist
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function universalApprove(IERC20 token, address to, uint256 amount) internal {
        if (!isETH(token)) {
            if (amount == 0) {
                token.safeApprove(to, 0);
                return;
            }

            uint256 allowance = token.allowance(address(this), to);
            if (allowance < amount) {
                if (allowance > 0) {
                    token.safeApprove(to, 0);
                }
                token.safeApprove(to, amount);
            }
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function universalDecimals(IERC20 token) internal view returns (uint256) {

        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall.gas(10000)(
            abi.encodeWithSignature("decimals()")
        );
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall.gas(10000)(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS));
    }

    function eq(IERC20 a, IERC20 b) internal pure returns(bool) {
        return a == b || (isETH(a) && isETH(b));
    }

    function notExist(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(-1));
    }
}

// File: contracts/interface/IUniswapV2Exchange.sol

pragma solidity ^0.5.0;






interface IUniswapV2Exchange {
    function getReserves() external view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
}


library UniswapV2ExchangeLib {
    using Math for uint256;
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    function getReturn(
        IUniswapV2Exchange exchange,
        IERC20 fromToken,
        IERC20 destToken,
        uint amountIn
    ) internal view returns (uint256 result, bool needSync, bool needSkim) {
        uint256 reserveIn = fromToken.universalBalanceOf(address(exchange));
        uint256 reserveOut = destToken.universalBalanceOf(address(exchange));
        (uint112 reserve0, uint112 reserve1,) = exchange.getReserves();
        if (fromToken > destToken) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        needSync = (reserveIn < reserve0 || reserveOut < reserve1);
        needSkim = !needSync && (reserveIn > reserve0 || reserveOut > reserve1);

        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(Math.min(reserveOut, reserve1));
        uint256 denominator = Math.min(reserveIn, reserve0).mul(1000).add(amountInWithFee);
        result = (denominator == 0) ? 0 : numerator.div(denominator);
    }
}

// File: contracts/interface/IUniswapV2Factory.sol

pragma solidity ^0.5.0;



interface IUniswapV2Factory {
    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniswapV2Exchange pair);
}

// File: contracts/interface/IDForceSwap.sol

pragma solidity ^0.5.0;



interface IDForceSwap {
    function getAmountByInput(IERC20 input, IERC20 output, uint256 amount) external view returns(uint256);
    function swap(IERC20 input, IERC20 output, uint256 amount) external;
}

// File: contracts/interface/IShell.sol

pragma solidity ^0.5.0;


interface IShell {
    function viewOriginTrade(
        address origin,
        address target,
        uint256 originAmount
    ) external view returns (uint256);

    function swapByOrigin(
        address origin,
        address target,
        uint256 originAmount,
        uint256 minTargetAmount,
        uint256 deadline
    ) external returns (uint256);
}

// File: contracts/interface/IMStable.sol

pragma solidity ^0.5.0;



contract IMStable is IERC20 {
    function getSwapOutput(
        IERC20 _input,
        IERC20 _output,
        uint256 _quantity
    )
        external
        view
        returns (bool, string memory, uint256 output);

    function swap(
        IERC20 _input,
        IERC20 _output,
        uint256 _quantity,
        address _recipient
    )
        external
        returns (uint256 output);

    function redeem(
        IERC20 _basset,
        uint256 _bassetQuantity
    )
        external
        returns (uint256 massetRedeemed);
}

interface IMassetValidationHelper {
    /**
     * @dev Returns a valid bAsset to redeem
     * @param _mAsset Masset addr
     * @return valid bool
     * @return string message
     * @return address of bAsset to redeem
     */
    function suggestRedeemAsset(
        IERC20 _mAsset
    )
        external
        view
        returns (
            bool valid,
            string memory err,
            address token
        );

    /**
     * @dev Returns a valid bAsset with which to mint
     * @param _mAsset Masset addr
     * @return valid bool
     * @return string message
     * @return address of bAsset to mint
     */
    function suggestMintAsset(
        IERC20 _mAsset
    )
        external
        view
        returns (
            bool valid,
            string memory err,
            address token
        );

    /**
     * @dev Determines if a given Redemption is valid
     * @param _mAsset Address of the given mAsset (e.g. mUSD)
     * @param _mAssetQuantity Amount of mAsset to redeem (in mUSD units)
     * @param _outputBasset Desired output bAsset
     * @return valid
     * @return validity reason
     * @return output in bAsset units
     * @return bAssetQuantityArg - required input argument to the 'redeem' call
     */
    function getRedeemValidity(
        IERC20 _mAsset,
        uint256 _mAssetQuantity,
        IERC20 _outputBasset
    )
        external
        view
        returns (
            bool valid,
            string memory,
            uint256 output,
            uint256 bassetQuantityArg
        );
}

// File: contracts/interface/IBalancerPool.sol

pragma solidity ^0.5.0;



interface IBalancerPool {
    function getSwapFee()
        external view returns (uint256 balance);

    function getDenormalizedWeight(IERC20 token)
        external view returns (uint256 balance);

    function getBalance(IERC20 token)
        external view returns (uint256 balance);

    function swapExactAmountIn(
        IERC20 tokenIn,
        uint256 tokenAmountIn,
        IERC20 tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    )
        external
        returns (uint256 tokenAmountOut, uint256 spotPriceAfter);
}


// 0xA961672E8Db773be387e775bc4937C678F3ddF9a
interface IBalancerHelper {
    function getReturns(
        IBalancerPool pool,
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] calldata amounts
    )
        external
        view
        returns(uint256[] memory rets);
}

// File: contracts/interface/IBalancerRegistry.sol

pragma solidity ^0.5.0;




interface IBalancerRegistry {
    event PoolAdded(
        address indexed pool
    );
    event PoolTokenPairAdded(
        address indexed pool,
        address indexed fromToken,
        address indexed destToken
    );
    event IndicesUpdated(
        address indexed fromToken,
        address indexed destToken,
        bytes32 oldIndices,
        bytes32 newIndices
    );

    // Get info about pool pair for 1 SLOAD
    function getPairInfo(address pool, address fromToken, address destToken)
        external view returns(uint256 weight1, uint256 weight2, uint256 swapFee);

    // Pools
    function checkAddedPools(address pool)
        external view returns(bool);
    function getAddedPoolsLength()
        external view returns(uint256);
    function getAddedPools()
        external view returns(address[] memory);
    function getAddedPoolsWithLimit(uint256 offset, uint256 limit)
        external view returns(address[] memory result);

    // Tokens
    function getAllTokensLength()
        external view returns(uint256);
    function getAllTokens()
        external view returns(address[] memory);
    function getAllTokensWithLimit(uint256 offset, uint256 limit)
        external view returns(address[] memory result);

    // Pairs
    function getPoolsLength(address fromToken, address destToken)
        external view returns(uint256);
    function getPools(address fromToken, address destToken)
        external view returns(address[] memory);
    function getPoolsWithLimit(address fromToken, address destToken, uint256 offset, uint256 limit)
        external view returns(address[] memory result);
    function getBestPools(address fromToken, address destToken)
        external view returns(address[] memory pools);
    function getBestPoolsWithLimit(address fromToken, address destToken, uint256 limit)
        external view returns(address[] memory pools);

    // Get swap rates
    function getPoolReturn(address pool, address fromToken, address destToken, uint256 amount)
        external view returns(uint256);
    function getPoolReturns(address pool, address fromToken, address destToken, uint256[] calldata amounts)
        external view returns(uint256[] memory result);

    // Add and update registry
    function addPool(address pool) external returns(uint256 listed);
    function addPools(address[] calldata pools) external returns(uint256[] memory listed);
    function updatedIndices(address[] calldata tokens, uint256 lengthLimit) external;
}

// File: contracts/BalancerLib.sol

pragma solidity ^0.5.0;


library BalancerLib {
    uint public constant BONE              = 10**18;

    uint public constant MIN_BOUND_TOKENS  = 2;
    uint public constant MAX_BOUND_TOKENS  = 8;

    uint public constant MIN_FEE           = BONE / 10**6;
    uint public constant MAX_FEE           = BONE / 10;
    uint public constant EXIT_FEE          = 0;

    uint public constant MIN_WEIGHT        = BONE;
    uint public constant MAX_WEIGHT        = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT  = BONE * 50;
    uint public constant MIN_BALANCE       = BONE / 10**12;

    uint public constant INIT_POOL_SUPPLY  = BONE * 100;

    uint public constant MIN_BPOW_BASE     = 1 wei;
    uint public constant MAX_BPOW_BASE     = (2 * BONE) - 1 wei;
    uint public constant BPOW_PRECISION    = BONE / 10**10;

    uint public constant MAX_IN_RATIO      = BONE / 2;
    uint public constant MAX_OUT_RATIO     = (BONE / 3) + 1 wei;

    function btoi(uint a)
        internal pure
        returns (uint)
    {
        return a / BONE;
    }

    function bfloor(uint a)
        internal pure
        returns (uint)
    {
        return btoi(a) * BONE;
    }

    function badd(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint a, uint b)
        internal pure
        returns (uint)
    {
        (uint c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint a, uint b)
        internal pure
        returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        require(b != 0, "ERR_DIV_ZERO");
        uint c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint a, uint n)
        internal pure
        returns (uint)
    {
        uint z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `bpowi` for `b^e` and `bpowK` for k iterations
    // of approximation of b^0.w
    function bpow(uint base, uint exp)
        internal pure
        returns (uint)
    {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint whole  = bfloor(exp);
        uint remain = bsub(exp, whole);

        uint wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(uint base, uint exp, uint precision)
        internal pure
        returns (uint)
    {
        // term 0:
        uint a     = exp;
        (uint x, bool xneg)  = bsubSign(base, BONE);
        uint term = BONE;
        uint sum   = term;
        bool negative = false;


        // term(k) = numer / denom
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * BONE;
            (uint c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }

    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                ( bI / wI )         1                                  //
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcSpotPrice(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint swapFee
    )
        internal pure
        returns (uint spotPrice)
    {
        uint numer = bdiv(tokenBalanceIn, tokenWeightIn);
        uint denom = bdiv(tokenBalanceOut, tokenWeightOut);
        uint ratio = bdiv(numer, denom);
        uint scale = bdiv(BONE, bsub(BONE, swapFee));
        return  (spotPrice = bmul(ratio, scale));
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcOutGivenIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountIn,
        uint swapFee
    )
        internal pure
        returns (uint tokenAmountOut)
    {
        uint weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
        uint adjustedIn = bsub(BONE, swapFee);
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
        uint y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
        if (y == 0) {
            return 0;
        }
        uint foo = bpow(y, weightRatio);
        uint bar = bsub(BONE, foo);
        tokenAmountOut = bmul(tokenBalanceOut, bar);
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcInGivenOut                                                                            //
    // aI = tokenAmountIn                                                                        //
    // bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \                 //
    // bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |                //
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /                 //
    // wI = tokenWeightIn           --------------------------------------------                 //
    // wO = tokenWeightOut                          ( 1 - sF )                                   //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcInGivenOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountOut,
        uint swapFee
    )
        internal pure
        returns (uint tokenAmountIn)
    {
        uint weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
        uint diff = bsub(tokenBalanceOut, tokenAmountOut);
        uint y = bdiv(tokenBalanceOut, diff);
        if (y == 0) {
            return 0;
        }
        uint foo = bpow(y, weightRatio);
        foo = bsub(foo, BONE);
        tokenAmountIn = bsub(BONE, swapFee);
        tokenAmountIn = bdiv(bmul(tokenBalanceIn, foo), tokenAmountIn);
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcPoolOutGivenSingleIn                                                                  //
    // pAo = poolAmountOut         /                                              \              //
    // tAi = tokenAmountIn        ///      /     //    wI \      \\       \     wI \             //
    // wI = tokenWeightIn        //| tAi *| 1 - || 1 - --  | * sF || + tBi \    --  \            //
    // tW = totalWeight     pAo=||  \      \     \\    tW /      //         | ^ tW   | * pS - pS //
    // tBi = tokenBalanceIn      \\  ------------------------------------- /        /            //
    // pS = poolSupply            \\                    tBi               /        /             //
    // sF = swapFee                \                                              /              //
    **********************************************************************************************/
    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        internal pure
        returns (uint poolAmountOut)
    {
        // Charge the trading fee for the proportion of tokenAi
        ///  which is implicitly traded to the other pool tokens.
        // That proportion is (1- weightTokenIn)
        // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);
        uint normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
        uint tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BONE, zaz));

        uint newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
        uint tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);

        // uint newPoolSupply = (ratioTi ^ weightTi) * poolSupply;
        uint poolRatio = bpow(tokenInRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        poolAmountOut = bsub(newPoolSupply, poolSupply);
        return poolAmountOut;
    }

    /**********************************************************************************************
    // calcSingleInGivenPoolOut                                                                  //
    // tAi = tokenAmountIn              //(pS + pAo)\     /    1    \\                           //
    // pS = poolSupply                 || ---------  | ^ | --------- || * bI - bI                //
    // pAo = poolAmountOut              \\    pS    /     \(wI / tW)//                           //
    // bI = balanceIn          tAi =  --------------------------------------------               //
    // wI = weightIn                              /      wI  \                                   //
    // tW = totalWeight                          |  1 - ----  |  * sF                            //
    // sF = swapFee                               \      tW  /                                   //
    **********************************************************************************************/
    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    )
        internal pure
        returns (uint tokenAmountIn)
    {
        uint normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint newPoolSupply = badd(poolSupply, poolAmountOut);
        uint poolRatio = bdiv(newPoolSupply, poolSupply);

        //uint newBalTi = poolRatio^(1/weightTi) * balTi;
        uint boo = bdiv(BONE, normalizedWeight);
        uint tokenInRatio = bpow(poolRatio, boo);
        uint newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
        uint tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
        // Do reverse order of fees charged in joinswap_ExternAmountIn, this way
        //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
        //uint tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
        uint zar = bmul(bsub(BONE, normalizedWeight), swapFee);
        tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BONE, zar));
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcSingleOutGivenPoolIn                                                                  //
    // tAo = tokenAmountOut            /      /                                             \\   //
    // bO = tokenBalanceOut           /      // pS - (pAi * (1 - eF)) \     /    1    \      \\  //
    // pAi = poolAmountIn            | bO - || ----------------------- | ^ | --------- | * b0 || //
    // ps = poolSupply                \      \\          pS           /     \(wO / tW)/      //  //
    // wI = tokenWeightIn      tAo =   \      \                                             //   //
    // tW = totalWeight                    /     /      wO \       \                             //
    // sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |                            //
    // eF = exitFee                        \     \      tW /       /                             //
    **********************************************************************************************/
    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    )
        internal pure
        returns (uint tokenAmountOut)
    {
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        // charge exit fee on the pool token side
        // pAiAfterExitFee = pAi*(1-exitFee)
        uint poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BONE, EXIT_FEE));
        uint newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
        uint poolRatio = bdiv(newPoolSupply, poolSupply);

        // newBalTo = poolRatio^(1/weightTo) * balTo;
        uint tokenOutRatio = bpow(poolRatio, bdiv(BONE, normalizedWeight));
        uint newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

        uint tokenAmountOutBeforeSwapFee = bsub(tokenBalanceOut, newTokenBalanceOut);

        // charge swap fee on the output token side
        //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
        uint zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
        tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BONE, zaz));
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcPoolInGivenSingleOut                                                                  //
    // pAi = poolAmountIn               // /               tAo             \\     / wO \     \   //
    // bO = tokenBalanceOut            // | bO - -------------------------- |\   | ---- |     \  //
    // tAo = tokenAmountOut      pS - ||   \     1 - ((1 - (tO / tW)) * sF)/  | ^ \ tW /  * pS | //
    // ps = poolSupply                 \\ -----------------------------------/                /  //
    // wO = tokenWeightOut  pAi =       \\               bO                 /                /   //
    // tW = totalWeight           -------------------------------------------------------------  //
    // sF = swapFee                                        ( 1 - eF )                            //
    // eF = exitFee                                                                              //
    **********************************************************************************************/
    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    )
        internal pure
        returns (uint poolAmountIn)
    {

        // charge swap fee on the output token side
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        //uint tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
        uint zoo = bsub(BONE, normalizedWeight);
        uint zar = bmul(zoo, swapFee);
        uint tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BONE, zar));

        uint newTokenBalanceOut = bsub(tokenBalanceOut, tokenAmountOutBeforeSwapFee);
        uint tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);

        //uint newPoolSupply = (ratioTo ^ weightTo) * poolSupply;
        uint poolRatio = bpow(tokenOutRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        uint poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);

        // charge exit fee on the pool token side
        // pAi = pAiAfterExitFee/(1-exitFee)
        poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BONE, EXIT_FEE));
        return poolAmountIn;
    }
}

// File: contracts/OneSplitBase.sol

pragma solidity ^0.5.0;































contract IOneSplitView is IOneSplitConsts {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );
}


library DisableFlags {
    function check(uint256 flags, uint256 flag) internal pure returns(bool) {
        return (flags & flag) != 0;
    }
}


contract OneSplitRoot is IOneSplitView {
    using SafeMath for uint256;
    using DisableFlags for uint256;

    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;
    using UniswapV2ExchangeLib for IUniswapV2Exchange;
    using ChaiHelper for IChai;

    uint256 constant internal DEXES_COUNT = 34;
    IERC20 constant internal ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 constant internal ZERO_ADDRESS = IERC20(0);

    IBancorEtherToken constant internal bancorEtherToken = IBancorEtherToken(0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315);
    IWETH constant internal weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IChai constant internal chai = IChai(0x06AF07097C9Eeb7fD685c692751D5C66dB49c215);
    IERC20 constant internal dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant internal usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant internal usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 constant internal tusd = IERC20(0x0000000000085d4780B73119b644AE5ecd22b376);
    IERC20 constant internal busd = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    IERC20 constant internal susd = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    IERC20 constant internal pax = IERC20(0x8E870D67F660D95d5be530380D0eC0bd388289E1);
    IERC20 constant internal renbtc = IERC20(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
    IERC20 constant internal wbtc = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 constant internal tbtc = IERC20(0x1bBE271d15Bb64dF0bc6CD28Df9Ff322F2eBD847);
    IERC20 constant internal hbtc = IERC20(0x0316EB71485b0Ab14103307bf65a021042c6d380);
    IERC20 constant internal sbtc = IERC20(0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6);

    IKyberNetworkProxy constant internal kyberNetworkProxy = IKyberNetworkProxy(0x9AAb3f75489902f3a48495025729a0AF77d4b11e);
    IKyberStorage constant internal kyberStorage = IKyberStorage(0xC8fb12402cB16970F3C5F4b48Ff68Eb9D1289301);
    IKyberHintHandler constant internal kyberHintHandler = IKyberHintHandler(0xa1C0Fa73c39CFBcC11ec9Eb1Afc665aba9996E2C);
    IUniswapFactory constant internal uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    IBancorContractRegistry constant internal bancorContractRegistry = IBancorContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
    IBancorNetworkPathFinder constant internal bancorNetworkPathFinder = IBancorNetworkPathFinder(0x6F0cD8C4f6F06eAB664C7E3031909452b4B72861);
    //IBancorConverterRegistry constant internal bancorConverterRegistry = IBancorConverterRegistry(0xf6E2D7F616B67E46D708e4410746E9AAb3a4C518);
    IBancorFinder constant internal bancorFinder = IBancorFinder(0x2B344e14dc2641D11D338C053C908c7A7D4c30B9);
    IOasisExchange constant internal oasisExchange = IOasisExchange(0x794e6e91555438aFc3ccF1c5076A74F42133d08D);
    ICurve constant internal curveCompound = ICurve(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56);
    ICurve constant internal curveUSDT = ICurve(0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C);
    ICurve constant internal curveY = ICurve(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    ICurve constant internal curveBinance = ICurve(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27);
    ICurve constant internal curveSynthetix = ICurve(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);
    ICurve constant internal curvePAX = ICurve(0x06364f10B501e868329afBc005b3492902d6C763);
    ICurve constant internal curveRenBTC = ICurve(0x93054188d876f558f4a66B2EF1d97d16eDf0895B);
    ICurve constant internal curveTBTC = ICurve(0x9726e9314eF1b96E45f40056bEd61A088897313E);
    ICurve constant internal curveSBTC = ICurve(0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714);
    IShell constant internal shell = IShell(0xA8253a440Be331dC4a7395B73948cCa6F19Dc97D);
    IAaveLendingPool constant internal aave = IAaveLendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);
    ICompound constant internal compound = ICompound(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    ICompoundEther constant internal cETH = ICompoundEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
    IMooniswapRegistry constant internal mooniswapRegistry = IMooniswapRegistry(0x71CD6666064C3A1354a3B4dca5fA1E2D3ee7D303);
    IUniswapV2Factory constant internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IDForceSwap constant internal dforceSwap = IDForceSwap(0x03eF3f37856bD08eb47E2dE7ABc4Ddd2c19B60F2);
    IMStable constant internal musd = IMStable(0xe2f2a5C287993345a840Db3B0845fbC70f5935a5);
    IMassetValidationHelper constant internal musd_helper = IMassetValidationHelper(0xaBcC93c3be238884cc3309C19Afd128fAfC16911);
    IBalancerRegistry constant internal balancerRegistry = IBalancerRegistry(0x65e67cbc342712DF67494ACEfc06fe951EE93982);
    ICurveCalculator constant internal curveCalculator = ICurveCalculator(0xc1DB00a8E5Ef7bfa476395cdbcc98235477cDE4E);
    ICurveRegistry constant internal curveRegistry = ICurveRegistry(0x7002B727Ef8F5571Cb5F9D70D13DBEEb4dFAe9d1);
    ICompoundRegistry constant internal compoundRegistry = ICompoundRegistry(0xF451Dbd7Ba14BFa7B1B78A766D3Ed438F79EE1D1);
    IAaveRegistry constant internal aaveRegistry = IAaveRegistry(0xEd8b133B7B88366E01Bb9E38305Ab11c26521494);
    IBalancerHelper constant internal balancerHelper = IBalancerHelper(0xA961672E8Db773be387e775bc4937C678F3ddF9a);

    int256 internal constant VERY_NEGATIVE_VALUE = -1e72;

    function _findBestDistribution(
        uint256 s,                // parts
        int256[][] memory amounts // exchangesReturns
    )
        internal
        pure
        returns(
            int256 returnAmount,
            uint256[] memory distribution
        )
    {
        uint256 n = amounts.length;

        int256[][] memory answer = new int256[][](n); // int[n][s+1]
        uint256[][] memory parent = new uint256[][](n); // int[n][s+1]

        for (uint i = 0; i < n; i++) {
            answer[i] = new int256[](s + 1);
            parent[i] = new uint256[](s + 1);
        }

        for (uint j = 0; j <= s; j++) {
            answer[0][j] = amounts[0][j];
            for (uint i = 1; i < n; i++) {
                answer[i][j] = -1e72;
            }
            parent[0][j] = 0;
        }

        for (uint i = 1; i < n; i++) {
            for (uint j = 0; j <= s; j++) {
                answer[i][j] = answer[i - 1][j];
                parent[i][j] = j;

                for (uint k = 1; k <= j; k++) {
                    if (answer[i - 1][j - k] + amounts[i][k] > answer[i][j]) {
                        answer[i][j] = answer[i - 1][j - k] + amounts[i][k];
                        parent[i][j] = j - k;
                    }
                }
            }
        }

        distribution = new uint256[](DEXES_COUNT);

        uint256 partsLeft = s;
        for (uint curExchange = n - 1; partsLeft > 0; curExchange--) {
            distribution[curExchange] = partsLeft - parent[curExchange][partsLeft];
            partsLeft = parent[curExchange][partsLeft];
        }

        returnAmount = (answer[n - 1][s] == VERY_NEGATIVE_VALUE) ? 0 : answer[n - 1][s];
    }

    function _kyberReserveIdByTokens(
        IERC20 fromToken,
        IERC20 destToken
    ) internal view returns(bytes32) {
        if (!fromToken.isETH() && !destToken.isETH()) {
            return 0;
        }

        bytes32[] memory reserveIds = kyberStorage.getReserveIdsPerTokenSrc(
            fromToken.isETH() ? destToken : fromToken
        );

        for (uint i = 0; i < reserveIds.length; i++) {
            if ((uint256(reserveIds[i]) >> 248) != 0xBB && // Bridge
                reserveIds[i] != 0xff4b796265722046707200000000000000000000000000000000000000000000 && // Reserve 1
                reserveIds[i] != 0xffabcd0000000000000000000000000000000000000000000000000000000000 && // Reserve 2
                reserveIds[i] != 0xff4f6e65426974205175616e7400000000000000000000000000000000000000)   // Reserve 3
            {
                return reserveIds[i];
            }
        }

        return 0;
    }

    function _scaleDestTokenEthPriceTimesGasPrice(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 destTokenEthPriceTimesGasPrice
    ) internal view returns(uint256) {
        if (fromToken == destToken) {
            return destTokenEthPriceTimesGasPrice;
        }

        uint256 mul = _cheapGetPrice(ETH_ADDRESS, destToken, 0.01 ether);
        uint256 div = _cheapGetPrice(ETH_ADDRESS, fromToken, 0.01 ether);
        if (div > 0) {
            return destTokenEthPriceTimesGasPrice.mul(mul).div(div);
        }
        return 0;
    }

    function _cheapGetPrice(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal view returns(uint256 returnAmount) {
        (returnAmount,,) = this.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            1,
            FLAG_DISABLE_SPLIT_RECALCULATION |
            FLAG_DISABLE_ALL_SPLIT_SOURCES |
            FLAG_DISABLE_UNISWAP_V2_ALL |
            FLAG_DISABLE_UNISWAP,
            0
        );
    }

    function _linearInterpolation(
        uint256 value,
        uint256 parts
    ) internal pure returns(uint256[] memory rets) {
        rets = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            rets[i] = value.mul(i + 1).div(parts);
        }
    }

    function _tokensEqual(IERC20 tokenA, IERC20 tokenB) internal pure returns(bool) {
        return ((tokenA.isETH() && tokenB.isETH()) || tokenA == tokenB);
    }
}


contract OneSplitViewWrapBase is IOneSplitView, OneSplitRoot {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        (returnAmount, , distribution) = this.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
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
        return _getExpectedReturnRespectingGasFloor(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _getExpectedReturnRespectingGasFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        internal
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );
}


contract OneSplitView is IOneSplitView, OneSplitRoot {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
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
        distribution = new uint256[](DEXES_COUNT);

        if (fromToken == destToken) {
            return (amount, 0, distribution);
        }

        function(IERC20,IERC20,uint256,uint256,uint256) view returns(uint256[] memory, uint256)[DEXES_COUNT] memory reserves = _getAllReserves(flags);

        int256[][] memory matrix = new int256[][](DEXES_COUNT);
        uint256[DEXES_COUNT] memory gases;
        bool atLeastOnePositive = false;
        for (uint i = 0; i < DEXES_COUNT; i++) {
            uint256[] memory rets;
            (rets, gases[i]) = reserves[i](fromToken, destToken, amount, parts, flags);

            // Prepend zero and sub gas
            int256 gas = int256(gases[i].mul(destTokenEthPriceTimesGasPrice).div(1e18));
            matrix[i] = new int256[](parts + 1);
            for (uint j = 0; j < rets.length; j++) {
                matrix[i][j + 1] = int256(rets[j]) - gas;
                atLeastOnePositive = atLeastOnePositive || (matrix[i][j + 1] > 0);
            }
        }

        if (!atLeastOnePositive) {
            for (uint i = 0; i < DEXES_COUNT; i++) {
                for (uint j = 1; j < parts + 1; j++) {
                    if (matrix[i][j] == 0) {
                        matrix[i][j] = VERY_NEGATIVE_VALUE;
                    }
                }
            }
        }

        (, distribution) = _findBestDistribution(parts, matrix);

        (returnAmount, estimateGasAmount) = _getReturnAndGasByDistribution(
            Args({
                fromToken: fromToken,
                destToken: destToken,
                amount: amount,
                parts: parts,
                flags: flags,
                destTokenEthPriceTimesGasPrice: destTokenEthPriceTimesGasPrice,
                distribution: distribution,
                matrix: matrix,
                gases: gases,
                reserves: reserves
            })
        );
        return (returnAmount, estimateGasAmount, distribution);
    }

    struct Args {
        IERC20 fromToken;
        IERC20 destToken;
        uint256 amount;
        uint256 parts;
        uint256 flags;
        uint256 destTokenEthPriceTimesGasPrice;
        uint256[] distribution;
        int256[][] matrix;
        uint256[DEXES_COUNT] gases;
        function(IERC20,IERC20,uint256,uint256,uint256) view returns(uint256[] memory, uint256)[DEXES_COUNT] reserves;
    }

    function _getReturnAndGasByDistribution(
        Args memory args
    ) internal view returns(uint256 returnAmount, uint256 estimateGasAmount) {
        bool[DEXES_COUNT] memory exact = [
            true,  // "Uniswap",
            false, // "Kyber",
            false, // "Bancor",
            false, // "Oasis",
            true,  // "Curve Compound",
            true,  // "Curve USDT",
            true,  // "Curve Y",
            true,  // "Curve Binance",
            true,  // "Curve Synthetix",
            true,  // "Uniswap Compound",
            true,  // "Uniswap CHAI",
            true,  // "Uniswap Aave",
            true,  // "Mooniswap 1",
            true,  // "Uniswap V2",
            true,  // "Uniswap V2 (ETH)",
            true,  // "Uniswap V2 (DAI)",
            true,  // "Uniswap V2 (USDC)",
            true,  // "Curve Pax",
            true,  // "Curve RenBTC",
            true,  // "Curve tBTC",
            true,  // "Dforce XSwap",
            false, // "Shell",
            true,  // "mStable",
            true,  // "Curve sBTC"
            true,  // "Balancer 1"
            true,  // "Balancer 2"
            true,  // "Balancer 3"
            true,  // "Kyber 1"
            true,  // "Kyber 2"
            true,  // "Kyber 3"
            true,  // "Kyber 4"
            true,  // "Mooniswap 2"
            true,  // "Mooniswap 3"
            true   // "Mooniswap 4"
        ];

        for (uint i = 0; i < DEXES_COUNT; i++) {
            if (args.distribution[i] > 0) {
                if (args.distribution[i] == args.parts || exact[i] || args.flags.check(FLAG_DISABLE_SPLIT_RECALCULATION)) {
                    estimateGasAmount = estimateGasAmount.add(args.gases[i]);
                    int256 value = args.matrix[i][args.distribution[i]];
                    returnAmount = returnAmount.add(uint256(
                        (value == VERY_NEGATIVE_VALUE ? 0 : value) +
                        int256(args.gases[i].mul(args.destTokenEthPriceTimesGasPrice).div(1e18))
                    ));
                }
                else {
                    (uint256[] memory rets, uint256 gas) = args.reserves[i](args.fromToken, args.destToken, args.amount.mul(args.distribution[i]).div(args.parts), 1, args.flags);
                    estimateGasAmount = estimateGasAmount.add(gas);
                    returnAmount = returnAmount.add(rets[0]);
                }
            }
        }
    }

    function _getAllReserves(uint256 flags)
        internal
        pure
        returns(function(IERC20,IERC20,uint256,uint256,uint256) view returns(uint256[] memory, uint256)[DEXES_COUNT] memory)
    {
        bool invert = flags.check(FLAG_DISABLE_ALL_SPLIT_SOURCES);
        return [
            invert != flags.check(FLAG_DISABLE_UNISWAP_ALL | FLAG_DISABLE_UNISWAP)            ? _calculateNoReturn : calculateUniswap,
            _calculateNoReturn, // invert != flags.check(FLAG_DISABLE_KYBER) ? _calculateNoReturn : calculateKyber,
            invert != flags.check(FLAG_DISABLE_BANCOR)                                        ? _calculateNoReturn : calculateBancor,
            invert != flags.check(FLAG_DISABLE_OASIS)                                         ? _calculateNoReturn : calculateOasis,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_COMPOUND)       ? _calculateNoReturn : calculateCurveCompound,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_USDT)           ? _calculateNoReturn : calculateCurveUSDT,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_Y)              ? _calculateNoReturn : calculateCurveY,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_BINANCE)        ? _calculateNoReturn : calculateCurveBinance,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_SYNTHETIX)      ? _calculateNoReturn : calculateCurveSynthetix,
            invert != flags.check(FLAG_DISABLE_UNISWAP_ALL | FLAG_DISABLE_UNISWAP_COMPOUND)   ? _calculateNoReturn : calculateUniswapCompound,
            invert != flags.check(FLAG_DISABLE_UNISWAP_ALL | FLAG_DISABLE_UNISWAP_CHAI)       ? _calculateNoReturn : calculateUniswapChai,
            invert != flags.check(FLAG_DISABLE_UNISWAP_ALL | FLAG_DISABLE_UNISWAP_AAVE)       ? _calculateNoReturn : calculateUniswapAave,
            invert != flags.check(FLAG_DISABLE_MOONISWAP_ALL | FLAG_DISABLE_MOONISWAP)        ? _calculateNoReturn : calculateMooniswap,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_ALL | FLAG_DISABLE_UNISWAP_V2)      ? _calculateNoReturn : calculateUniswapV2,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_ALL | FLAG_DISABLE_UNISWAP_V2_ETH)  ? _calculateNoReturn : calculateUniswapV2ETH,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_ALL | FLAG_DISABLE_UNISWAP_V2_DAI)  ? _calculateNoReturn : calculateUniswapV2DAI,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_ALL | FLAG_DISABLE_UNISWAP_V2_USDC) ? _calculateNoReturn : calculateUniswapV2USDC,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_PAX)            ? _calculateNoReturn : calculateCurvePAX,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_RENBTC)         ? _calculateNoReturn : calculateCurveRenBTC,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_TBTC)           ? _calculateNoReturn : calculateCurveTBTC,
            invert != flags.check(FLAG_DISABLE_DFORCE_SWAP)                                   ? _calculateNoReturn : calculateDforceSwap,
            invert != flags.check(FLAG_DISABLE_SHELL)                                         ? _calculateNoReturn : calculateShell,
            invert != flags.check(FLAG_DISABLE_MSTABLE_MUSD)                                  ? _calculateNoReturn : calculateMStableMUSD,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_SBTC)           ? _calculateNoReturn : calculateCurveSBTC,
            invert != flags.check(FLAG_DISABLE_BALANCER_ALL | FLAG_DISABLE_BALANCER_1)        ? _calculateNoReturn : calculateBalancer1,
            invert != flags.check(FLAG_DISABLE_BALANCER_ALL | FLAG_DISABLE_BALANCER_2)        ? _calculateNoReturn : calculateBalancer2,
            invert != flags.check(FLAG_DISABLE_BALANCER_ALL | FLAG_DISABLE_BALANCER_3)        ? _calculateNoReturn : calculateBalancer3,
            invert != flags.check(FLAG_DISABLE_KYBER_ALL | FLAG_DISABLE_KYBER_1)              ? _calculateNoReturn : calculateKyber1,
            invert != flags.check(FLAG_DISABLE_KYBER_ALL | FLAG_DISABLE_KYBER_2)              ? _calculateNoReturn : calculateKyber2,
            invert != flags.check(FLAG_DISABLE_KYBER_ALL | FLAG_DISABLE_KYBER_3)              ? _calculateNoReturn : calculateKyber3,
            invert != flags.check(FLAG_DISABLE_KYBER_ALL | FLAG_DISABLE_KYBER_4)              ? _calculateNoReturn : calculateKyber4,
            invert != flags.check(FLAG_DISABLE_MOONISWAP_ALL | FLAG_DISABLE_MOONISWAP_ETH)    ? _calculateNoReturn : calculateMooniswapOverETH,
            invert != flags.check(FLAG_DISABLE_MOONISWAP_ALL | FLAG_DISABLE_MOONISWAP_DAI)    ? _calculateNoReturn : calculateMooniswapOverDAI,
            invert != flags.check(FLAG_DISABLE_MOONISWAP_ALL | FLAG_DISABLE_MOONISWAP_USDC)   ? _calculateNoReturn : calculateMooniswapOverUSDC
        ];
    }

    function _calculateNoGas(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 /*parts*/,
        uint256 /*destTokenEthPriceTimesGasPrice*/,
        uint256 /*flags*/,
        uint256 /*destTokenEthPrice*/
    ) internal view returns(uint256[] memory /*rets*/, uint256 /*gas*/) {
        this;
    }

    // View Helpers

    struct Balances {
        uint256 src;
        uint256 dst;
    }

    function _calculateBalancer(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 poolIndex
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        address[] memory pools = balancerRegistry.getBestPoolsWithLimit(
            address(fromToken.isETH() ? weth : fromToken),
            address(destToken.isETH() ? weth : destToken),
            poolIndex + 1
        );
        if (poolIndex >= pools.length) {
            return (new uint256[](parts), 0);
        }

        rets = balancerHelper.getReturns(
            IBalancerPool(pools[poolIndex]),
            fromToken.isETH() ? weth : fromToken,
            destToken.isETH() ? weth : destToken,
            _linearInterpolation(amount, parts)
        );
        gas = 75_000 + (fromToken.isETH() || destToken.isETH() ? 0 : 65_000);
    }

    function calculateBalancer1(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateBalancer(
            fromToken,
            destToken,
            amount,
            parts,
            0
        );
    }

    function calculateBalancer2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateBalancer(
            fromToken,
            destToken,
            amount,
            parts,
            1
        );
    }

    function calculateBalancer3(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateBalancer(
            fromToken,
            destToken,
            amount,
            parts,
            2
        );
    }

    function calculateMStableMUSD(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = new uint256[](parts);

        if ((fromToken != usdc && fromToken != dai && fromToken != usdt && fromToken != tusd) ||
            (destToken != usdc && destToken != dai && destToken != usdt && destToken != tusd))
        {
            return (rets, 0);
        }

        for (uint i = 1; i <= parts; i *= 2) {
            (bool success, bytes memory data) = address(musd).staticcall(abi.encodeWithSelector(
                musd.getSwapOutput.selector,
                fromToken,
                destToken,
                amount.mul(parts.div(i)).div(parts)
            ));

            if (success && data.length > 0) {
                (,, uint256 maxRet) = abi.decode(data, (bool,string,uint256));
                if (maxRet > 0) {
                    for (uint j = 0; j < parts.div(i); j++) {
                        rets[j] = maxRet.mul(j + 1).div(parts.div(i));
                    }
                    break;
                }
            }
        }

        return (
            rets,
            700_000
        );
    }

    function _getCurvePoolInfo(
        ICurve curve,
        bool haveUnderlying
    ) internal view returns(
        uint256[8] memory balances,
        uint256[8] memory precisions,
        uint256[8] memory rates,
        uint256 amp,
        uint256 fee
    ) {
        uint256[8] memory underlying_balances;
        uint256[8] memory decimals;
        uint256[8] memory underlying_decimals;

        (
            balances,
            underlying_balances,
            decimals,
            underlying_decimals,
            /*address lp_token*/,
            amp,
            fee
        ) = curveRegistry.get_pool_info(address(curve));

        for (uint k = 0; k < 8 && balances[k] > 0; k++) {
            precisions[k] = 10 ** (18 - (haveUnderlying ? underlying_decimals : decimals)[k]);
            if (haveUnderlying) {
                rates[k] = underlying_balances[k].mul(1e18).div(balances[k]);
            } else {
                rates[k] = 1e18;
            }
        }
    }

    function _calculateCurveSelector(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        ICurve curve,
        bool haveUnderlying,
        IERC20[] memory tokens
    ) internal view returns(uint256[] memory rets) {
        rets = new uint256[](parts);

        int128 i = 0;
        int128 j = 0;
        for (uint t = 0; t < tokens.length; t++) {
            if (fromToken == tokens[t]) {
                i = int128(t + 1);
            }
            if (destToken == tokens[t]) {
                j = int128(t + 1);
            }
        }

        if (i == 0 || j == 0) {
            return rets;
        }

        bytes memory data = abi.encodePacked(
            uint256(haveUnderlying ? 1 : 0),
            uint256(i - 1),
            uint256(j - 1),
            _linearInterpolation100(amount, parts)
        );

        (
            uint256[8] memory balances,
            uint256[8] memory precisions,
            uint256[8] memory rates,
            uint256 amp,
            uint256 fee
        ) = _getCurvePoolInfo(curve, haveUnderlying);

        bool success;
        (success, data) = address(curveCalculator).staticcall(
            abi.encodePacked(
                abi.encodeWithSelector(
                    curveCalculator.get_dy.selector,
                    tokens.length,
                    balances,
                    amp,
                    fee,
                    rates,
                    precisions
                ),
                data
            )
        );

        if (!success || data.length == 0) {
            return rets;
        }

        uint256[100] memory dy = abi.decode(data, (uint256[100]));
        for (uint t = 0; t < parts; t++) {
            rets[t] = dy[t];
        }
    }

    function _linearInterpolation100(
        uint256 value,
        uint256 parts
    ) internal pure returns(uint256[100] memory rets) {
        for (uint i = 0; i < parts; i++) {
            rets[i] = value.mul(i + 1).div(parts);
        }
    }

    function calculateCurveCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = dai;
        tokens[1] = usdc;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveCompound,
            true,
            tokens
        ), 720_000);
    }

    function calculateCurveUSDT(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveUSDT,
            true,
            tokens
        ), 720_000);
    }

    function calculateCurveY(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = tusd;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveY,
            true,
            tokens
        ), 1_400_000);
    }

    function calculateCurveBinance(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = busd;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveBinance,
            true,
            tokens
        ), 1_400_000);
    }

    function calculateCurveSynthetix(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = susd;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveSynthetix,
            true,
            tokens
        ), 200_000);
    }

    function calculateCurvePAX(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = pax;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curvePAX,
            true,
            tokens
        ), 1_000_000);
    }

    function calculateCurveRenBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = renbtc;
        tokens[1] = wbtc;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveRenBTC,
            false,
            tokens
        ), 130_000);
    }

    function calculateCurveTBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = tbtc;
        tokens[1] = wbtc;
        tokens[2] = hbtc;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveTBTC,
            false,
            tokens
        ), 145_000);
    }

    function calculateCurveSBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = renbtc;
        tokens[1] = wbtc;
        tokens[2] = sbtc;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveSBTC,
            false,
            tokens
        ), 150_000);
    }

    function calculateShell(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        (bool success, bytes memory data) = address(shell).staticcall(abi.encodeWithSelector(
            shell.viewOriginTrade.selector,
            fromToken,
            destToken,
            amount
        ));

        if (!success || data.length == 0) {
            return (new uint256[](parts), 0);
        }

        uint256 maxRet = abi.decode(data, (uint256));
        return (_linearInterpolation(maxRet, parts), 300_000);
    }

    function calculateDforceSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        (bool success, bytes memory data) = address(dforceSwap).staticcall(
            abi.encodeWithSelector(
                dforceSwap.getAmountByInput.selector,
                fromToken,
                destToken,
                amount
            )
        );
        if (!success || data.length == 0) {
            return (new uint256[](parts), 0);
        }

        uint256 maxRet = abi.decode(data, (uint256));
        uint256 available = destToken.universalBalanceOf(address(dforceSwap));
        if (maxRet > available) {
            return (new uint256[](parts), 0);
        }

        return (_linearInterpolation(maxRet, parts), 160_000);
    }

    function _calculateUniswapFormula(uint256 fromBalance, uint256 toBalance, uint256 amount) internal pure returns(uint256) {
        if (amount == 0) {
            return 0;
        }
        return amount.mul(toBalance).mul(997).div(
            fromBalance.mul(1000).add(amount.mul(997))
        );
    }

    function _calculateUniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = amounts;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(fromToken);
            if (fromExchange == IUniswapExchange(0)) {
                return (new uint256[](rets.length), 0);
            }

            uint256 fromTokenBalance = fromToken.universalBalanceOf(address(fromExchange));
            uint256 fromEtherBalance = address(fromExchange).balance;

            for (uint i = 0; i < rets.length; i++) {
                rets[i] = _calculateUniswapFormula(fromTokenBalance, fromEtherBalance, rets[i]);
            }
        }

        if (!destToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(destToken);
            if (toExchange == IUniswapExchange(0)) {
                return (new uint256[](rets.length), 0);
            }

            uint256 toEtherBalance = address(toExchange).balance;
            uint256 toTokenBalance = destToken.universalBalanceOf(address(toExchange));

            for (uint i = 0; i < rets.length; i++) {
                rets[i] = _calculateUniswapFormula(toEtherBalance, toTokenBalance, rets[i]);
            }
        }

        return (rets, fromToken.isETH() || destToken.isETH() ? 60_000 : 100_000);
    }

    function calculateUniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateUniswap(
            fromToken,
            destToken,
            _linearInterpolation(amount, parts),
            flags
        );
    }

    function _calculateUniswapWrapped(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 midTokenPrice,
        uint256 flags,
        uint256 gas1,
        uint256 gas2
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (!fromToken.isETH() && destToken.isETH()) {
            (rets, gas) = _calculateUniswap(
                midToken,
                destToken,
                _linearInterpolation(amount.mul(1e18).div(midTokenPrice), parts),
                flags
            );
            return (rets, gas + gas1);
        }
        else if (fromToken.isETH() && !destToken.isETH()) {
            (rets, gas) = _calculateUniswap(
                fromToken,
                midToken,
                _linearInterpolation(amount, parts),
                flags
            );

            for (uint i = 0; i < parts; i++) {
                rets[i] = rets[i].mul(midTokenPrice).div(1e18);
            }
            return (rets, gas + gas2);
        }

        return (new uint256[](parts), 0);
    }

    function calculateUniswapCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20 midPreToken;
        if (!fromToken.isETH() && destToken.isETH()) {
            midPreToken = fromToken;
        }
        else if (!destToken.isETH() && fromToken.isETH()) {
            midPreToken = destToken;
        }

        if (!midPreToken.isETH()) {
            ICompoundToken midToken = compoundRegistry.cTokenByToken(midPreToken);
            if (midToken != ICompoundToken(0)) {
                return _calculateUniswapWrapped(
                    fromToken,
                    midToken,
                    destToken,
                    amount,
                    parts,
                    midToken.exchangeRateStored(),
                    flags,
                    200_000,
                    200_000
                );
            }
        }

        return (new uint256[](parts), 0);
    }

    function calculateUniswapChai(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == dai && destToken.isETH() ||
            fromToken.isETH() && destToken == dai)
        {
            return _calculateUniswapWrapped(
                fromToken,
                chai,
                destToken,
                amount,
                parts,
                chai.chaiPrice(),
                flags,
                180_000,
                160_000
            );
        }

        return (new uint256[](parts), 0);
    }

    function calculateUniswapAave(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20 midPreToken;
        if (!fromToken.isETH() && destToken.isETH()) {
            midPreToken = fromToken;
        }
        else if (!destToken.isETH() && fromToken.isETH()) {
            midPreToken = destToken;
        }

        if (!midPreToken.isETH()) {
            IAaveToken midToken = aaveRegistry.aTokenByToken(midPreToken);
            if (midToken != IAaveToken(0)) {
                return _calculateUniswapWrapped(
                    fromToken,
                    midToken,
                    destToken,
                    amount,
                    parts,
                    1e18,
                    flags,
                    310_000,
                    670_000
                );
            }
        }

        return (new uint256[](parts), 0);
    }

    function calculateKyber1(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateKyber(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0xff4b796265722046707200000000000000000000000000000000000000000000 // 0x63825c174ab367968EC60f061753D3bbD36A0D8F
        );
    }

    function calculateKyber2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateKyber(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0xffabcd0000000000000000000000000000000000000000000000000000000000 // 0x7a3370075a54B187d7bD5DceBf0ff2B5552d4F7D
        );
    }

    function calculateKyber3(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateKyber(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0xff4f6e65426974205175616e7400000000000000000000000000000000000000 // 0x4f32BbE8dFc9efD54345Fc936f9fEF1048746fCF
        );
    }

    function calculateKyber4(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        bytes32 reserveId = _kyberReserveIdByTokens(fromToken, destToken);
        if (reserveId == 0) {
            return (new uint256[](parts), 0);
        }

        return _calculateKyber(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            reserveId
        );
    }

    function _kyberGetRate(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags,
        bytes memory hint
    ) private view returns(uint256) {
        (, bytes memory data) = address(kyberNetworkProxy).staticcall(
            abi.encodeWithSelector(
                kyberNetworkProxy.getExpectedRateAfterFee.selector,
                fromToken,
                destToken,
                amount,
                (flags >> 255) * 10,
                hint
            )
        );

        return (data.length == 32) ? abi.decode(data, (uint256)) : 0;
    }

    function _calculateKyber(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        bytes32 reserveId
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        bytes memory fromHint;
        bytes memory destHint;
        {
            bytes32[] memory reserveIds = new bytes32[](1);
            reserveIds[0] = reserveId;

            (bool success, bytes memory data) = address(kyberHintHandler).staticcall(
                abi.encodeWithSelector(
                    kyberHintHandler.buildTokenToEthHint.selector,
                    fromToken,
                    IKyberHintHandler.TradeType.MaskIn,
                    reserveIds,
                    new uint256[](0)
                )
            );
            fromHint = success ? abi.decode(data, (bytes)) : bytes("");

            (success, data) = address(kyberHintHandler).staticcall(
                abi.encodeWithSelector(
                    kyberHintHandler.buildEthToTokenHint.selector,
                    destToken,
                    IKyberHintHandler.TradeType.MaskIn,
                    reserveIds,
                    new uint256[](0)
                )
            );
            destHint = success ? abi.decode(data, (bytes)) : bytes("");
        }

        uint256 fromTokenDecimals = 10 ** IERC20(fromToken).universalDecimals();
        uint256 destTokenDecimals = 10 ** IERC20(destToken).universalDecimals();
        rets = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            if (i > 0 && rets[i - 1] == 0) {
                break;
            }
            rets[i] = amount.mul(i + 1).div(parts);

            if (!fromToken.isETH()) {
                if (fromHint.length == 0) {
                    rets[i] = 0;
                    break;
                }
                uint256 rate = _kyberGetRate(
                    fromToken,
                    ETH_ADDRESS,
                    rets[i],
                    flags,
                    fromHint
                );
                rets[i] = rate.mul(rets[i]).div(fromTokenDecimals);
            }

            if (!destToken.isETH() && rets[i] > 0) {
                if (destHint.length == 0) {
                    rets[i] = 0;
                    break;
                }
                uint256 rate = _kyberGetRate(
                    ETH_ADDRESS,
                    destToken,
                    rets[i],
                    10,
                    destHint
                );
                rets[i] = rate.mul(rets[i]).mul(destTokenDecimals).div(1e36);
            }
        }

        return (rets, 100_000);
    }

    function calculateBancor(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return (new uint256[](parts), 0);
        // IBancorNetwork bancorNetwork = IBancorNetwork(bancorContractRegistry.addressOf("BancorNetwork"));

        // address[] memory path = bancorFinder.buildBancorPath(
        //     fromToken.isETH() ? bancorEtherToken : fromToken,
        //     destToken.isETH() ? bancorEtherToken : destToken
        // );

        // rets = _linearInterpolation(amount, parts);
        // for (uint i = 0; i < parts; i++) {
        //     (bool success, bytes memory data) = address(bancorNetwork).staticcall.gas(500000)(
        //         abi.encodeWithSelector(
        //             bancorNetwork.getReturnByPath.selector,
        //             path,
        //             rets[i]
        //         )
        //     );
        //     if (!success || data.length == 0) {
        //         for (; i < parts; i++) {
        //             rets[i] = 0;
        //         }
        //         break;
        //     } else {
        //         (uint256 ret,) = abi.decode(data, (uint256,uint256));
        //         rets[i] = ret;
        //     }
        // }

        // return (rets, path.length.mul(150_000));
    }

    function calculateOasis(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = _linearInterpolation(amount, parts);
        for (uint i = 0; i < parts; i++) {
            (bool success, bytes memory data) = address(oasisExchange).staticcall.gas(500000)(
                abi.encodeWithSelector(
                    oasisExchange.getBuyAmount.selector,
                    destToken.isETH() ? weth : destToken,
                    fromToken.isETH() ? weth : fromToken,
                    rets[i]
                )
            );

            if (!success || data.length == 0) {
                for (; i < parts; i++) {
                    rets[i] = 0;
                }
                break;
            } else {
                rets[i] = abi.decode(data, (uint256));
            }
        }

        return (rets, 500_000);
    }

    function calculateMooniswapMany(
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = new uint256[](amounts.length);

        IMooniswap mooniswap = mooniswapRegistry.pools(
            fromToken.isETH() ? ZERO_ADDRESS : fromToken,
            destToken.isETH() ? ZERO_ADDRESS : destToken
        );
        if (mooniswap == IMooniswap(0)) {
            return (rets, 0);
        }

        uint256 fee = mooniswap.fee();
        uint256 fromBalance = mooniswap.getBalanceForAddition(fromToken.isETH() ? ZERO_ADDRESS : fromToken);
        uint256 destBalance = mooniswap.getBalanceForRemoval(destToken.isETH() ? ZERO_ADDRESS : destToken);
        if (fromBalance == 0 || destBalance == 0) {
            return (rets, 0);
        }

        for (uint i = 0; i < amounts.length; i++) {
            uint256 amount = amounts[i].sub(amounts[i].mul(fee).div(1e18));
            rets[i] = amount.mul(destBalance).div(
                fromBalance.add(amount)
            );
        }

        return (rets, (fromToken.isETH() || destToken.isETH()) ? 80_000 : 110_000);
    }

    function calculateMooniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return calculateMooniswapMany(
            fromToken,
            destToken,
            _linearInterpolation(amount, parts)
        );
    }

    function calculateMooniswapOverETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken.isETH() || destToken.isETH()) {
            return (new uint256[](parts), 0);
        }

        (uint256[] memory results, uint256 gas1) = calculateMooniswap(fromToken, ZERO_ADDRESS, amount, parts, flags);
        (rets, gas) = calculateMooniswapMany(ZERO_ADDRESS, destToken, results);
        gas = gas.add(gas1);
    }

    function calculateMooniswapOverDAI(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == dai || destToken == dai) {
            return (new uint256[](parts), 0);
        }

        (uint256[] memory results, uint256 gas1) = calculateMooniswap(fromToken, dai, amount, parts, flags);
        (rets, gas) = calculateMooniswapMany(dai, destToken, results);
        gas = gas.add(gas1);
    }

    function calculateMooniswapOverUSDC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == usdc || destToken == usdc) {
            return (new uint256[](parts), 0);
        }

        (uint256[] memory results, uint256 gas1) = calculateMooniswap(fromToken, usdc, amount, parts, flags);
        (rets, gas) = calculateMooniswapMany(usdc, destToken, results);
        gas = gas.add(gas1);
    }

    function calculateUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateUniswapV2(
            fromToken,
            destToken,
            _linearInterpolation(amount, parts),
            flags
        );
    }

    function calculateUniswapV2ETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken.isETH() || fromToken == weth || destToken.isETH() || destToken == weth) {
            return (new uint256[](parts), 0);
        }

        return _calculateUniswapV2OverMidToken(
            fromToken,
            weth,
            destToken,
            amount,
            parts,
            flags
        );
    }

    function calculateUniswapV2DAI(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == dai || destToken == dai) {
            return (new uint256[](parts), 0);
        }

        return _calculateUniswapV2OverMidToken(
            fromToken,
            dai,
            destToken,
            amount,
            parts,
            flags
        );
    }

    function calculateUniswapV2USDC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == usdc || destToken == usdc) {
            return (new uint256[](parts), 0);
        }

        return _calculateUniswapV2OverMidToken(
            fromToken,
            usdc,
            destToken,
            amount,
            parts,
            flags
        );
    }

    function _calculateUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = new uint256[](amounts.length);

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 destTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, destTokenReal);
        if (exchange != IUniswapV2Exchange(0)) {
            uint256 fromTokenBalance = fromTokenReal.universalBalanceOf(address(exchange));
            uint256 destTokenBalance = destTokenReal.universalBalanceOf(address(exchange));
            for (uint i = 0; i < amounts.length; i++) {
                rets[i] = _calculateUniswapFormula(fromTokenBalance, destTokenBalance, amounts[i]);
            }
            return (rets, 50_000);
        }
    }

    function _calculateUniswapV2OverMidToken(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = _linearInterpolation(amount, parts);

        uint256 gas1;
        uint256 gas2;
        (rets, gas1) = _calculateUniswapV2(fromToken, midToken, rets, flags);
        (rets, gas2) = _calculateUniswapV2(midToken, destToken, rets, flags);
        return (rets, gas1 + gas2);
    }

    function _calculateNoReturn(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        this;
        return (new uint256[](parts), 0);
    }
}


contract OneSplitBaseWrap is IOneSplit, OneSplitRoot {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags // See constants in IOneSplit.sol
    ) internal {
        if (fromToken == destToken) {
            return;
        }

        _swapFloor(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _swapFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 /*flags*/ // See constants in IOneSplit.sol
    ) internal;
}


contract OneSplit is IOneSplit, OneSplitRoot {
    IOneSplitView public oneSplitView;

    constructor(IOneSplitView _oneSplitView) public {
        oneSplitView = _oneSplitView;
    }

    function() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
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

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
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
        return oneSplitView.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags  // See constants in IOneSplit.sol
    ) public payable returns(uint256 returnAmount) {
        if (fromToken == destToken) {
            return amount;
        }

        function(IERC20,IERC20,uint256,uint256)[DEXES_COUNT] memory reserves = [
            _swapOnUniswap,
            _swapOnNowhere,
            _swapOnBancor,
            _swapOnOasis,
            _swapOnCurveCompound,
            _swapOnCurveUSDT,
            _swapOnCurveY,
            _swapOnCurveBinance,
            _swapOnCurveSynthetix,
            _swapOnUniswapCompound,
            _swapOnUniswapChai,
            _swapOnUniswapAave,
            _swapOnMooniswap,
            _swapOnUniswapV2,
            _swapOnUniswapV2ETH,
            _swapOnUniswapV2DAI,
            _swapOnUniswapV2USDC,
            _swapOnCurvePAX,
            _swapOnCurveRenBTC,
            _swapOnCurveTBTC,
            _swapOnDforceSwap,
            _swapOnShell,
            _swapOnMStableMUSD,
            _swapOnCurveSBTC,
            _swapOnBalancer1,
            _swapOnBalancer2,
            _swapOnBalancer3,
            _swapOnKyber1,
            _swapOnKyber2,
            _swapOnKyber3,
            _swapOnKyber4,
            _swapOnMooniswapETH,
            _swapOnMooniswapDAI,
            _swapOnMooniswapUSDC
        ];

        require(distribution.length <= reserves.length, "OneSplit: Distribution array should not exceed reserves array size");

        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] > 0) {
                parts = parts.add(distribution[i]);
                lastNonZeroIndex = i;
            }
        }

        if (parts == 0) {
            if (fromToken.isETH()) {
                msg.sender.transfer(msg.value);
                return msg.value;
            }
            return amount;
        }

        fromToken.universalTransferFrom(msg.sender, address(this), amount);
        uint256 remainingAmount = fromToken.universalBalanceOf(address(this));

        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] == 0) {
                continue;
            }

            uint256 swapAmount = amount.mul(distribution[i]).div(parts);
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            reserves[i](fromToken, destToken, swapAmount, flags);
        }

        returnAmount = destToken.universalBalanceOf(address(this));
        require(returnAmount >= minReturn, "OneSplit: Return amount was not enough");
        destToken.universalTransfer(msg.sender, returnAmount);
        fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
    }

    // Swap helpers

    function _swapOnCurveCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) + (fromToken == usdc ? 2 : 0);
        int128 j = (destToken == dai ? 1 : 0) + (destToken == usdc ? 2 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveCompound), amount);
        curveCompound.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveUSDT(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveUSDT), amount);
        curveUSDT.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveY(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == tusd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == tusd ? 4 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveY), amount);
        curveY.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveBinance(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == busd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == busd ? 4 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveBinance), amount);
        curveBinance.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveSynthetix(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == susd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == susd ? 4 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveSynthetix), amount);
        curveSynthetix.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurvePAX(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == pax ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == pax ? 4 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curvePAX), amount);
        curvePAX.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnShell(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        fromToken.universalApprove(address(shell), amount);
        shell.swapByOrigin(
            address(fromToken),
            address(destToken),
            amount,
            0,
            now + 50
        );
    }

    function _swapOnMStableMUSD(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        fromToken.universalApprove(address(musd), amount);
        musd.swap(
            fromToken,
            destToken,
            amount,
            address(this)
        );
    }

    function _swapOnCurveRenBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == renbtc ? 1 : 0) +
            (fromToken == wbtc ? 2 : 0);
        int128 j = (destToken == renbtc ? 1 : 0) +
            (destToken == wbtc ? 2 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveRenBTC), amount);
        curveRenBTC.exchange(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveTBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == tbtc ? 1 : 0) +
            (fromToken == wbtc ? 2 : 0) +
            (fromToken == hbtc ? 3 : 0);
        int128 j = (destToken == tbtc ? 1 : 0) +
            (destToken == wbtc ? 2 : 0) +
            (destToken == hbtc ? 3 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveTBTC), amount);
        curveTBTC.exchange(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveSBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == renbtc ? 1 : 0) +
            (fromToken == wbtc ? 2 : 0) +
            (fromToken == sbtc ? 3 : 0);
        int128 j = (destToken == renbtc ? 1 : 0) +
            (destToken == wbtc ? 2 : 0) +
            (destToken == sbtc ? 3 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveSBTC), amount);
        curveSBTC.exchange(i - 1, j - 1, amount, 0);
    }

    function _swapOnDforceSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        fromToken.universalApprove(address(dforceSwap), amount);
        dforceSwap.swap(fromToken, destToken, amount);
    }

    function _swapOnUniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        uint256 returnAmount = amount;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(fromToken);
            if (fromExchange != IUniswapExchange(0)) {
                fromToken.universalApprove(address(fromExchange), returnAmount);
                returnAmount = fromExchange.tokenToEthSwapInput(returnAmount, 1, now);
            }
        }

        if (!destToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(destToken);
            if (toExchange != IUniswapExchange(0)) {
                returnAmount = toExchange.ethToTokenSwapInput.value(returnAmount)(1, now);
            }
        }
    }

    function _swapOnUniswapCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        if (!fromToken.isETH()) {
            ICompoundToken fromCompound = compoundRegistry.cTokenByToken(fromToken);
            fromToken.universalApprove(address(fromCompound), amount);
            fromCompound.mint(amount);
            _swapOnUniswap(IERC20(fromCompound), destToken, IERC20(fromCompound).universalBalanceOf(address(this)), flags);
            return;
        }

        if (!destToken.isETH()) {
            ICompoundToken toCompound = compoundRegistry.cTokenByToken(destToken);
            _swapOnUniswap(fromToken, IERC20(toCompound), amount, flags);
            toCompound.redeem(IERC20(toCompound).universalBalanceOf(address(this)));
            destToken.universalBalanceOf(address(this));
            return;
        }
    }

    function _swapOnUniswapChai(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        if (fromToken == dai) {
            fromToken.universalApprove(address(chai), amount);
            chai.join(address(this), amount);
            _swapOnUniswap(IERC20(chai), destToken, IERC20(chai).universalBalanceOf(address(this)), flags);
            return;
        }

        if (destToken == dai) {
            _swapOnUniswap(fromToken, IERC20(chai), amount, flags);
            chai.exit(address(this), chai.balanceOf(address(this)));
            return;
        }
    }

    function _swapOnUniswapAave(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        if (!fromToken.isETH()) {
            IAaveToken fromAave = aaveRegistry.aTokenByToken(fromToken);
            fromToken.universalApprove(aave.core(), amount);
            aave.deposit(fromToken, amount, 1101);
            _swapOnUniswap(IERC20(fromAave), destToken, IERC20(fromAave).universalBalanceOf(address(this)), flags);
            return;
        }

        if (!destToken.isETH()) {
            IAaveToken toAave = aaveRegistry.aTokenByToken(destToken);
            _swapOnUniswap(fromToken, IERC20(toAave), amount, flags);
            toAave.redeem(toAave.balanceOf(address(this)));
            return;
        }
    }

    function _swapOnMooniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        IMooniswap mooniswap = mooniswapRegistry.pools(
            fromToken.isETH() ? ZERO_ADDRESS : fromToken,
            destToken.isETH() ? ZERO_ADDRESS : destToken
        );
        fromToken.universalApprove(address(mooniswap), amount);
        mooniswap.swap.value(fromToken.isETH() ? amount : 0)(
            fromToken.isETH() ? ZERO_ADDRESS : fromToken,
            destToken.isETH() ? ZERO_ADDRESS : destToken,
            amount,
            0,
            0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5
        );
    }

    function _swapOnMooniswapETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnMooniswap(fromToken, ZERO_ADDRESS, amount, flags);
        _swapOnMooniswap(ZERO_ADDRESS, destToken, address(this).balance, flags);
    }

    function _swapOnMooniswapDAI(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnMooniswap(fromToken, dai, amount, flags);
        _swapOnMooniswap(dai, destToken, dai.balanceOf(address(this)), flags);
    }

    function _swapOnMooniswapUSDC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnMooniswap(fromToken, usdc, amount, flags);
        _swapOnMooniswap(usdc, destToken, usdc.balanceOf(address(this)), flags);
    }

    function _swapOnNowhere(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 /*flags*/
    ) internal {
        revert("This source was deprecated");
    }

    function _swapOnKyber1(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnKyber(
            fromToken,
            destToken,
            amount,
            flags,
            0xff4b796265722046707200000000000000000000000000000000000000000000
        );
    }

    function _swapOnKyber2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnKyber(
            fromToken,
            destToken,
            amount,
            flags,
            0xffabcd0000000000000000000000000000000000000000000000000000000000
        );
    }

    function _swapOnKyber3(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnKyber(
            fromToken,
            destToken,
            amount,
            flags,
            0xff4f6e65426974205175616e7400000000000000000000000000000000000000
        );
    }

    function _swapOnKyber4(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnKyber(
            fromToken,
            destToken,
            amount,
            flags,
            _kyberReserveIdByTokens(fromToken, destToken)
        );
    }

    function _swapOnKyber(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags,
        bytes32 reserveId
    ) internal {
        uint256 returnAmount = amount;

        bytes32[] memory reserveIds = new bytes32[](1);
        reserveIds[0] = reserveId;

        if (!fromToken.isETH()) {
            bytes memory fromHint = kyberHintHandler.buildTokenToEthHint(
                fromToken,
                IKyberHintHandler.TradeType.MaskIn,
                reserveIds,
                new uint256[](0)
            );

            fromToken.universalApprove(address(kyberNetworkProxy), amount);
            returnAmount = kyberNetworkProxy.tradeWithHintAndFee(
                fromToken,
                returnAmount,
                ETH_ADDRESS,
                address(this),
                uint256(-1),
                0,
                0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5,
                (flags >> 255) * 10,
                fromHint
            );
        }

        if (!destToken.isETH()) {
            bytes memory destHint = kyberHintHandler.buildEthToTokenHint(
                destToken,
                IKyberHintHandler.TradeType.MaskIn,
                reserveIds,
                new uint256[](0)
            );

            returnAmount = kyberNetworkProxy.tradeWithHintAndFee.value(returnAmount)(
                ETH_ADDRESS,
                returnAmount,
                destToken,
                address(this),
                uint256(-1),
                0,
                0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5,
                (flags >> 255) * 10,
                destHint
            );
        }
    }

    function _swapOnBancor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        IBancorNetwork bancorNetwork = IBancorNetwork(bancorContractRegistry.addressOf("BancorNetwork"));
        address[] memory path = bancorNetworkPathFinder.generatePath(
            fromToken.isETH() ? bancorEtherToken : fromToken,
            destToken.isETH() ? bancorEtherToken : destToken
        );
        fromToken.universalApprove(address(bancorNetwork), amount);
        bancorNetwork.convert.value(fromToken.isETH() ? amount : 0)(path, amount, 1);
    }

    function _swapOnOasis(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }

        IERC20 approveToken = fromToken.isETH() ? weth : fromToken;
        approveToken.universalApprove(address(oasisExchange), amount);
        oasisExchange.sellAllAmount(
            fromToken.isETH() ? weth : fromToken,
            amount,
            destToken.isETH() ? weth : destToken,
            1
        );

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnUniswapV2Internal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal returns(uint256 returnAmount) {
        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, toTokenReal);
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(fromTokenReal, toTokenReal, amount);
        if (needSync) {
            exchange.sync();
        }
        else if (needSkim) {
            exchange.skim(0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5);
        }

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint256(address(fromTokenReal)) < uint256(address(toTokenReal))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnUniswapV2OverMid(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2Internal(
            midToken,
            destToken,
            _swapOnUniswapV2Internal(
                fromToken,
                midToken,
                amount,
                flags
            ),
            flags
        );
    }

    function _swapOnUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2Internal(
            fromToken,
            destToken,
            amount,
            flags
        );
    }

    function _swapOnUniswapV2ETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2OverMid(
            fromToken,
            weth,
            destToken,
            amount,
            flags
        );
    }

    function _swapOnUniswapV2DAI(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2OverMid(
            fromToken,
            dai,
            destToken,
            amount,
            flags
        );
    }

    function _swapOnUniswapV2USDC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2OverMid(
            fromToken,
            usdc,
            destToken,
            amount,
            flags
        );
    }

    function _swapOnBalancerX(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/,
        uint256 poolIndex
    ) internal {
        address[] memory pools = balancerRegistry.getBestPoolsWithLimit(
            address(fromToken.isETH() ? weth : fromToken),
            address(destToken.isETH() ? weth : destToken),
            poolIndex + 1
        );

        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }

        (fromToken.isETH() ? weth : fromToken).universalApprove(pools[poolIndex], amount);
        IBalancerPool(pools[poolIndex]).swapExactAmountIn(
            fromToken.isETH() ? weth : fromToken,
            amount,
            destToken.isETH() ? weth : destToken,
            0,
            uint256(-1)
        );

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnBalancer1(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnBalancerX(fromToken, destToken, amount, flags, 0);
    }

    function _swapOnBalancer2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnBalancerX(fromToken, destToken, amount, flags, 1);
    }

    function _swapOnBalancer3(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnBalancerX(fromToken, destToken, amount, flags, 2);
    }
}

// File: contracts/OneSplitCompound.sol

pragma solidity ^0.5.0;




contract OneSplitCompoundView is OneSplitViewWrapBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
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
        return _compoundGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _compoundGetExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_COMPOUND)) {
            IERC20 underlying = compoundRegistry.tokenByCToken(ICompoundToken(address(fromToken)));
            if (underlying != IERC20(0)) {
                uint256 compoundRate = ICompoundToken(address(fromToken)).exchangeRateStored();
                (returnAmount, estimateGasAmount, distribution) = _compoundGetExpectedReturn(
                    underlying,
                    destToken,
                    amount.mul(compoundRate).div(1e18),
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 295_000, distribution);
            }

            underlying = compoundRegistry.tokenByCToken(ICompoundToken(address(destToken)));
            if (underlying != IERC20(0)) {
                uint256 _destTokenEthPriceTimesGasPrice = destTokenEthPriceTimesGasPrice;
                uint256 compoundRate = ICompoundToken(address(destToken)).exchangeRateStored();
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    fromToken,
                    underlying,
                    amount,
                    parts,
                    flags,
                    _destTokenEthPriceTimesGasPrice.mul(compoundRate).div(1e18)
                );
                return (returnAmount.mul(1e18).div(compoundRate), estimateGasAmount + 430_000, distribution);
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitCompound is OneSplitBaseWrap {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _compoundSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _compoundSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_COMPOUND)) {
            IERC20 underlying = compoundRegistry.tokenByCToken(ICompoundToken(address(fromToken)));
            if (underlying != IERC20(0)) {
                ICompoundToken(address(fromToken)).redeem(amount);
                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                return _compoundSwap(
                    underlying,
                    destToken,
                    underlyingAmount,
                    distribution,
                    flags
                );
            }

            underlying = compoundRegistry.tokenByCToken(ICompoundToken(address(destToken)));
            if (underlying != IERC20(0)) {
                super._swap(
                    fromToken,
                    underlying,
                    amount,
                    distribution,
                    flags
                );

                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                if (underlying.isETH()) {
                    cETH.mint.value(underlyingAmount)();
                } else {
                    underlying.universalApprove(address(destToken), underlyingAmount);
                    ICompoundToken(address(destToken)).mint(underlyingAmount);
                }
                return;
            }
        }

        return super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}

// File: contracts/interface/IFulcrum.sol

pragma solidity ^0.5.0;



contract IFulcrumToken is IERC20 {
    function tokenPrice() external view returns (uint256);

    function loanTokenAddress() external view returns (address);

    function mintWithEther(address receiver) external payable returns (uint256 mintAmount);

    function mint(address receiver, uint256 depositAmount) external returns (uint256 mintAmount);

    function burnToEther(address receiver, uint256 burnAmount)
        external
        returns (uint256 loanAmountPaid);

    function burn(address receiver, uint256 burnAmount) external returns (uint256 loanAmountPaid);
}

// File: contracts/OneSplitFulcrum.sol

pragma solidity ^0.5.0;




contract OneSplitFulcrumBase {
    using UniversalERC20 for IERC20;

    function _isFulcrumToken(IERC20 token) internal view returns(IERC20) {
        if (token.isETH()) {
            return IERC20(-1);
        }

        (bool success, bytes memory data) = address(token).staticcall.gas(5000)(abi.encodeWithSignature(
            "name()"
        ));
        if (!success) {
            return IERC20(-1);
        }

        bool foundBZX = false;
        for (uint i = 0; i + 6 < data.length; i++) {
            if (data[i + 0] == "F" &&
                data[i + 1] == "u" &&
                data[i + 2] == "l" &&
                data[i + 3] == "c" &&
                data[i + 4] == "r" &&
                data[i + 5] == "u" &&
                data[i + 6] == "m")
            {
                foundBZX = true;
                break;
            }
        }
        if (!foundBZX) {
            return IERC20(-1);
        }

        (success, data) = address(token).staticcall.gas(5000)(abi.encodeWithSelector(
            IFulcrumToken(address(token)).loanTokenAddress.selector
        ));
        if (!success) {
            return IERC20(-1);
        }

        return abi.decode(data, (IERC20));
    }
}


contract OneSplitFulcrumView is OneSplitViewWrapBase, OneSplitFulcrumBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
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
        return _fulcrumGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _fulcrumGetExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_FULCRUM)) {
            IERC20 underlying = _isFulcrumToken(fromToken);
            if (underlying != IERC20(-1)) {
                uint256 fulcrumRate = IFulcrumToken(address(fromToken)).tokenPrice();
                (returnAmount, estimateGasAmount, distribution) = _fulcrumGetExpectedReturn(
                    underlying,
                    destToken,
                    amount.mul(fulcrumRate).div(1e18),
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 381_000, distribution);
            }

            underlying = _isFulcrumToken(destToken);
            if (underlying != IERC20(-1)) {
                uint256 _destTokenEthPriceTimesGasPrice = destTokenEthPriceTimesGasPrice;
                uint256 fulcrumRate = IFulcrumToken(address(destToken)).tokenPrice();
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    fromToken,
                    underlying,
                    amount,
                    parts,
                    flags,
                    _destTokenEthPriceTimesGasPrice.mul(fulcrumRate).div(1e18)
                );
                return (returnAmount.mul(1e18).div(fulcrumRate), estimateGasAmount + 354_000, distribution);
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitFulcrum is OneSplitBaseWrap, OneSplitFulcrumBase {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _fulcrumSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _fulcrumSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_FULCRUM)) {
            IERC20 underlying = _isFulcrumToken(fromToken);
            if (underlying != IERC20(-1)) {
                if (underlying.isETH()) {
                    IFulcrumToken(address(fromToken)).burnToEther(address(this), amount);
                } else {
                    IFulcrumToken(address(fromToken)).burn(address(this), amount);
                }

                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                return super._swap(
                    underlying,
                    destToken,
                    underlyingAmount,
                    distribution,
                    flags
                );
            }

            underlying = _isFulcrumToken(destToken);
            if (underlying != IERC20(-1)) {
                super._swap(
                    fromToken,
                    underlying,
                    amount,
                    distribution,
                    flags
                );

                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                if (underlying.isETH()) {
                    IFulcrumToken(address(destToken)).mintWithEther.value(underlyingAmount)(address(this));
                } else {
                    underlying.universalApprove(address(destToken), underlyingAmount);
                    IFulcrumToken(address(destToken)).mint(address(this), underlyingAmount);
                }
                return;
            }
        }

        return super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}

// File: contracts/OneSplitChai.sol

pragma solidity ^0.5.0;




contract OneSplitChaiView is OneSplitViewWrapBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
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
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_CHAI)) {
            if (fromToken == IERC20(chai)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    dai,
                    destToken,
                    chai.chaiToDai(amount),
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 197_000, distribution);
            }

            if (destToken == IERC20(chai)) {
                uint256 price = chai.chaiPrice();
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    fromToken,
                    dai,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice.mul(1e18).div(price)
                );
                return (returnAmount.mul(price).div(1e18), estimateGasAmount + 168_000, distribution);
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitChai is OneSplitBaseWrap {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_CHAI)) {
            if (fromToken == IERC20(chai)) {
                chai.exit(address(this), amount);

                return super._swap(
                    dai,
                    destToken,
                    dai.balanceOf(address(this)),
                    distribution,
                    flags
                );
            }

            if (destToken == IERC20(chai)) {
                super._swap(
                    fromToken,
                    dai,
                    amount,
                    distribution,
                    flags
                );

                uint256 daiBalance = dai.balanceOf(address(this));
                dai.universalApprove(address(chai), daiBalance);
                chai.join(address(this), daiBalance);
                return;
            }
        }

        return super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}

// File: contracts/interface/IBdai.sol

pragma solidity ^0.5.0;



contract IBdai is IERC20 {
    function join(uint256) external;

    function exit(uint256) external;
}

// File: contracts/OneSplitBdai.sol

pragma solidity ^0.5.0;




contract OneSplitBdaiBase {
    IBdai internal constant bdai = IBdai(0x6a4FFAafa8DD400676Df8076AD6c724867b0e2e8);
    IERC20 internal constant btu = IERC20(0xb683D83a532e2Cb7DFa5275eED3698436371cc9f);
}


contract OneSplitBdaiView is OneSplitViewWrapBase, OneSplitBdaiBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
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
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_BDAI)) {
            if (fromToken == IERC20(bdai)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    dai,
                    destToken,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 227_000, distribution);
            }

            if (destToken == IERC20(bdai)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    fromToken,
                    dai,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 295_000, distribution);
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitBdai is OneSplitBaseWrap, OneSplitBdaiBase {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_BDAI)) {
            if (fromToken == IERC20(bdai)) {
                bdai.exit(amount);

                uint256 btuBalance = btu.balanceOf(address(this));
                if (btuBalance > 0) {
                    (,uint256[] memory btuDistribution) = getExpectedReturn(
                        btu,
                        destToken,
                        btuBalance,
                        1,
                        flags
                    );

                    _swap(
                        btu,
                        destToken,
                        btuBalance,
                        btuDistribution,
                        flags
                    );
                }

                return super._swap(
                    dai,
                    destToken,
                    amount,
                    distribution,
                    flags
                );
            }

            if (destToken == IERC20(bdai)) {
                super._swap(fromToken, dai, amount, distribution, flags);

                uint256 daiBalance = dai.balanceOf(address(this));
                dai.universalApprove(address(bdai), daiBalance);
                bdai.join(daiBalance);
                return;
            }
        }

        return super._swap(fromToken, destToken, amount, distribution, flags);
    }
}

// File: contracts/interface/IIearn.sol

pragma solidity ^0.5.0;



contract IIearn is IERC20 {
    function token() external view returns(IERC20);

    function calcPoolValueInToken() external view returns(uint256);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;
}

// File: contracts/OneSplitIearn.sol

pragma solidity ^0.5.0;




contract OneSplitIearnBase {
    function _yTokens() internal pure returns(IIearn[13] memory) {
        return [
            IIearn(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01),
            IIearn(0x04Aa51bbcB46541455cCF1B8bef2ebc5d3787EC9),
            IIearn(0x73a052500105205d34Daf004eAb301916DA8190f),
            IIearn(0x83f798e925BcD4017Eb265844FDDAbb448f1707D),
            IIearn(0xd6aD7a6750A7593E092a9B218d66C0A814a3436e),
            IIearn(0xF61718057901F84C4eEC4339EF8f0D86D2B45600),
            IIearn(0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE),
            IIearn(0xC2cB1040220768554cf699b0d863A3cd4324ce32),
            IIearn(0xE6354ed5bC4b393a5Aad09f21c46E101e692d447),
            IIearn(0x26EA744E5B887E5205727f55dFBE8685e3b21951),
            IIearn(0x99d1Fa417f94dcD62BfE781a1213c092a47041Bc),
            IIearn(0x9777d7E2b60bB01759D0E2f8be2095df444cb07E),
            IIearn(0x1bE5d71F2dA660BFdee8012dDc58D024448A0A59)
        ];
    }
}


contract OneSplitIearnView is OneSplitViewWrapBase, OneSplitIearnBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
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
        return _iearnGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _iearnGetExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (!flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == !flags.check(FLAG_DISABLE_IEARN)) {
            IIearn[13] memory yTokens = _yTokens();

            for (uint i = 0; i < yTokens.length; i++) {
                if (fromToken == IERC20(yTokens[i])) {
                    (returnAmount, estimateGasAmount, distribution) = _iearnGetExpectedReturn(
                        yTokens[i].token(),
                        destToken,
                        amount
                            .mul(yTokens[i].calcPoolValueInToken())
                            .div(yTokens[i].totalSupply()),
                        parts,
                        flags,
                        destTokenEthPriceTimesGasPrice
                    );
                    return (returnAmount, estimateGasAmount + 260_000, distribution);
                }
            }

            for (uint i = 0; i < yTokens.length; i++) {
                if (destToken == IERC20(yTokens[i])) {
                    uint256 _destTokenEthPriceTimesGasPrice = destTokenEthPriceTimesGasPrice;
                    IERC20 token = yTokens[i].token();
                    (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                        fromToken,
                        token,
                        amount,
                        parts,
                        flags,
                        _destTokenEthPriceTimesGasPrice
                            .mul(yTokens[i].calcPoolValueInToken())
                            .div(yTokens[i].totalSupply())
                    );

                    return(
                        returnAmount
                            .mul(yTokens[i].totalSupply())
                            .div(yTokens[i].calcPoolValueInToken()),
                        estimateGasAmount + 743_000,
                        distribution
                    );
                }
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitIearn is OneSplitBaseWrap, OneSplitIearnBase {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _iearnSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _iearnSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_IEARN)) {
            IIearn[13] memory yTokens = _yTokens();

            for (uint i = 0; i < yTokens.length; i++) {
                if (fromToken == IERC20(yTokens[i])) {
                    IERC20 underlying = yTokens[i].token();
                    yTokens[i].withdraw(amount);
                    _iearnSwap(underlying, destToken, underlying.balanceOf(address(this)), distribution, flags);
                    return;
                }
            }

            for (uint i = 0; i < yTokens.length; i++) {
                if (destToken == IERC20(yTokens[i])) {
                    IERC20 underlying = yTokens[i].token();
                    super._swap(fromToken, underlying, amount, distribution, flags);

                    uint256 underlyingBalance = underlying.balanceOf(address(this));
                    underlying.universalApprove(address(yTokens[i]), underlyingBalance);
                    yTokens[i].deposit(underlyingBalance);
                    return;
                }
            }
        }

        return super._swap(fromToken, destToken, amount, distribution, flags);
    }
}

// File: contracts/interface/IIdle.sol

pragma solidity ^0.5.0;



contract IIdle is IERC20 {
    function token()
        external view returns (IERC20);

    function tokenPrice()
        external view returns (uint256);

    function mintIdleToken(uint256 _amount, uint256[] calldata _clientProtocolAmounts)
        external returns (uint256 mintedTokens);

    function redeemIdleToken(uint256 _amount, bool _skipRebalance, uint256[] calldata _clientProtocolAmounts)
        external returns (uint256 redeemedTokens);
}

// File: contracts/OneSplitIdle.sol

pragma solidity ^0.5.0;




contract OneSplitIdleBase {
    function _idleTokens() internal pure returns(IIdle[8] memory) {
        // https://developers.idle.finance/contracts-and-codebase
        return [
            // V3
            IIdle(0x78751B12Da02728F467A44eAc40F5cbc16Bd7934),
            IIdle(0x12B98C621E8754Ae70d0fDbBC73D6208bC3e3cA6),
            IIdle(0x63D27B3DA94A9E871222CB0A32232674B02D2f2D),
            IIdle(0x1846bdfDB6A0f5c473dEc610144513bd071999fB),
            IIdle(0xcDdB1Bceb7a1979C6caa0229820707429dd3Ec6C),
            IIdle(0x42740698959761BAF1B06baa51EfBD88CB1D862B),
            // V2
            IIdle(0x10eC0D497824e342bCB0EDcE00959142aAa766dD),
            IIdle(0xeB66ACc3d011056B00ea521F8203580C2E5d3991)
        ];
    }
}


contract OneSplitIdleView is OneSplitViewWrapBase, OneSplitIdleBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
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
        return _idleGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _idleGetExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        internal
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (!flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == !flags.check(FLAG_DISABLE_IDLE)) {
            IIdle[8] memory tokens = _idleTokens();

            for (uint i = 0; i < tokens.length; i++) {
                if (fromToken == IERC20(tokens[i])) {
                    (returnAmount, estimateGasAmount, distribution) = _idleGetExpectedReturn(
                        tokens[i].token(),
                        destToken,
                        amount.mul(tokens[i].tokenPrice()).div(1e18),
                        parts,
                        flags,
                        destTokenEthPriceTimesGasPrice
                    );
                    return (returnAmount, estimateGasAmount + 2_400_000, distribution);
                }
            }

            for (uint i = 0; i < tokens.length; i++) {
                if (destToken == IERC20(tokens[i])) {
                    uint256 _destTokenEthPriceTimesGasPrice = destTokenEthPriceTimesGasPrice;
                    uint256 _price = tokens[i].tokenPrice();
                    IERC20 token = tokens[i].token();
                    (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                        fromToken,
                        token,
                        amount,
                        parts,
                        flags,
                        _destTokenEthPriceTimesGasPrice.mul(_price).div(1e18)
                    );
                    return (returnAmount.mul(1e18).div(_price), estimateGasAmount + 1_300_000, distribution);
                }
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitIdle is OneSplitBaseWrap, OneSplitIdleBase {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _idleSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _idleSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (!flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == !flags.check(FLAG_DISABLE_IDLE)) {
            IIdle[8] memory tokens = _idleTokens();

            for (uint i = 0; i < tokens.length; i++) {
                if (fromToken == IERC20(tokens[i])) {
                    IERC20 underlying = tokens[i].token();
                    uint256 minted = tokens[i].redeemIdleToken(amount, true, new uint256[](0));
                    _idleSwap(underlying, destToken, minted, distribution, flags);
                    return;
                }
            }

            for (uint i = 0; i < tokens.length; i++) {
                if (destToken == IERC20(tokens[i])) {
                    IERC20 underlying = tokens[i].token();
                    super._swap(fromToken, underlying, amount, distribution, flags);

                    uint256 underlyingBalance = underlying.balanceOf(address(this));
                    underlying.universalApprove(address(tokens[i]), underlyingBalance);
                    tokens[i].mintIdleToken(underlyingBalance, new uint256[](0));
                    return;
                }
            }
        }

        return super._swap(fromToken, destToken, amount, distribution, flags);
    }
}

// File: contracts/OneSplitAave.sol

pragma solidity ^0.5.0;




contract OneSplitAaveView is OneSplitViewWrapBase {
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
        return _aaveGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _aaveGetExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_AAVE)) {
            IERC20 underlying = aaveRegistry.tokenByAToken(IAaveToken(address(fromToken)));
            if (underlying != IERC20(0)) {
                (returnAmount, estimateGasAmount, distribution) = _aaveGetExpectedReturn(
                    underlying,
                    destToken,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 670_000, distribution);
            }

            underlying = aaveRegistry.tokenByAToken(IAaveToken(address(destToken)));
            if (underlying != IERC20(0)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    fromToken,
                    underlying,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 310_000, distribution);
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitAave is OneSplitBaseWrap {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _aaveSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _aaveSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_AAVE)) {
            IERC20 underlying = aaveRegistry.tokenByAToken(IAaveToken(address(fromToken)));
            if (underlying != IERC20(0)) {
                IAaveToken(address(fromToken)).redeem(amount);

                return _aaveSwap(
                    underlying,
                    destToken,
                    amount,
                    distribution,
                    flags
                );
            }

            underlying = aaveRegistry.tokenByAToken(IAaveToken(address(destToken)));
            if (underlying != IERC20(0)) {
                super._swap(
                    fromToken,
                    underlying,
                    amount,
                    distribution,
                    flags
                );

                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                underlying.universalApprove(aave.core(), underlyingAmount);
                aave.deposit.value(underlying.isETH() ? underlyingAmount : 0)(
                    underlying.isETH() ? ETH_ADDRESS : underlying,
                    underlyingAmount,
                    1101
                );
                return;
            }
        }

        return super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}

// File: contracts/OneSplitWeth.sol

pragma solidity ^0.5.0;




contract OneSplitWethView is OneSplitViewWrapBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
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
        return _wethGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _wethGetExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_WETH)) {
            if (fromToken == weth || fromToken == bancorEtherToken) {
                return super.getExpectedReturnWithGas(ETH_ADDRESS, destToken, amount, parts, flags, destTokenEthPriceTimesGasPrice);
            }

            if (destToken == weth || destToken == bancorEtherToken) {
                return super.getExpectedReturnWithGas(fromToken, ETH_ADDRESS, amount, parts, flags, destTokenEthPriceTimesGasPrice);
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitWeth is OneSplitBaseWrap {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _wethSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _wethSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_WETH)) {
            if (fromToken == weth) {
                weth.withdraw(weth.balanceOf(address(this)));
                super._swap(
                    ETH_ADDRESS,
                    destToken,
                    amount,
                    distribution,
                    flags
                );
                return;
            }

            if (fromToken == bancorEtherToken) {
                bancorEtherToken.withdraw(bancorEtherToken.balanceOf(address(this)));
                super._swap(
                    ETH_ADDRESS,
                    destToken,
                    amount,
                    distribution,
                    flags
                );
                return;
            }

            if (destToken == weth) {
                _wethSwap(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    distribution,
                    flags
                );
                weth.deposit.value(address(this).balance)();
                return;
            }

            if (destToken == bancorEtherToken) {
                _wethSwap(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    distribution,
                    flags
                );
                bancorEtherToken.deposit.value(address(this).balance)();
                return;
            }
        }

        return super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}

// File: contracts/OneSplitMStable.sol

pragma solidity ^0.5.0;




contract OneSplitMStableView is OneSplitViewWrapBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
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
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_MSTABLE_MUSD)) {
            if (fromToken == IERC20(musd)) {
                {
                    (bool valid1,, uint256 res1,) = musd_helper.getRedeemValidity(musd, amount, destToken);
                    if (valid1) {
                        return (res1, 300_000, new uint256[](DEXES_COUNT));
                    }
                }

                (bool valid,, address token) = musd_helper.suggestRedeemAsset(musd);
                if (valid) {
                    (,, returnAmount,) = musd_helper.getRedeemValidity(musd, amount, IERC20(token));
                    if (IERC20(token) != destToken) {
                        (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                            IERC20(token),
                            destToken,
                            returnAmount,
                            parts,
                            flags,
                            destTokenEthPriceTimesGasPrice
                        );
                    } else {
                        distribution = new uint256[](DEXES_COUNT);
                    }

                    return (returnAmount, estimateGasAmount + 300_000, distribution);
                }
            }

            if (destToken == IERC20(musd)) {
                if (fromToken == usdc || fromToken == dai || fromToken == usdt || fromToken == tusd) {
                    (,, returnAmount) = musd.getSwapOutput(fromToken, destToken, amount);
                    return (returnAmount, 300_000, new uint256[](DEXES_COUNT));
                }
                else {
                    IERC20 _destToken = destToken;
                    (bool valid,, address token) = musd_helper.suggestMintAsset(_destToken);
                    if (valid) {
                        if (IERC20(token) != fromToken) {
                            (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                                fromToken,
                                IERC20(token),
                                amount,
                                parts,
                                flags,
                                _scaleDestTokenEthPriceTimesGasPrice(
                                    _destToken,
                                    IERC20(token),
                                    destTokenEthPriceTimesGasPrice
                                )
                            );
                        } else {
                            returnAmount = amount;
                        }
                        (,, returnAmount) = musd.getSwapOutput(IERC20(token), _destToken, returnAmount);
                        return (returnAmount, estimateGasAmount + 300_000, distribution);
                    }
                }
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitMStable is OneSplitBaseWrap {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_MSTABLE_MUSD)) {
            if (fromToken == IERC20(musd)) {
                if (destToken == usdc || destToken == dai || destToken == usdt || destToken == tusd) {
                    (,,, uint256 result) = musd_helper.getRedeemValidity(fromToken, amount, destToken);
                    musd.redeem(
                        destToken,
                        result
                    );
                }
                else {
                    (,,, uint256 result) = musd_helper.getRedeemValidity(fromToken, amount, dai);
                    musd.redeem(
                        dai,
                        result
                    );
                    super._swap(
                        dai,
                        destToken,
                        dai.balanceOf(address(this)),
                        distribution,
                        flags
                    );
                }
                return;
            }

            if (destToken == IERC20(musd)) {
                if (fromToken == usdc || fromToken == dai || fromToken == usdt || fromToken == tusd) {
                    fromToken.universalApprove(address(musd), amount);
                    musd.swap(
                        fromToken,
                        destToken,
                        amount,
                        address(this)
                    );
                }
                else {
                    super._swap(
                        fromToken,
                        dai,
                        amount,
                        distribution,
                        flags
                    );
                    musd.swap(
                        dai,
                        destToken,
                        dai.balanceOf(address(this)),
                        address(this)
                    );
                }
                return;
            }
        }

        return super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}

// File: contracts/interface/IDMM.sol

pragma solidity ^0.5.0;



interface IDMMController {
    function getUnderlyingTokenForDmm(IERC20 token) external view returns(IERC20);
}


contract IDMM is IERC20 {
    function getCurrentExchangeRate() public view returns(uint256);
    function mint(uint256 underlyingAmount) public returns(uint256);
    function redeem(uint256 amount) public returns(uint256);
}

// File: contracts/OneSplitDMM.sol

pragma solidity ^0.5.0;




contract OneSplitDMMBase {
    IDMMController internal constant _dmmController = IDMMController(0x4CB120Dd1D33C9A3De8Bc15620C7Cd43418d77E2);

    function _getDMMUnderlyingToken(IERC20 token) internal view returns(IERC20) {
        (bool success, bytes memory data) = address(_dmmController).staticcall(
            abi.encodeWithSelector(
                _dmmController.getUnderlyingTokenForDmm.selector,
                token
            )
        );

        if (!success || data.length == 0) {
            return IERC20(-1);
        }

        return abi.decode(data, (IERC20));
    }

    function _getDMMExchangeRate(IDMM dmm) internal view returns(uint256) {
        (bool success, bytes memory data) = address(dmm).staticcall(
            abi.encodeWithSelector(
                dmm.getCurrentExchangeRate.selector
            )
        );

        if (!success || data.length == 0) {
            return 0;
        }

        return abi.decode(data, (uint256));
    }
}


contract OneSplitDMMView is OneSplitViewWrapBase, OneSplitDMMBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
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
        return _dmmGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _dmmGetExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_DMM)) {
            IERC20 underlying = _getDMMUnderlyingToken(fromToken);
            if (underlying != IERC20(-1)) {
                if (underlying == weth) {
                    underlying = ETH_ADDRESS;
                }
                IERC20 _fromToken = fromToken;
                (returnAmount, estimateGasAmount, distribution) = _dmmGetExpectedReturn(
                    underlying,
                    destToken,
                    amount.mul(_getDMMExchangeRate(IDMM(address(_fromToken)))).div(1e18),
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 295_000, distribution);
            }

            underlying = _getDMMUnderlyingToken(destToken);
            if (underlying != IERC20(-1)) {
                if (underlying == weth) {
                    underlying = ETH_ADDRESS;
                }
                uint256 price = _getDMMExchangeRate(IDMM(address(destToken)));
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    fromToken,
                    underlying,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice.mul(price).div(1e18)
                );
                return (
                    returnAmount.mul(1e18).div(price),
                    estimateGasAmount + 430_000,
                    distribution
                );
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitDMM is OneSplitBaseWrap, OneSplitDMMBase {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _dmmSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _dmmSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_DMM)) {
            IERC20 underlying = _getDMMUnderlyingToken(fromToken);
            if (underlying != IERC20(-1)) {
                IDMM(address(fromToken)).redeem(amount);
                uint256 balance = underlying.universalBalanceOf(address(this));
                if (underlying == weth) {
                    weth.withdraw(balance);
                }
                _dmmSwap(
                    (underlying == weth) ? ETH_ADDRESS : underlying,
                    destToken,
                    balance,
                    distribution,
                    flags
                );
            }

            underlying = _getDMMUnderlyingToken(destToken);
            if (underlying != IERC20(-1)) {
                super._swap(
                    fromToken,
                    (underlying == weth) ? ETH_ADDRESS : underlying,
                    amount,
                    distribution,
                    flags
                );

                uint256 underlyingAmount = ((underlying == weth) ? ETH_ADDRESS : underlying).universalBalanceOf(address(this));
                if (underlying == weth) {
                    weth.deposit.value(underlyingAmount);
                }

                underlying.universalApprove(address(destToken), underlyingAmount);
                IDMM(address(destToken)).mint(underlyingAmount);
                return;
            }
        }

        return super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}

// File: contracts/OneSplitMooniswapPoolToken.sol

pragma solidity ^0.5.0;





contract OneSplitMooniswapTokenBase {
    using SafeMath for uint256;
    using Math for uint256;
    using UniversalERC20 for IERC20;

    struct TokenInfo {
        IERC20 token;
        uint256 reserve;
    }

    struct PoolDetails {
        TokenInfo[2] tokens;
        uint256 totalSupply;
    }

    function _getPoolDetails(IMooniswap pool) internal view returns (PoolDetails memory details) {
        for (uint i = 0; i < 2; i++) {
            IERC20 token = pool.tokens(i);
            details.tokens[i] = TokenInfo({
                token: token,
                reserve: token.universalBalanceOf(address(pool))
            });
        }

        details.totalSupply = IERC20(address(pool)).totalSupply();
    }
}


contract OneSplitMooniswapTokenView is OneSplitViewWrapBase, OneSplitMooniswapTokenBase {

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns (
            uint256 returnAmount,
            uint256,
            uint256[] memory distribution
        )
    {
        if (fromToken.eq(toToken)) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }


        if (!flags.check(FLAG_DISABLE_MOONISWAP_POOL_TOKEN)) {
            bool isPoolTokenFrom = mooniswapRegistry.isPool(address(fromToken));
            bool isPoolTokenTo = mooniswapRegistry.isPool(address(toToken));

            if (isPoolTokenFrom && isPoolTokenTo) {
                (
                    uint256 returnETHAmount,
                    uint256[] memory poolTokenFromDistribution
                ) = _getExpectedReturnFromMooniswapPoolToken(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    parts,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );

                (
                    uint256 returnPoolTokenToAmount,
                    uint256[] memory poolTokenToDistribution
                ) = _getExpectedReturnToMooniswapPoolToken(
                    ETH_ADDRESS,
                    toToken,
                    returnETHAmount,
                    parts,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );

                for (uint i = 0; i < poolTokenToDistribution.length; i++) {
                    poolTokenFromDistribution[i] |= poolTokenToDistribution[i] << 128;
                }

                return (returnPoolTokenToAmount, 0, poolTokenFromDistribution);
            }

            if (isPoolTokenFrom) {
                (returnAmount, distribution) = _getExpectedReturnFromMooniswapPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );
                return (returnAmount, 0, distribution);
            }

            if (isPoolTokenTo) {
                (returnAmount, distribution) = _getExpectedReturnToMooniswapPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );
                return (returnAmount, 0, distribution);
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            toToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _getExpectedReturnFromMooniswapPoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        PoolDetails memory details = _getPoolDetails(IMooniswap(address(poolToken)));

        for (uint i = 0; i < 2; i++) {

            uint256 exchangeAmount = amount
                .mul(details.tokens[i].reserve)
                .div(details.totalSupply);

            if (toToken.eq(details.tokens[i].token)) {
                returnAmount = returnAmount.add(exchangeAmount);
                continue;
            }

            (uint256 ret, ,uint256[] memory dist) = super.getExpectedReturnWithGas(
                details.tokens[i].token,
                toToken,
                exchangeAmount,
                parts,
                flags,
                0
            );

            returnAmount = returnAmount.add(ret);
            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        return (returnAmount, distribution);
    }

    function _getExpectedReturnToMooniswapPoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        PoolDetails memory details = _getPoolDetails(IMooniswap(address(poolToken)));

        // will overwritten to liquidity amounts
        uint256[2] memory amounts;
        amounts[0] = amount.div(2);
        amounts[1] = amount.sub(amounts[0]);
        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < 2; i++) {

            if (fromToken.eq(details.tokens[i].token)) {
                continue;
            }

            (amounts[i], ,dist) = super.getExpectedReturnWithGas(
                fromToken,
                details.tokens[i].token,
                amounts[i],
                parts,
                flags,
                0
            );

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        returnAmount = uint256(-1);
        for (uint i = 0; i < 2; i++) {
            returnAmount = Math.min(
                returnAmount,
                details.totalSupply.mul(amounts[i]).div(details.tokens[i].reserve)
            );
        }

        return (
            returnAmount,
            distribution
        );
    }

}


contract OneSplitMooniswapToken is OneSplitBaseWrap, OneSplitMooniswapTokenBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken.eq(toToken)) {
            return;
        }

        if (!flags.check(FLAG_DISABLE_MOONISWAP_POOL_TOKEN)) {
            bool isPoolTokenFrom = mooniswapRegistry.isPool(address(fromToken));
            bool isPoolTokenTo = mooniswapRegistry.isPool(address(toToken));

            if (isPoolTokenFrom && isPoolTokenTo) {
                uint256[] memory dist = new uint256[](distribution.length);
                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] & ((1 << 128) - 1);
                }

                uint256 ethBalanceBefore = ETH_ADDRESS.universalBalanceOf(address(this));

                _swapFromMooniswapToken(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    dist,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );

                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] >> 128;
                }

                uint256 ethBalanceAfter = ETH_ADDRESS.universalBalanceOf(address(this));

                return _swapToMooniswapToken(
                    ETH_ADDRESS,
                    toToken,
                    ethBalanceAfter.sub(ethBalanceBefore),
                    dist,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );
            }

            if (isPoolTokenFrom) {
                return _swapFromMooniswapToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );
            }

            if (isPoolTokenTo) {
                return _swapToMooniswapToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );
            }
        }

        return super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            flags
        );
    }

    function _swapFromMooniswapToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        IERC20[2] memory tokens = [
            IMooniswap(address(poolToken)).tokens(0),
            IMooniswap(address(poolToken)).tokens(1)
        ];

        IMooniswap(address(poolToken)).withdraw(
            amount,
            new uint256[](0)
        );

        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < 2; i++) {

            if (toToken.eq(tokens[i])) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            super._swap(
                tokens[i],
                toToken,
                tokens[i].universalBalanceOf(address(this)),
                dist,
                flags
            );
        }
    }

    function _swapToMooniswapToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        IERC20[2] memory tokens = [
            IMooniswap(address(poolToken)).tokens(0),
            IMooniswap(address(poolToken)).tokens(1)
        ];

        // will overwritten to liquidity amounts
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount.div(2);
        amounts[1] = amount.sub(amounts[0]);
        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < 2; i++) {

            if (fromToken.eq(tokens[i])) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            super._swap(
                fromToken,
                tokens[i],
                amounts[i],
                dist,
                flags
            );

            amounts[i] = tokens[i].universalBalanceOf(address(this));
            tokens[i].universalApprove(address(poolToken), amounts[i]);
        }

        uint256 ethValue = (tokens[0].isETH() ? amounts[0] : 0) + (tokens[1].isETH() ? amounts[1] : 0);
        IMooniswap(address(poolToken)).deposit.value(ethValue)(
            amounts,
            new uint256[](2)
        );

        for (uint i = 0; i < 2; i++) {
            tokens[i].universalTransfer(
                msg.sender,
                tokens[i].universalBalanceOf(address(this))
            );
        }
    }
}

// File: contracts/OneSplit.sol

pragma solidity ^0.5.0;















contract OneSplitViewWrap is
    OneSplitViewWrapBase,
    OneSplitMStableView,
    OneSplitChaiView,
    OneSplitBdaiView,
    OneSplitAaveView,
    OneSplitFulcrumView,
    OneSplitCompoundView,
    OneSplitIearnView,
    OneSplitIdleView,
    OneSplitWethView,
    OneSplitDMMView,
    OneSplitMooniswapTokenView
{
    IOneSplitView public oneSplitView;

    constructor(IOneSplitView _oneSplit) public {
        oneSplitView = _oneSplit;
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
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
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _getExpectedReturnRespectingGasFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        internal
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return oneSplitView.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitWrap is
    OneSplitBaseWrap,
    OneSplitMStable,
    OneSplitChai,
    OneSplitBdai,
    OneSplitAave,
    OneSplitFulcrum,
    OneSplitCompound,
    OneSplitIearn,
    OneSplitIdle,
    OneSplitWeth,
    OneSplitDMM,
    OneSplitMooniswapToken
{
    IOneSplitView public oneSplitView;
    IOneSplit public oneSplit;

    constructor(IOneSplitView _oneSplitView, IOneSplit _oneSplit) public {
        oneSplitView = _oneSplitView;
        oneSplit = _oneSplit;
    }

    function() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
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

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
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
        return oneSplitView.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function getExpectedReturnWithGasMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256[] memory parts,
        uint256[] memory flags,
        uint256[] memory destTokenEthPriceTimesGasPrices
    )
        public
        view
        returns(
            uint256[] memory returnAmounts,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        uint256[] memory dist;

        returnAmounts = new uint256[](tokens.length - 1);
        for (uint i = 1; i < tokens.length; i++) {
            if (tokens[i - 1] == tokens[i]) {
                returnAmounts[i - 1] = (i == 1) ? amount : returnAmounts[i - 2];
                continue;
            }

            IERC20[] memory _tokens = tokens;

            (
                returnAmounts[i - 1],
                amount,
                dist
            ) = getExpectedReturnWithGas(
                _tokens[i - 1],
                _tokens[i],
                (i == 1) ? amount : returnAmounts[i - 2],
                parts[i - 1],
                flags[i - 1],
                destTokenEthPriceTimesGasPrices[i - 1]
            );
            estimateGasAmount = estimateGasAmount.add(amount);

            if (distribution.length == 0) {
                distribution = new uint256[](dist.length);
            }
            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] = distribution[j].add(dist[j] << (8 * (i - 1)));
            }
        }
    }

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    ) public payable returns(uint256 returnAmount) {
        fromToken.universalTransferFrom(msg.sender, address(this), amount);
        uint256 confirmed = fromToken.universalBalanceOf(address(this));
        _swap(fromToken, destToken, confirmed, distribution, flags);

        returnAmount = destToken.universalBalanceOf(address(this));
        require(returnAmount >= minReturn, "OneSplit: actual return amount is less than minReturn");
        destToken.universalTransfer(msg.sender, returnAmount);
        fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
    }

    function swapMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256[] memory flags
    ) public payable returns(uint256 returnAmount) {
        tokens[0].universalTransferFrom(msg.sender, address(this), amount);

        returnAmount = tokens[0].universalBalanceOf(address(this));
        for (uint i = 1; i < tokens.length; i++) {
            if (tokens[i - 1] == tokens[i]) {
                continue;
            }

            uint256[] memory dist = new uint256[](distribution.length);
            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (8 * (i - 1))) & 0xFF;
            }

            _swap(
                tokens[i - 1],
                tokens[i],
                returnAmount,
                dist,
                flags[i - 1]
            );
            returnAmount = tokens[i].universalBalanceOf(address(this));
            tokens[i - 1].universalTransfer(msg.sender, tokens[i - 1].universalBalanceOf(address(this)));
        }

        require(returnAmount >= minReturn, "OneSplit: actual return amount is less than minReturn");
        tokens[tokens.length - 1].universalTransfer(msg.sender, returnAmount);
    }

    function _swapFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        fromToken.universalApprove(address(oneSplit), amount);
        oneSplit.swap.value(fromToken.isETH() ? amount : 0)(
            fromToken,
            destToken,
            amount,
            0,
            distribution,
            flags
        );
    }
}
