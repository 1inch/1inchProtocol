pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract IIearn is IERC20 {
    function token() external view returns(IERC20);

    function calcPoolValueInToken() external view returns(uint256);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;
}
