pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IKyberStorage {
    function getReserveAddressesPerTokenSrc(
        IERC20 token,
        uint256 startIndex,
        uint256 endToken
    ) external view returns (address[] memory);

    function getReserveId(
        address reserve
    ) external view returns (bytes32);
}
