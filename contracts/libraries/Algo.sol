// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";


library Algo {
    using SafeMath for uint256;

    int256 public constant VERY_NEGATIVE_VALUE = -1e72;

    function findBestDistribution(int256[][] memory amounts, uint256 parts)
        internal
        pure
        returns(
            int256[] memory returnAmounts,
            uint256[][] memory distributions
        )
    {
        uint256 n = amounts.length;

        int256[][] memory answer = new int256[][](n); // int[n][parts+1]
        uint256[][] memory parent = new uint256[][](n); // int[n][parts+1]

        for (uint i = 0; i < n; i++) {
            answer[i] = new int256[](parts + 1);
            parent[i] = new uint256[](parts + 1);
        }

        for (uint j = 0; j <= parts; j++) {
            answer[0][j] = amounts[0][j];
            for (uint i = 1; i < n; i++) {
                answer[i][j] = VERY_NEGATIVE_VALUE;
            }
            parent[0][j] = 0;
        }

        for (uint i = 1; i < n; i++) {
            for (uint j = 0; j <= parts; j++) {
                answer[i][j] = answer[i - 1][j];
                parent[i][j] = j;

                for (uint k = 1; k <= j; k++) {
                    if (answer[i - 1][j - k] + amounts[i][k] > answer[i][j]) {
                        answer[i][j] = answer[i - 1][j - k] + amounts[i][k];
                        parent[i][j] = j - k;
                    }
                }
            }
        }

        distributions = new uint256[][](parts);
        returnAmounts = new int256[](parts);
        for (uint256 i = 1; i <= parts; i++) {
            uint256 partsLeft = i;
            distributions[i - 1] = new uint256[](n);
            for (uint curExchange = n - 1; partsLeft > 0; curExchange--) {
                distributions[i - 1][curExchange] = partsLeft - parent[curExchange][partsLeft];
                partsLeft = parent[curExchange][partsLeft];
            }

            returnAmounts[i - 1] = (answer[n - 1][i] == VERY_NEGATIVE_VALUE) ? 0 : answer[n - 1][i];
        }
    }
}
