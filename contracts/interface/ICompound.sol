pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract ICompound {
    function markets(address cToken)
        external
        view
        returns(bool isListed, uint256 collateralFactorMantissa);
}


contract ICompoundToken is IERC20 {
    function underlying() external view returns(address);
    function exchangeRateStored() external view returns(uint256);

    function mint(uint256 mintAmount) external returns(uint256);
    function redeem(uint256 redeemTokens) external returns(uint256);
}


contract ICompoundEther is IERC20 {
    function mint() external payable;
    function redeem(uint256 redeemTokens) external returns(uint256);
}
