// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MockERC20} from "./MockERC20.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC20ForPermit2 is MockERC20 {
    constructor(string memory name_, string memory symbol_, uint8 decimals_)
        MockERC20(name_, symbol_, decimals_)
    {}

    function _givePermit2InfiniteAllowance() internal view virtual override returns (bool) {
        return true;
    }
}
