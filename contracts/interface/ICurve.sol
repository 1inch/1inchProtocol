pragma solidity ^0.5.0;


interface ICurve {
    // solium-disable-next-line mixedcase
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns(uint256 dy);

    function get_virtual_price() external view returns(uint256);

    // solium-disable-next-line mixedcase
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 minDy) external;

    function coins(int128 arg0) external view returns (address);

    function balances(int128 arg0) external view returns (uint256);
}
