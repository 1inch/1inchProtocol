pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IOasisExchange {

    function getBuyAmount(IERC20 buyGem, IERC20 payGem, uint256 payAmt)
        external view returns(uint256 fillAmt);

    function sellAllAmount(IERC20 payGem, uint payAmt, IERC20 buyGem, uint256 minFillAmount)
        external returns(uint256 fillAmt);
}
