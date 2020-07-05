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
