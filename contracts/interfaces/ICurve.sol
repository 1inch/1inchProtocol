// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


interface ICurve {
    // solhint-disable-next-line func-name-mixedcase
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns(uint256 dy);

    // solhint-disable-next-line func-name-mixedcase
    function get_dy(int128 i, int128 j, uint256 dx) external view returns(uint256 dy);

    // solhint-disable-next-line func-name-mixedcase
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 minDy) external;

    // solhint-disable-next-line func-name-mixedcase
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external;
}


interface ICurveRegistry {
    // solhint-disable-next-line func-name-mixedcase
    function get_pool_info(address pool)
        external
        view
        returns(
            uint256[8] memory balances,
            uint256[8] memory underlyingBalances,
            uint256[8] memory decimals,
            uint256[8] memory underlyingDecimals,
            address lpToken,
            uint256 a,
            uint256 fee
        );
}


interface ICurveCalculator {
    // solhint-disable-next-line func-name-mixedcase
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
