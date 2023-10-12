// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC4337} from "../../../src/accounts/ERC4337.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC4337 is ERC4337 {
    function withdrawDepositTo(address to, uint256 amount) public payable virtual override {
        super.withdrawDepositTo(_brutalized(to), amount);
    }

    function _brutalized(address a) private pure returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(a, shl(160, 0x0123456789abcdeffedcba98))
        }
    }

    function executeBatch(uint256 filler, Call[] calldata calls)
        public
        payable
        virtual
        onlyEntryPointOrOwner
        returns (bytes[] memory results)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, add(mload(0x40), mod(filler, 0x40)))
        }
        return super.executeBatch(calls);
    }
}
