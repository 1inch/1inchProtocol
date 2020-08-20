// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


abstract contract IWETH is IERC20 {
    function deposit() external payable virtual;
    function withdraw(uint256 amount) external virtual;
}
