pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "./interface/IIdle.sol";
import "./OneSplitBase.sol";

contract OneSplitIdle is OneSplitBase {
  function getExpectedReturn(
    IERC20 fromToken,
    IERC20 toToken,
    uint256 amount,
    uint256 parts,
    uint256 disableFlags
  )
    public
    view
    returns(
      uint256 returnAmount,
      uint256[] memory distribution
    )
  {
    if (fromToken == toToken) {
      return (amount, new uint256[](4));
    }

    if (disableFlags.enabled(FLAG_IDLE)) {
      if (_isIdleToken(fromToken)) {
        IERC20 underlying = _idleUnderlyingAsset(fromToken);
        if (underlying != IERC20(-1)) {
          uint256 idleRate = IIdle(address(fromToken)).tokenPrice();

          return super.getExpectedReturn(
            underlying,
            toToken,
            amount.mul(idleRate).div(1e18),
            parts,
            disableFlags
          );
        }
      }

      if (_isIdleToken(toToken)) {
        IERC20 underlying = _idleUnderlyingAsset(toToken);
        if (underlying != IERC20(-1)) {
          uint256 idleRate = IIdle(address(fromToken)).tokenPrice();

          (returnAmount, distribution) = super.getExpectedReturn(
            fromToken,
            underlying,
            amount,
            parts,
            disableFlags
          );

          returnAmount = returnAmount.mul(1e18).div(idleRate);
          return (returnAmount, distribution);
        }
      }
    }

    return super.getExpectedReturn(
        fromToken,
        toToken,
        amount,
        parts,
        disableFlags
    );
  }

  function _swap(
    IERC20 fromToken,
    IERC20 toToken,
    uint256 amount,
    uint256[] memory distribution,
    uint256 disableFlags
  ) internal {
    if (fromToken == toToken) {
      return;
    }

    if (disableFlags.enabled(FLAG_IDLE)) {
      if (_isIdleToken(fromToken)) {
        IERC20 underlying = _idleUnderlyingAsset(fromToken);

        IIdle(address(fromToken)).redeemIdleToken(amount, true, []);
        uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

        return super._swap(
          underlying,
          toToken,
          underlyingAmount,
          distribution,
          disableFlags
        );
      }

      if (_isIdleToken(toToken)) {
        IERC20 underlying = _idleUnderlyingAsset(toToken);

        super._swap(
          fromToken,
          underlying,
          amount,
          distribution,
          disableFlags
        );

        uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

        _infiniteApproveIfNeeded(underlying, address(toToken));
        IIdle(address(toToken)).mintIdleToken(underlyingAmount, []);
        return;
      }
    }

    return super._swap(
      fromToken,
      toToken,
      amount,
      distribution,
      disableFlags
    );
  }

  function _isIdleToken(IERC20 token) internal view returns(bool) {
    if (token.isETH()) {
      return IERC20(-1);
    }
    (bool success, bytes memory data) = address(token).staticcall.gas(5000)(abi.encodeWithSelector(
      ERC20Detailed(address(token)).name.selector
    ));
    if (!success) {
      return IERC20(-1);
    }

    bool foundIdle = false;
    for (uint i = 0; i < data.length - 4; i++) {
      if (data[i + 0] == "I" &&
          data[i + 1] == "d" &&
          data[i + 2] == "l" &&
          data[i + 3] == "e")
      {
        foundIdle = true;
        break;
      }
    }
    if (!foundIdle) {
      return IERC20(-1);
    }

    (success, data) = address(token).staticcall.gas(5000)(abi.encodeWithSelector(
      IIdle(address(token)).token.selector
    ));
    if (!success) {
      return IERC20(-1);
    }

    (address underlying) = abi.decode(data, (IERC20));
    return underlying != address(0);
  }

  function _idleUnderlyingAsset(IERC20 asset) internal view returns(IERC20) {
    (bool success, bytes memory data) = address(asset).staticcall.gas(5000)(abi.encodeWithSelector(
      IIdle(address(asset)).token.selector
    ));
    if (!success) {
      return IERC20(-1);
    }

    return abi.decode(data, (IERC20));
  }
}
