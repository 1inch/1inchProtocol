// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract OneRouterConstants {
    uint256 constant internal _FLAG_DISABLE_RECALCULATION   = 0x1000000000000000000000000000000000000000000000000;

    uint256 constant internal _FLAG_DISABLE_ALL_SOURCES     = 0x100000000000000000000000000000000;
    uint256 constant internal _FLAG_DISABLE_KYBER_ALL       = 0x200000000000000000000000000000000;
    uint256 constant internal _FLAG_DISABLE_CURVE_ALL       = 0x400000000000000000000000000000000;
    uint256 constant internal _FLAG_DISABLE_BALANCER_ALL    = 0x800000000000000000000000000000000;

    uint256 constant internal _FLAG_DISABLE_UNISWAP_V1      = 0x1;
    uint256 constant internal _FLAG_DISABLE_UNISWAP_V2      = 0x2;
    uint256 constant internal _FLAG_DISABLE_MOONISWAP       = 0x4;
    uint256 constant internal _FLAG_DISABLE_KYBER_1         = 0x8;
    uint256 constant internal _FLAG_DISABLE_KYBER_2         = 0x10;
    uint256 constant internal _FLAG_DISABLE_KYBER_3         = 0x20;
    uint256 constant internal _FLAG_DISABLE_KYBER_4         = 0x40;
    uint256 constant internal _FLAG_DISABLE_CURVE_COMPOUND  = 0x80;
    uint256 constant internal _FLAG_DISABLE_CURVE_USDT      = 0x100;
    uint256 constant internal _FLAG_DISABLE_CURVE_Y         = 0x200;
    uint256 constant internal _FLAG_DISABLE_CURVE_BINANCE   = 0x400;
    uint256 constant internal _FLAG_DISABLE_CURVE_SYNTHETIX = 0x800;
    uint256 constant internal _FLAG_DISABLE_CURVE_PAX       = 0x1000;
    uint256 constant internal _FLAG_DISABLE_CURVE_RENBTC    = 0x2000;
    uint256 constant internal _FLAG_DISABLE_CURVE_TBTC      = 0x4000;
    uint256 constant internal _FLAG_DISABLE_CURVE_SBTC      = 0x8000;
    uint256 constant internal _FLAG_DISABLE_BALANCER_1      = 0x10000;
    uint256 constant internal _FLAG_DISABLE_BALANCER_2      = 0x20000;
    uint256 constant internal _FLAG_DISABLE_BALANCER_3      = 0x40000;
    uint256 constant internal _FLAG_DISABLE_BANCOR_1        = 0x80000;
    uint256 constant internal _FLAG_DISABLE_BANCOR_2        = 0x100000;
    uint256 constant internal _FLAG_DISABLE_BANCOR_3        = 0x200000;
    uint256 constant internal _FLAG_DISABLE_OASIS           = 0x400000;
    uint256 constant internal _FLAG_DISABLE_DFORCE_SWAP     = 0x800000;
    uint256 constant internal _FLAG_DISABLE_SHELL           = 0x1000000;
    uint256 constant internal _FLAG_DISABLE_MSTABLE_MUSD    = 0x2000000;
    uint256 constant internal _FLAG_DISABLE_BLACK_HOLE_SWAP = 0x4000000;

    IERC20 constant internal _DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant internal _USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant internal _USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 constant internal _TUSD = IERC20(0x0000000000085d4780B73119b644AE5ecd22b376);
    IERC20 constant internal _BUSD = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    IERC20 constant internal _SUSD = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    IERC20 constant internal _PAX = IERC20(0x8E870D67F660D95d5be530380D0eC0bd388289E1);
    IERC20 constant internal _RENBTC = IERC20(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
    IERC20 constant internal _WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 constant internal _SBTC = IERC20(0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6);
}
