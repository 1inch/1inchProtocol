pragma solidity ^0.5.0;

import "../../contracts/OneSplit.sol";


contract OneSplitMock is OneSplit {

    function getExpectedReturnMock(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 ignoreFlags
    )
        public
        // view
        returns(
            uint256 returnAmount,
            uint[] memory distribution // [Uniswap, Kyber, Bancor, Oasis]
        )
    {
        this;
        return super.getExpectedReturn(fromToken, toToken, amount, parts, ignoreFlags);
    }
}
