pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract IOneSplit {

    // disableFlags = FLAG_UNISWAP + FLAG_KYBER + ...
    uint256 constant public FLAG_UNISWAP = 0x01;
    uint256 constant public FLAG_KYBER = 0x02;
    uint256 constant public FLAG_KYBER_UNISWAP_RESERVE = 0x100000000; // Turned off by default
    uint256 constant public FLAG_KYBER_OASIS_RESERVE = 0x200000000; // Turned off by default
    uint256 constant public FLAG_KYBER_BANCOR_RESERVE = 0x400000000; // Turned off by default
    uint256 constant public FLAG_BANCOR = 0x04;
    uint256 constant public FLAG_OASIS = 0x08;
    uint256 constant public FLAG_COMPOUND = 0x10;
    uint256 constant public FLAG_FULCRUM = 0x20;
    uint256 constant public FLAG_CHAI = 0x40;
    uint256 constant public FLAG_AAVE = 0x80;
    uint256 constant public FLAG_SMART_TOKEN = 0x100;
    uint256 constant public FLAG_MULTI_PATH_ETH = 0x200; // Turned off by default
    uint256 constant public FLAG_IDLE = 0x400;

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags // 1 - Uniswap, 2 - Kyber, 4 - Bancor, 8 - Oasis, 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution // [Uniswap, Kyber, Bancor, Oasis]
        );

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution, // [Uniswap, Kyber, Bancor, Oasis]
        uint256 disableFlags // 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken
    )
        public
        payable;

    function goodSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256 parts,
        uint256 disableFlags // 1 - Uniswap, 2 - Kyber, 4 - Bancor, 8 - Oasis, 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken
    )
        public
        payable;
}
