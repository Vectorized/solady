// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockETHRecipient {
    bool public immutable gasGriefUponReceiveETH;

    bool public immutable updateCounterUponReceiveETH;

    uint256 public counter;

    uint256 public garbage;

    constructor(bool updateCounterUponReceiveETH_, bool gasGriefUponReceiveETH_) {
        updateCounterUponReceiveETH = updateCounterUponReceiveETH_;
        gasGriefUponReceiveETH = gasGriefUponReceiveETH_;
    }

    receive() external payable {
        if (updateCounterUponReceiveETH) {
            counter += 1;
        }
        if (gasGriefUponReceiveETH) {
            /// @solidity memory-safe-assembly
            assembly {
                mstore(0x00, timestamp())
                mstore(0x20, 0)

                for { let i := 0 } lt(i, 10) { i := add(i, 1) } {
                    let h := keccak256(0x00, 0x40)
                    mstore(0x00, sload(h))
                    mstore(0x20, i)
                    sstore(add(h, 1), h)
                }
                sstore(garbage.slot, keccak256(0x00, 0x40))
            }
        }
    }
}
