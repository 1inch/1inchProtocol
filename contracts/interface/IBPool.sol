pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BConst {
    uint public constant EXIT_FEE = 0;
}

contract IBMath is BConst {
    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        public
        pure returns (uint poolAmountOut);
}

contract IBPool is IERC20, IBMath {
    function getCurrentTokens() external view returns (address[] memory tokens);

    function getBalance(address token) external view returns (uint);

    function getNormalizedWeight(address token) external view returns (uint);

    function getDenormalizedWeight(address token) external view returns (uint);

    function getTotalDenormalizedWeight() external view returns (uint);

    function getSwapFee() external view returns (uint);
}
