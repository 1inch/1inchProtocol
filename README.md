# 1inch on-chain DeFi aggregation protocol

First ever fully on-chain DEX aggregator protocol by 1inch

[![Build Status](https://travis-ci.org/CryptoManiacsZone/1split.svg?branch=master)](https://travis-ci.org/CryptoManiacsZone/1split)
[![Coverage Status](https://coveralls.io/repos/github/CryptoManiacsZone/1split/badge.svg?branch=master)](https://coveralls.io/github/CryptoManiacsZone/1split?branch=master)
[![Built-with openzeppelin](https://img.shields.io/badge/built%20with-OpenZeppelin-3677FF)](https://docs.openzeppelin.com/)

# Integration

Latest version is always accessible at [1split.eth](https://etherscan.io/address/1split.eth)

Start with checking out solidity interface: [IOneSplit.sol](https://github.com/CryptoManiacsZone/1split/blob/master/contracts/IOneSplit.sol)


## Methods

If you need Ether instead of any token use `address(0)` as param `fromToken`/`destToken`

- **getExpectedReturn(fromToken, destToken, amount, parts, flags)**

  Calculate expected returning amount of desired token

  | Params | Type | Description |
  | ----- | ----- | ----- |
  | fromToken | IERC20 | Address of trading off token |
  | destToken | IERC20 | Address of desired token |
  | amount | uint256 | Amount for `fromToken` |
  | parts | uint256 | Number of pieces source volume could be splitted (Works like granularity, higly affects gas usage. Should be called offchain, but could be called onchain if user swaps not his own funds, but this is still considered as not safe) |
  | flags | uint256 | Flags for enabling and disabling some features (default: `0`), see flags description |
  
  Return values: 

  | Params | Type | Description |
  | ----- | ----- | ----- |
  | returnAmount | uint256 | Expected returning amount of desired token |
  | distribution | uint256[] | Array of weights for volume distribution  |

  **Example:**
  ```
    let contract = new web3.eth.Contract(ABI, CONTRACT_ADDRESS)
    contract.methods.getExpectedReturn(
        fromToken, 
        toToken, 
        amount, 
        parts, 
        0
    ).call().then(data => {
      console.log(`returnAmount: ${data.returnAmount.toString()}`)
      console.log(`distribution: ${JSON.stringify(data.distribution)}`)
    }).catch(error => {
      // TO DO: ...
    });
  ```

- **swap(fromToken, destToken, amount, minReturn, distribution, flags)**

  Swap `amount` of `fromToken` to `destToken`

  | Params | Type | Description |
  | ----- | ----- | ----- |
  | fromToken | IERC20 | Address of trading off token |
  | destToken | IERC20 | Address of desired token |
  | amount | uint256 | Amount for `fromToken` |
  | minReturn | uint256 | Minimum expected return, else revert transaction |
  | distribution | uint256[] | Array of weights for volume distribution (returned by `getExpectedReturn`) |
  | flags | uint256 | Flags for enabling and disabling some features (default: `0`), see flags description |
  
  **Notice:** Make sure the `flags` param coincides `flags` param in `getExpectedReturn` method if you want the same result
  
  Return values: 
  
  | Params | Type | Description |
  | ----- | ----- | ----- |
  | returnAmount | uint256 | Recieved amount of desired token |

  **Example:**
  ```
   // TO DO: ...
  ```
- **swapWithReferral(fromToken, destToken, amount, minReturn, distribution, flags)**
  
  Swap `amount` of `fromToken` to `destToken`
  
  | Params | Type | Description |
  | ----- | ----- | ----- |
  | fromToken | IERC20 | Address of trading off token |
  | destToken | IERC20 | Address of desired token |
  | amount | uint256 | Amount for `fromToken` |
  | minReturn | uint256 | Minimum expected return, else revert transaction |
  | distribution | uint256[] | Array of weights for volume distribution (returned by `getExpectedReturn`) |
  | flags | uint256 | Flags for enabling and disabling some features (default: `0`), see flags description |
  | referral | address | Referrer's address |
  | feePercent | uint256 | Fees percents normalized to 1e18, limited to 0.03e18 (3%) |
  
  **Notice:** Make sure the `flags` param coincides `flags` param in `getExpectedReturn` method if you want the same result
  
  Return values: 
  
  | Params | Type | Description |
  | ----- | ----- | ----- |
  | returnAmount | uint256 | Recieved amount of desired token |

  **Example:**
  ```
   // TO DO: ...
  ```
  
## Flags
### Flag types
  There are basically 3 types of flags:
  1. **Exchange switch**<br>
  This flags allow `1split.eth` to enable or disable using exchange pools for swap. This can be applied for exchanges in genereral, for example: `split`, `wrap`, or this can be applied for a specific exchange type, for example: `bancor`, `oasis`.<br>
  This flags may be used in any combination.<br>
  List of `split` exchanges: `Uniswap`, `Kyber`, `Bancor`, `Oasis`, `CurveCompound`, `CurveUsdt`, `CurveY`, `CurveBinance`, `CurveSynthetix`, `UniswapCompound`, `UniswapChai`, `UniswapAave`, `Mooniswap`, `UniswapV2`, `UniswapV2ETH`, `UniswapV2DAI`, `UniswapV2USDC`, `CurvePax`, `CurveRenBtc`, `CurveTBtc`, `DforceSwap`, `Shellexchangers`.<br>
  List of `wrap` exchanges:  `Chai`, `Bdai`, `Aave`, `Fulcrum`, `Compound`, `Iearn`, `Idle`, `Weth`, `SmartToken`.
  
  2. **Transitional token selector**<br>
  This flags provide to swap from `fromToken` to `destToken` using transitional token.<br>
  This flags cann't be used in combination with the same type. <br>
  
  3. **Functional flags**<br>
  This flags provide some additional features.<br>
  This flags may be used in any combination.

### Flags description
`flags` param in `1split.eth` methods is sum  of flags values, for example:
```
flags = FLAG_DISABLE_UNISWAP + FLAG_DISABLE_KYBER + ...
```

- **Exchange switch**

  | Flag | Value | Description |
  | ---- | ---- | ---- |
  | FLAG_DISABLE_UNISWAP | `0x01` | Exclude `Uniswap` exchange from swap |
  | FLAG_DISABLE_KYBER | `0x02` | Exclude `Kyber` exchange from swap |
  | FLAG_ENABLE_KYBER_UNISWAP_RESERVE | `0x100000000` | Permit `Kyber` use `Uniswap`, by default it is forbidden |
  | FLAG_ENABLE_KYBER_OASIS_RESERVE | `0x200000000` | Permit `Kyber` use `Oasis`, by default it is forbidden |
  | FLAG_ENABLE_KYBER_BANCOR_RESERVE | `0x400000000` | Permit `Kyber` use `Bancor`, by default it is forbidden |
  | FLAG_DISABLE_BANCOR | `0x04` | Exclude `Bancor` exchange from swap |
  | FLAG_DISABLE_OASIS | `0x08` | Exclude `Oasis` exchange from swap |
  | FLAG_DISABLE_COMPOUND | `0x10` | Exclude `Compound` exchange from swap |
  | FLAG_DISABLE_FULCRUM | `0x20` | Exclude `Fulcrum` exchange from swap |
  | FLAG_DISABLE_CHAI | `0x40` | Exclude `Chai` exchange from swap |
  | FLAG_DISABLE_AAVE | `0x80` | Exclude `Aave` exchange from swap |
  | FLAG_DISABLE_SMART_TOKEN | `0x100` | Exclude `SmartToken` exchange from swap |
  | FLAG_DISABLE_BDAI | `0x400` | Exclude `Bdai` exchange from swap |
  | FLAG_DISABLE_IEARN | `0x800` | Exclude `Iearn` exchange from swap |
  | FLAG_DISABLE_CURVE_COMPOUND | `0x1000` | Exclude `CurveCompound` exchange from swap |
  | FLAG_DISABLE_CURVE_USDT | `0x2000` | Exclude `CurveUsdt` exchange from swap |
  | FLAG_DISABLE_CURVE_Y | `0x4000` | Exclude `CurveY` exchange from swap |
  | FLAG_DISABLE_CURVE_BINANCE | `0x8000` | Exclude `CurveBinance` exchange from swap |
  | FLAG_DISABLE_CURVE_SYNTHETIX | `0x40000` | Exclude `CurveSynthetix` exchange from swap |
  | FLAG_DISABLE_WETH | `0x80000` | Exclude `Weth` exchange from swap |
  | FLAG_ENABLE_UNISWAP_COMPOUND | `0x100000` | Permit `Uniswap` use `Compound`, by default it is forbidden. Works only when one of assets is `ETH` or `FLAG_ENABLE_MULTI_PATH_ETH` |
  | FLAG_ENABLE_UNISWAP_CHAI | `0x200000` | Permit `Uniswap` use `Chai`, by default it is forbidden. Works only when `ETH<>DAI` or `FLAG_ENABLE_MULTI_PATH_ETH` |
  | FLAG_ENABLE_UNISWAP_AAVE | `0x400000` | Permit `Uniswap` use `Aave`, by default it is forbidden. Works only when one of assets is `ETH` or `FLAG_ENABLE_MULTI_PATH_ETH` |
  | FLAG_DISABLE_IDLE | `0x800000` | Exclude `Idle` exchange from swap |
  | FLAG_DISABLE_MOONISWAP | `0x1000000` | Exclude `Mooniswap` exchange from swap |
  | FLAG_DISABLE_UNISWAP_V2_ALL | `0x1E000000` | Exclude all exchanges with `UniswapV2` prefix from swap |
  | FLAG_DISABLE_UNISWAP_V2 | `0x2000000` | Exclude `UniswapV2` exchange from swap |
  | FLAG_DISABLE_UNISWAP_V2_ETH | `0x4000000` | Exclude `UniswapV2ETH` exchange from swap |
  | FLAG_DISABLE_UNISWAP_V2_DAI | `0x8000000` | Exclude `UniswapV2DAI` exchange from swap |
  | FLAG_DISABLE_UNISWAP_V2_USDC | `0x10000000` | Exclude `UniswapV2USDC` exchange from swap |
  | FLAG_DISABLE_ALL_SPLIT_SOURCES | `0x20000000` | Exclude all `split` exchages from swap. Inverts `split` tokens flag values |
  | FLAG_DISABLE_ALL_WRAP_SOURCES | `0x40000000` | Exclude all `wrap` exchages from swap. Inverts `wrap` tokens flag values |
  | FLAG_DISABLE_CURVE_PAX | `0x80000000` | Exclude `CurvePax` exchange from swap |
  | FLAG_DISABLE_CURVE_RENBTC | `0x100000000` | Exclude `CurveRenBtc` exchange from swap |
  | FLAG_DISABLE_CURVE_TBTC | `0x200000000` | Exclude `CurveTBtc` exchange from swap |
  | FLAG_DISABLE_DFORCE_SWAP | `0x4000000000` | Exclude `DforceSwap` exchange from swap |
  | FLAG_DISABLE_SHELL | `0x8000000000` | Exclude `Shellexchangers` exchange from swap |
  
- **Transitional token selector**

  | Flag | Value | Description |
  | ---- | ---- | ---- |
  | FLAG_ENABLE_MULTI_PATH_ETH | `0x200` | Provides swap using `ETH` as a transitional token |
  | FLAG_ENABLE_MULTI_PATH_DAI | `0x10000` | Provides swap using `DAI` as a transitional token |
  | FLAG_ENABLE_MULTI_PATH_USDC | `0x20000` | Provides swap using `USDC` as a transitional token |
  | FLAG_ENABLE_MULTI_PATH_USDT | `0x400000000` | Provides swap using `USDT` as a transitional token |
  | FLAG_ENABLE_MULTI_PATH_WBTC | `0x800000000` | Provides swap using `WBTC` as a transitional token |
  | FLAG_ENABLE_MULTI_PATH_TBTC | `0x1000000000` | Provides swap using `TBTC` as a transitional token |
  | FLAG_ENABLE_MULTI_PATH_RENBTC | `0x2000000000` | Provides swap using `RENBTC` as a transitional token |
  
- **Functional flags**

  | Flag | Value | Description |
  | ---- | ---- | ---- |
  | FLAG_ENABLE_CHI_BURN | `0x10000000000` | Burns `CHI` token to save gas. Make sure it is approved for `1split.eth` in `CHI` contract |

