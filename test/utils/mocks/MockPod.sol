// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Pod} from "../../../src/accounts/Pod.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockPod is Pod, Brutalizer {
    function initializeMothership(address initialMothership) public {
        _initializeMothership(_brutalized(initialMothership));
    }

    function setMothership(address newMothership) external {
        _setMothership(_brutalized(newMothership));
    }

    function executeBatch(uint256 filler, Call[] calldata calls)
        public
        payable
        virtual
        onlyMothership
        returns (bytes[] memory results)
    {
        _brutalizeMemory();
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, add(mload(0x40), mod(filler, 0x40)))
        }
        return super.executeBatch(calls);
    }
}
