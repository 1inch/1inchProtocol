pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IDForceSwap {
    function getAmountByInput(IERC20 input, IERC20 output, uint256 amount) external view returns(uint256);
    function swap(IERC20 input, IERC20 output, uint256 amount) external;
}
