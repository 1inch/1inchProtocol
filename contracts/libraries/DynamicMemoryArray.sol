// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


library DynamicMemoryArray {
    using SafeMath for uint256;

    struct Addresses {
        uint256 length;
        address[1000] _arr;
    }

    function at(DynamicMemoryArray.Addresses memory self, uint256 index) internal pure returns(address) {
        require(index < self.length, "DynMemArr: out of range");
        return self._arr[index];
    }

    function push(DynamicMemoryArray.Addresses memory self, address item) internal pure returns(uint256) {
        require(self.length < self._arr.length, "DynMemArr: out of limit");
        self._arr[self.length++] = item;
        return self.length;
    }

    function pop(DynamicMemoryArray.Addresses memory self) internal pure returns(address) {
        require(self.length > 0, "DynMemArr: already empty");
        return self._arr[--self.length];
    }

    function copy(DynamicMemoryArray.Addresses memory self) internal pure returns(address[] memory arr) {
        arr = new address[](self.length);
        for (uint i = 0; i < arr.length; i++) {
            arr[i] = self._arr[i];
        }
    }
}
