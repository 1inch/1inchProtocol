pragma solidity ^0.5.0;

import "./IOneSplit.sol";
import "./OneSplitBase.sol";
import "./OneSplitCompound.sol";
import "./OneSplitFulcrum.sol";
import "./OneSplitChai.sol";
import "./OneSplitBdai.sol";
import "./OneSplitIearn.sol";
import "./OneSplitIdle.sol";
import "./OneSplitAave.sol";
import "./OneSplitWeth.sol";
import "./OneSplitMStable.sol";
import "./OneSplitDMM.sol";
import "./OneSplitMooniswapPoolToken.sol";


contract OneSplitViewWrap is
    OneSplitViewWrapBase,
    OneSplitMStableView,
    OneSplitChaiView,
    OneSplitBdaiView,
    OneSplitAaveView,
    OneSplitFulcrumView,
    OneSplitCompoundView,
    OneSplitIearnView,
    OneSplitIdleView,
    OneSplitWethView,
    OneSplitDMMView,
    OneSplitMooniswapTokenView
{
    IOneSplitView public oneSplitView;

    constructor(IOneSplitView _oneSplit) public {
        oneSplitView = _oneSplit;
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        (returnAmount, , distribution) = getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _getExpectedReturnRespectingGasFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        internal
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return oneSplitView.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitWrap is
    OneSplitBaseWrap,
    OneSplitMStable,
    OneSplitChai,
    OneSplitBdai,
    OneSplitAave,
    OneSplitFulcrum,
    OneSplitCompound,
    OneSplitIearn,
    OneSplitIdle,
    OneSplitWeth,
    OneSplitDMM,
    OneSplitMooniswapToken
{
    IOneSplitView public oneSplitView;
    IOneSplit public oneSplit;

    constructor(IOneSplitView _oneSplitView, IOneSplit _oneSplit) public {
        oneSplitView = _oneSplitView;
        oneSplit = _oneSplit;
    }

    function() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        (returnAmount, , distribution) = getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return oneSplitView.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function getExpectedReturnWithGasMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256[] memory parts,
        uint256[] memory flags,
        uint256[] memory destTokenEthPriceTimesGasPrices
    )
        public
        view
        returns(
            uint256[] memory returnAmounts,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        uint256[] memory dist;

        returnAmounts = new uint256[](tokens.length - 1);
        for (uint i = 1; i < tokens.length; i++) {
            if (tokens[i - 1] == tokens[i]) {
                returnAmounts[i - 1] = (i == 1) ? amount : returnAmounts[i - 2];
                continue;
            }

            IERC20[] memory _tokens = tokens;

            (
                returnAmounts[i - 1],
                amount,
                dist
            ) = getExpectedReturnWithGas(
                _tokens[i - 1],
                _tokens[i],
                (i == 1) ? amount : returnAmounts[i - 2],
                parts[i - 1],
                flags[i - 1],
                destTokenEthPriceTimesGasPrices[i - 1]
            );
            estimateGasAmount = estimateGasAmount.add(amount);

            if (distribution.length == 0) {
                distribution = new uint256[](dist.length);
            }
            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] = distribution[j].add(dist[j] << (8 * (i - 1)));
            }
        }
    }

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    ) public payable returns(uint256 returnAmount) {
        fromToken.universalTransferFrom(msg.sender, address(this), amount);
        uint256 confirmed = fromToken.universalBalanceOf(address(this));
        _swap(fromToken, destToken, confirmed, distribution, flags);

        returnAmount = destToken.universalBalanceOf(address(this));
        require(returnAmount >= minReturn, "OneSplit: actual return amount is less than minReturn");
        destToken.universalTransfer(msg.sender, returnAmount);
        fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
    }

    function swapMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256[] memory flags
    ) public payable returns(uint256 returnAmount) {
        tokens[0].universalTransferFrom(msg.sender, address(this), amount);

        returnAmount = tokens[0].universalBalanceOf(address(this));
        for (uint i = 1; i < tokens.length; i++) {
            if (tokens[i - 1] == tokens[i]) {
                continue;
            }

            uint256[] memory dist = new uint256[](distribution.length);
            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (8 * (i - 1))) & 0xFF;
            }

            _swap(
                tokens[i - 1],
                tokens[i],
                returnAmount,
                dist,
                flags[i - 1]
            );
            returnAmount = tokens[i].universalBalanceOf(address(this));
            tokens[i - 1].universalTransfer(msg.sender, tokens[i - 1].universalBalanceOf(address(this)));
        }

        require(returnAmount >= minReturn, "OneSplit: actual return amount is less than minReturn");
        tokens[tokens.length - 1].universalTransfer(msg.sender, returnAmount);
    }

    function _swapFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        fromToken.universalApprove(address(oneSplit), amount);
        oneSplit.swap.value(fromToken.isETH() ? amount : 0)(
            fromToken,
            destToken,
            amount,
            0,
            distribution,
            flags
        );
    }
}
