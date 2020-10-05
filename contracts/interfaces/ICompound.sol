// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



interface ICompoundRegistry {
    function tokenByCToken(IERC20 cToken) external view returns(IERC20);
    function cTokenByToken(IERC20 token) external view returns(IERC20);
}


interface ICompound {
    function markets(address cToken) external view returns (bool isListed, uint256 collateralFactorMantissa);
}


abstract contract ICompoundToken is IERC20 {
    function underlying() external view virtual returns (address);
    function exchangeRateStored() external view virtual returns (uint256);
    function mint(uint256 mintAmount) external virtual returns (uint256);
    function redeem(uint256 redeemTokens) external virtual returns (uint256);
}


abstract contract ICompoundEther is IERC20 {
    function mint() external payable virtual;
    function redeem(uint256 redeemTokens) external virtual returns (uint256);
}
