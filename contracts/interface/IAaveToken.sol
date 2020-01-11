pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IAaveToken {

    function underlyingAssetAddress() external view returns(IERC20);

    function redeem(uint256 amount) external;
}

interface IAaveLendingPool {

    function core() external view returns(address);

    function deposit(IERC20 token, uint256 amount, uint16 refCode) external payable;
}
