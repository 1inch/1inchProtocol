pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract IFulcrumToken is IERC20 {

    function tokenPrice() external view returns(uint256);
    function loanTokenAddress() external view returns(address);

    function mintWithEther(address receiver)
        external payable returns (uint256 mintAmount);

    function mint(address receiver, uint256 depositAmount)
        external returns (uint256 mintAmount);

    function burnToEther(address receiver, uint256 burnAmount)
        external returns (uint256 loanAmountPaid);

    function burn(address receiver, uint256 burnAmount)
        external returns (uint256 loanAmountPaid);
}
