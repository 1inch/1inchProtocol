pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IBalancerPool.sol";
import "./BalancerLib.sol";


contract BalancerHelper {
    using SafeMath for uint256;

    function getReturns(
        IBalancerPool pool,
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] calldata amounts
    )
        external
        view
        returns(uint256[] memory rets)
    {
        uint256 swapFee = pool.getSwapFee();
        uint256 fromBalance = pool.getBalance(fromToken);
        uint256 destBalance = pool.getBalance(destToken);
        uint256 fromWeight = pool.getDenormalizedWeight(fromToken);
        uint256 destWeight = pool.getDenormalizedWeight(destToken);

        rets = new uint256[](amounts.length);
        for (uint i = 0; i < amounts.length && amounts[i].mul(2) <= fromBalance; i++) {
            rets[i] = BalancerLib.calcOutGivenIn(
                fromBalance,
                fromWeight,
                destBalance,
                destWeight,
                amounts[i],
                swapFee
            );
        }
    }
}
