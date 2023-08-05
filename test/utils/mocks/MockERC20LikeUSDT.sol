// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MockERC20} from "./MockERC20.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC20LikeUSDT is MockERC20 {
    constructor() MockERC20("Tether USD", "USDT", 6) {}

    // Replicates USDT (0xdAC17F958D2ee523a2206206994597C13D831ec7) approval behavior.
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        require(amount == 0 || allowance(msg.sender, spender) == 0, "USDT approval failure");
        return super.approve(spender, amount);
    }
}
