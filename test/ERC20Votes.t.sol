// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {FixedPointMathLib} from "../src/utils/FixedPointMathLib.sol";

contract ERC20VotesTest is SoladyTest {
    function testSmallSqrtApprox(uint32 n) public {
        uint256 approx = _smallSqrtApprox(n);
        uint256 groundTruth = FixedPointMathLib.sqrt(n);
        assertGe(approx, groundTruth);
        assertLe(FixedPointMathLib.dist(approx, groundTruth), 3);
    }

    function _smallSqrtApprox(uint256 n) internal pure returns (uint256 m) {
        /// @solidity memory-safe-assembly
        assembly {
            m := shl(4, lt(0xffff, n))
            m := shl(shr(1, or(shl(3, lt(0xff, shr(m, n))), m)), 16)
            m := shr(1, add(m, div(n, m)))
            m := shr(1, add(m, div(n, m)))
            m := shr(1, add(m, div(n, m)))
            m := shr(1, add(m, div(n, m)))
            m := shr(1, add(m, div(n, m)))
            m := shr(1, add(m, div(n, m)))
        }
    }

    struct _TestCheckpointTemps {
        uint48 prevKey;
        uint48 key;
        uint256 lastValue;
        uint256 amount;
        bool isAdd;
    }

    event CheckpointChanged(uint256 oldValue, uint256 newValue);

    function testCheckpointDifferential(uint256 lengthSlot, uint256 n) public {
        lengthSlot = uint256(keccak256(abi.encode(lengthSlot, "hehe")));
        unchecked {
            n = _bound(n, 1, 32);
            _TestCheckpointTemps memory t;
            for (uint256 i; i != n; ++i) {
                do {
                    t.key = uint48(_random());
                } while (t.key > t.prevKey);

                while (true) {
                    t.amount = _random();
                    t.isAdd = _randomChance(2);
                    if (t.isAdd && type(uint256).max - t.lastValue >= t.amount) break;
                    if (!t.isAdd && t.lastValue >= t.amount) break;
                }

                (uint256 oldValue, uint256 newValue) =
                    _checkpointPushDiffOriginal(t.key, t.amount, t.isAdd);
                emit CheckpointChanged(oldValue, newValue);
                _checkpointPushDiff(lengthSlot, t.key, t.amount, t.isAdd);
                t.prevKey = t.key;
            }
        }
    }

    struct Checkpoint {
        uint256 key;
        uint256 value;
    }

    Checkpoint[] internal _trace;

    function _checkpointPushDiffOriginal(uint256 key, uint256 amount, bool isAdd)
        private
        returns (uint256 oldValue, uint256 newValue)
    {
        if (_trace.length == 0) {
            newValue = isAdd ? oldValue + amount : oldValue - amount;
            _trace.push(Checkpoint(key, newValue));
        } else {
            Checkpoint storage last = _trace[_trace.length - 1];
            newValue = isAdd ? oldValue + amount : oldValue - amount;
            if (last.key > key) revert("Unordered insertion");
            if (last.key == key) {
                last.value = newValue;
            } else {
                _trace.push(Checkpoint(key, newValue));
            }
        }
    }

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
                log1(0x00, 0x00, newValue)
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

    function _checkpointAt(uint256 lengthSlot, uint256 i)
        private
        view
        returns (uint256 key, uint256 value)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := sload(lengthSlot) // Checkpoint length.
            if iszero(lt(i, n)) { invalid() }
            let checkpointSlot := add(sub(add(i, i), 2), shl(50, lengthSlot))
            let checkpointPacked := sload(checkpointSlot)
            key := and(0xffffffffffff, checkpointPacked)
            value := shr(48, checkpointPacked)
            if eq(value, address()) { value := sload(add(1, checkpointSlot)) }
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
