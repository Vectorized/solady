// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
            assembly {
                let m := mload(0x40)
                let n := 3000
                for {
                    let i := 0
                } lt(i, n) {
                    i := add(i, 1)
                } {
                    mstore(add(m, mul(0x20, i)), i)
                }
                mstore(m, timestamp())
                sstore(garbage.slot, keccak256(m, mul(0x20, n)))
            }
        }
    }
}
