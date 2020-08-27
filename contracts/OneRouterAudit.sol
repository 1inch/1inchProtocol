// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOneRouterSwap.sol";
import "./libraries/UniERC20.sol";
import "./sources/MooniswapSource.sol";
import "./OneRouterConstants.sol";


interface IReferralGasSponsor {
    function makeGasDiscount(
        uint256 gasSpent,
        uint256 returnAmount,
        bytes calldata msgSenderCalldata
    ) external;
}


interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns(uint256 freed);
}


contract OneRouterAudit is IOneRouterView, IOneRouterSwap, OneRouterConstants, Ownable {
    using UniERC20 for IERC20;
    using SafeMath for uint256;

    IOneRouterView public oneRouterView;
    IOneRouterSwap public oneRouterSwap;

    modifier validateInput(SwapInput memory input) {
        require(input.referral.fee <= 0.03e18, "OneRouter: fee out of range");
        require(input.fromToken != input.destToken, "OneRouter: invalid input");
        _;
    }

    constructor(IOneRouterView _oneRouterView, IOneRouterSwap _oneRouterSwap) public {
        oneRouterView = _oneRouterView;
        oneRouterSwap = _oneRouterSwap;
    }

    function setOneRouter(IOneRouterView _oneRouterView, IOneRouterSwap _oneRouterSwap) public onlyOwner {
        oneRouterView = _oneRouterView;
        oneRouterSwap = _oneRouterSwap;
    }

    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "OneRouter: ETH deposit rejected");
    }

    // View methods

    function getReturn(IERC20 fromToken, uint256[] memory amounts, Swap memory swap)
        public
        view
        override
        returns(
            Path[] memory paths,
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        )
    {
        return oneRouterView.getReturn(fromToken, amounts, swap);
    }

    function getSwapReturn(IERC20 fromToken, uint256[] memory amounts, Swap memory swap)
        public
        view
        override
        returns(SwapResult memory result)
    {
        return oneRouterView.getSwapReturn(fromToken, amounts, swap);
    }

    function getPathReturn(IERC20 fromToken, uint256[] memory amounts, Path memory path)
        public
        view
        override
        returns(PathResult memory result)
    {
        return oneRouterView.getPathReturn(fromToken, amounts, path);
    }

    function getMultiPathReturn(IERC20 fromToken, uint256[] memory amounts, Path[] memory paths)
        public
        view
        override
        returns(
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        )
    {
        return oneRouterView.getMultiPathReturn(fromToken, amounts, paths);
    }

    // Swap methods

    function makeSwap(
        SwapInput memory input,
        Swap memory swap,
        SwapDistribution memory swapDistribution
    )
        public
        payable
        override
        validateInput(input)
        returns(uint256 returnAmount)
    {
        uint256 gasStart = gasleft();
        _claimInput(input);
        input.fromToken.uniApprove(address(oneRouterSwap), input.amount);
        oneRouterSwap.makeSwap{ value: input.fromToken.isETH() ? input.amount : 0 }(input, swap, swapDistribution);
        return _processOutput(gasStart, input, swap.flags);
    }

    function makePathSwap(
        SwapInput memory input,
        Path memory path,
        PathDistribution memory pathDistribution
    )
        public
        payable
        override
        validateInput(input)
        returns(uint256 returnAmount)
    {
        uint256 gasStart = gasleft();
        _claimInput(input);
        input.fromToken.uniApprove(address(oneRouterSwap), input.amount);
        oneRouterSwap.makePathSwap{ value: input.fromToken.isETH() ? input.amount : 0 }(input, path, pathDistribution);
        return _processOutput(gasStart, input, path.swaps[0].flags);
    }

    function makeMultiPathSwap(
        SwapInput memory input,
        Path[] memory paths,
        PathDistribution[] memory pathDistributions,
        SwapDistribution memory interPathsDistribution
    )
        public
        payable
        override
        validateInput(input)
        returns(uint256 returnAmount)
    {
        uint256 gasStart = gasleft();
        _claimInput(input);
        input.fromToken.uniApprove(address(oneRouterSwap), input.amount);
        oneRouterSwap.makeMultiPathSwap{ value: input.fromToken.isETH() ? input.amount : 0 }(input, paths, pathDistributions, interPathsDistribution);
        return _processOutput(gasStart, input, paths[0].swaps[0].flags);
    }

    // Internal methods

    function _claimInput(SwapInput memory input) internal {
        input.fromToken.uniTransferFromSender(address(this), input.amount);
        input.amount = input.fromToken.uniBalanceOf(address(this));
    }

    function _processOutput(uint256 gasStart, SwapInput memory input, uint256 flags) private returns(uint256 returnAmount) {
        uint256 remaining = input.fromToken.uniBalanceOf(address(this));
        returnAmount = input.destToken.uniBalanceOf(address(this));
        require(returnAmount >= input.minReturn, "OneRouter: less than minReturn");
        input.fromToken.uniTransfer(msg.sender, remaining);
        input.destToken.uniTransfer(input.referral.ref, returnAmount.mul(input.referral.fee).div(1e18));
        input.destToken.uniTransfer(msg.sender, returnAmount.sub(returnAmount.mul(input.referral.fee).div(1e18)));

        if ((flags & (_FLAG_ENABLE_CHI_BURN | _FLAG_ENABLE_CHI_BURN_ORIGIN)) > 0) {
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            _chiBurnOrSell(
                ((flags & _FLAG_ENABLE_CHI_BURN_ORIGIN) > 0) ? tx.origin : msg.sender, // solhint-disable-line avoid-tx-origin
                (gasSpent + 14154) / 41947
            );
        }
        else if ((flags & _FLAG_ENABLE_REFERRAL_GAS_DISCOUNT) > 0) {
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            IReferralGasSponsor(input.referral.ref).makeGasDiscount(gasSpent, returnAmount, msg.data);
        }
    }

    function _chiBurnOrSell(address payable sponsor, uint256 amount) private {
        amount = Math.min(amount, _CHI.balanceOf(sponsor));
        if (amount == 0) {
            return;
        }
        IMooniswap exchange = IMooniswap(0x5B1fC2435B1f7C16c206e7968C0e8524eC29b786);
        uint256 sellRefund = MooniswapHelper.getReturn(exchange, _CHI, UniERC20.ZERO_ADDRESS, amount);
        uint256 burnRefund = amount.mul(18_000).mul(tx.gasprice);

        if (sellRefund.add(tx.gasprice.mul(36_000)) < burnRefund.add(tx.gasprice.mul(150_000))) {
            IFreeFromUpTo(address(_CHI)).freeFromUpTo(sponsor, amount);
        }
        else {
            _CHI.transferFrom(sponsor, address(this), amount);
            _CHI.approve(address(exchange), amount);
            exchange.swap(_CHI, UniERC20.ZERO_ADDRESS, amount, 0, 0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5);
            sponsor.transfer(address(this).balance);
        }
    }
}
