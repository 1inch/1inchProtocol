pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract IBancorEtherToken is IERC20 {

    function deposit()
        external payable;

    function withdraw(uint256 amount)
        external;
}
