// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ICompoundRegistry {
    function tokenByCToken(IERC20 cToken) external view returns(IERC20);
    function cTokenByToken(IERC20 token) external view returns(IERC20);
}
