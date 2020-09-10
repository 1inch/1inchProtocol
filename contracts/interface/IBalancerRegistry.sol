pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBalancerPool.sol";


interface IBalancerRegistry {
    event PoolAdded(
        address indexed pool
    );
    event PoolTokenPairAdded(
        address indexed pool,
        address indexed fromToken,
        address indexed destToken
    );
    event IndicesUpdated(
        address indexed fromToken,
        address indexed destToken,
        bytes32 oldIndices,
        bytes32 newIndices
    );

    // Get info about pool pair for 1 SLOAD
    function getPairInfo(address pool, address fromToken, address destToken)
        external view returns(uint256 weight1, uint256 weight2, uint256 swapFee);

    // Pools
    function checkAddedPools(address pool)
        external view returns(bool);
    function getAddedPoolsLength()
        external view returns(uint256);
    function getAddedPools()
        external view returns(address[] memory);
    function getAddedPoolsWithLimit(uint256 offset, uint256 limit)
        external view returns(address[] memory result);

    // Tokens
    function getAllTokensLength()
        external view returns(uint256);
    function getAllTokens()
        external view returns(address[] memory);
    function getAllTokensWithLimit(uint256 offset, uint256 limit)
        external view returns(address[] memory result);

    // Pairs
    function getPoolsLength(address fromToken, address destToken)
        external view returns(uint256);
    function getPools(address fromToken, address destToken)
        external view returns(address[] memory);
    function getPoolsWithLimit(address fromToken, address destToken, uint256 offset, uint256 limit)
        external view returns(address[] memory result);
    function getBestPools(address fromToken, address destToken)
        external view returns(address[] memory pools);
    function getBestPoolsWithLimit(address fromToken, address destToken, uint256 limit)
        external view returns(address[] memory pools);

    // Get swap rates
    function getPoolReturn(address pool, address fromToken, address destToken, uint256 amount)
        external view returns(uint256);
    function getPoolReturns(address pool, address fromToken, address destToken, uint256[] calldata amounts)
        external view returns(uint256[] memory result);

    // Add and update registry
    function addPool(address pool) external returns(uint256 listed);
    function addPools(address[] calldata pools) external returns(uint256[] memory listed);
    function updatedIndices(address[] calldata tokens, uint256 lengthLimit) external;
}
