// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC4337} from "../../../src/accounts/ERC4337.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC4337 is ERC4337 {
    function withdrawDepositTo(address to, uint256 amount) public virtual override {
        super.withdrawDepositTo(_brutalized(to), amount);
    }

    function _brutalized(address a) private pure returns (address result) {
        assembly {
            result := or(a, shl(160, 0x0123456789abcdeffedcba98))
        }
    }
}
