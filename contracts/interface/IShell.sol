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
