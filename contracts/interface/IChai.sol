pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IPot {
    function dsr() external view returns (uint256);
    function chi() external view returns (uint256);
    function rho() external view returns (uint256);
    function drip() external returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
}


contract IChai is IERC20 {

    function POT() public view returns(IPot);

    function join(address dst, uint wad) external;

    function exit(address src, uint wad) external;
}


library ChaiHelper {

    IPot private constant POT = IPot(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    uint256 private constant RAY = 10 ** 27;

    function _mul(uint x, uint y) private pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function _rmul(uint x, uint y) private pure returns (uint z) {
        // always rounds down
        z = _mul(x, y) / RAY;
    }

    function _rdiv(uint x, uint y) private pure returns (uint z) {
        // always rounds down
        z = _mul(x, RAY) / y;
    }

    function rpow(uint x, uint n, uint base) private pure returns (uint z) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }

    function potDrip() private view returns(uint256) {
        return _rmul(rpow(POT.dsr(), now - POT.rho(), RAY), POT.chi());
    }

    function daiToChai(IChai /*chai*/, uint256 amount) internal view returns(uint256) {
        uint chi = (now > POT.rho()) ? potDrip() : POT.chi();
        return _rdiv(amount, chi);
    }

    function chaiToDai(IChai /*chai*/, uint256 amount) internal view returns(uint256) {
        uint chi = (now > POT.rho()) ? potDrip() : POT.chi();
        return _rmul(chi, amount);
    }
}