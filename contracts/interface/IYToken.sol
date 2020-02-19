pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract IYToken is IERC20 {
    function getPricePerFullShare() external view returns (uint256);

    function token() external view returns (address);

    function deposit(uint256 depositAmount) external;
    function withdraw(uint256 burnAmount) external;
}
