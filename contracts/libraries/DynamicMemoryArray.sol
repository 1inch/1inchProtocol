// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


library DynamicMemoryArray {
    using SafeMath for uint256;

    struct Addresses {
        uint256 length;
        address[] items;
    }

    function init(DynamicMemoryArray.Addresses memory self) internal pure {
        self.items = new address[](1000);
    }

    function at(DynamicMemoryArray.Addresses memory self, uint256 index) internal pure returns(address) {
        require(index < self.length, "DynMemArr: out of range");
        return self.items[index];
    }

    function push(DynamicMemoryArray.Addresses memory self, address item) internal pure returns(uint256) {
        require(self.length < self.items.length, "DynMemArr: out of limit");
        self.items[self.length++] = item;
        return self.length;
    }

    function pop(DynamicMemoryArray.Addresses memory self) internal pure returns(address) {
        require(self.length > 0, "DynMemArr: already empty");
        return self.items[--self.length];
    }
}
