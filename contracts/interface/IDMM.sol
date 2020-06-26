pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IDMMController {
    function getUnderlyingTokenForDmm(IERC20 token) external view returns(IERC20);
}


contract IDMM is IERC20 {
    function getCurrentExchangeRate() public view returns(uint256);
    function mint(uint256 underlyingAmount) public returns(uint256);
    function redeem(uint256 amount) public returns(uint256);
}
