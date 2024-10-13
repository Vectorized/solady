// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "./ERC20.sol";

/// @notice ERC20 with votes based on ERC5805 and ERC6372.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC20Votes.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Votes.sol)
abstract contract ERC20Votes is ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERC6372                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function CLOCK_MODE() public view virtual returns (string memory) {
        return "mode=blocknumber&from=default";
    }

    function clock() public view returns (uint48) {
        if (block.number >= 2 ** 48) revert();
        return uint48(block.number);
    }

    /// @dev Used in `_afterTokenTransfer(address from, address to, uint256 amount)`.
    function _transferVotingUnits(address from, address to, uint256 amount) internal virtual {
        if (from == address(0)) {
            // _totalCheckpointPush(amount);
        }
        if (to == address(0)) {
            // _totalCheckpointPush(amount);
        }
    }

    // Note: Actually testing this for all kinds of input will be pretty crazy,
    // since we will actually need to populate a LOT of values in order to test.
    // I think around 700 checkpoints should be good?

    // Just copy and paste these functions into the test class.

    function _checkpointPushDiff(uint256 lengthSlot, uint256 key, uint256 amount, bool isAdd)
        private
        returns (uint256 oldValue, uint256 newValue)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := sload(lengthSlot) // Checkpoint length. Must always be less than 2 ** 48.
            let checkpointSlot := shl(50, lengthSlot) // `lengthSlot` must never be zero.
            for {} 1 {} {
                if iszero(n) {
                    if iszero(or(isAdd, iszero(amount))) {
                        mstore(0x00, 0x8ec8c748) // `ERC20VoteCheckpointUnderflow()`.
                        revert(0x1c, 0x04)
                    }
                    newValue := amount
                    sstore(lengthSlot, 1)
                    if iszero(or(eq(newValue, address()), shr(208, newValue))) {
                        sstore(checkpointSlot, or(key, shl(48, newValue)))
                        break
                    }
                    sstore(checkpointSlot, or(key, shl(48, address())))
                    sstore(add(1, checkpointSlot), newValue)
                    break
                }
                checkpointSlot := add(add(n, n), checkpointSlot)
                let lastPacked := sload(checkpointSlot)
                oldValue := shr(48, lastPacked)
                if eq(oldValue, address()) { oldValue := sload(add(1, checkpointSlot)) }
                for {} 1 {} {
                    if iszero(isAdd) {
                        if gt(amount, oldValue) {
                            mstore(0x00, 0x8ec8c748) // `ERC20VoteCheckpointUnderflow()`.
                            revert(0x1c, 0x04)
                        }
                        newValue := sub(oldValue, amount)
                        break
                    }
                    newValue := add(oldValue, amount)
                    if lt(newValue, oldValue) {
                        mstore(0x00, 0x888051e3) // `ERC20VoteCheckpointOverflow()`.
                        revert(0x1c, 0x04)
                    }
                    break
                }
                let lastKey := and(0xffffffffffff, lastPacked)
                if gt(lastKey, key) {
                    mstore(0x00, 0x24a526cc) // `ERC20VoteCheckpointUnorderedInsertion()`
                    revert(0x1c, 0x04)
                }
                if iszero(eq(lastKey, key)) {
                    sstore(lengthSlot, add(n, 1))
                    checkpointSlot := add(2, checkpointSlot)
                }
                if iszero(or(eq(newValue, address()), shr(208, newValue))) {
                    sstore(checkpointSlot, or(key, shl(48, newValue)))
                    break
                }
                sstore(checkpointSlot, or(key, shl(48, address())))
                sstore(add(1, checkpointSlot), newValue)
                break
            }
        }
    }

    function _checkpointLatest(uint256 lengthSlot) private view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := sload(lengthSlot) // Checkpoint length.
            if n {
                let checkpointSlot := add(sub(add(n, n), 2), shl(50, lengthSlot))
                result := shr(48, sload(checkpointSlot))
                if eq(result, address()) { result := sload(add(1, checkpointSlot)) }
            }
        }
    }

    function _checkpointUpperLookupRecent(uint256 lengthSlot, uint256 key)
        private
        view
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := sload(lengthSlot)
            let checkpointSlot := shl(50, lengthSlot)
            let l := 0 // Low.
            let h := n // High.
            for {} iszero(lt(n, 6)) {} {
                let m := shl(4, lt(0xffff, n))
                m := shl(shr(1, or(m, shl(3, lt(0xff, shr(m, n))))), 16)
                m := shr(1, add(m, div(n, m)))
                m := shr(1, add(m, div(n, m)))
                m := shr(1, add(m, div(n, m)))
                m := shr(1, add(m, div(n, m)))
                m := shr(1, add(m, div(n, m)))
                m := sub(n, shr(1, add(m, div(n, m)))) // Approx `n - sqrt(n)`.
                if iszero(lt(key, and(sload(add(add(m, m), checkpointSlot)), 0xffffffffffff))) {
                    l := add(1, m)
                    break
                }
                h := m
                break
            }
            for {} lt(l, h) {} {
                let m := shr(1, add(l, h)) // Won't overflow in practice.
                if iszero(lt(key, and(sload(add(add(m, m), checkpointSlot)), 0xffffffffffff))) {
                    l := add(1, m)
                    continue
                }
                h := m
            }
            if h {
                checkpointSlot := add(sub(add(h, h), 2), checkpointSlot)
                result := shr(48, sload(checkpointSlot))
                if eq(result, address()) { result := sload(add(1, checkpointSlot)) }
            }
        }
    }
}
