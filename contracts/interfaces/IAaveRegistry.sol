// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IAaveRegistry {
    function tokenByAToken(IERC20 aToken) external view returns(IERC20);
    function aTokenByToken(IERC20 token) external view returns(IERC20);
}
