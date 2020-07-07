pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IKyberStorage {
    function getReserveIdsPerTokenSrc(
        IERC20 token
    ) external view returns (bytes32[] memory);
}
