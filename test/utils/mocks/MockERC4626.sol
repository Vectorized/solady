// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20, ERC4626} from "../../../src/tokens/ERC4626.sol";

contract MockERC4626 is ERC4626 {
    bool public immutable useVirtualShares;
    uint8 public immutable decimalsOffset;

    address internal immutable _underlying;
    uint8 internal immutable _decimals;

    string internal _name;
    string internal _symbol;

    uint256 public beforeWithdrawHookCalledCounter;
    uint256 public afterDepositHookCalledCounter;

    constructor(
        address underlying_,
        string memory name_,
        string memory symbol_,
        bool useVirtualShares_,
        uint8 decimalsOffset_
    ) {
        _underlying = underlying_;

        (bool success, uint8 result) = _tryGetAssetDecimals(underlying_);
        _decimals = success ? result : _DEFAULT_UNDERLYING_DECIMALS;

        _name = name_;
        _symbol = symbol_;

        useVirtualShares = useVirtualShares_;
        decimalsOffset = decimalsOffset_;
    }

    function asset() public view virtual override returns (address) {
        return _underlying;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function _useVirtualShares() internal view virtual override returns (bool) {
        return useVirtualShares;
    }

    function _underlyingDecimals() internal view virtual override returns (uint8) {
        return _decimals;
    }

    function _decimalsOffset() internal view virtual override returns (uint8) {
        return decimalsOffset;
    }

    function _beforeWithdraw(uint256, uint256) internal override {
        unchecked {
            ++beforeWithdrawHookCalledCounter;
        }
    }

    function _afterDeposit(uint256, uint256) internal override {
        unchecked {
            ++afterDepositHookCalledCounter;
        }
    }
}
