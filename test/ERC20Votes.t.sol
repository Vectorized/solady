// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {FixedPointMathLib} from "../src/utils/FixedPointMathLib.sol";

contract ERC20VotesTest is SoladyTest {
    struct Checkpoint {
        uint256 key;
        uint256 value;
    }

    Checkpoint[] internal _trace;

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
        uint256 key;
        uint256 amount;
        bool isAdd;
        uint256 oldValueOriginal;
        uint256 oldValue;
        uint256 newValueOriginal;
        uint256 newValue;
    }

    function testCheckpointDifferential(uint256 lengthSlot, uint256 n) public {
        lengthSlot = uint256(keccak256(abi.encode(lengthSlot, "hehe")));
        unchecked {
            n = _randomChance(64) ? _bound(n, 1, 32) : _bound(n, 1, 8);
            _TestCheckpointTemps memory t;
            for (uint256 i; i != n; ++i) {
                uint256 lastKey = _checkpointLatestKeyOriginal();
                while (true) {
                    t.key = lastKey + _randomUniform() & 0xf;
                    t.amount = _random();
                    t.isAdd = _randomChance(2);
                    if (!_checkpointPushDiffOriginalReverts(t.key, t.amount, t.isAdd)) break;
                }

                (t.oldValueOriginal, t.newValueOriginal) =
                    _checkpointPushDiffOriginal(t.key, t.amount, t.isAdd);

                (t.oldValue, t.newValue) = _checkpointPushDiff(lengthSlot, t.key, t.amount, t.isAdd);

                assertEq(t.oldValue, t.oldValueOriginal);
                assertEq(t.newValue, t.newValueOriginal);

                assertEq(_checkpointLatestOriginal(), _checkpointLatest(lengthSlot));

                if (_randomChance(8)) _checkCheckpoints(lengthSlot);
                if (_randomChance(8)) _checkCheckpointUpperLookupRecent(lengthSlot);
            }
            _checkCheckpoints(lengthSlot);
            _checkCheckpointUpperLookupRecent(lengthSlot);
        }
    }

    function _checkCheckpoints(uint256 lengthSlot) internal tempMemory {
        unchecked {
            uint256 n = _trace.length;
            for (uint256 i; i != n; ++i) {
                (uint256 key, uint256 value) = _checkpointAt(lengthSlot, i);
                Checkpoint storage c = _trace[i];
                assertEq(key, c.key);
                assertEq(value, c.value);
            }
        }
    }

    function _checkCheckpointUpperLookupRecent(uint256 lengthSlot) internal tempMemory {
        uint256 key = _bound(_randomUniform(), 0, _checkpointLatestKeyOriginal() + 3);
        assertEq(
            _checkpointUpperLookupRecent(lengthSlot, key), _checkpointUpperLookupRecentOriginal(key)
        );
    }

    function _checkpointPushDiffOriginalReverts(uint256 key, uint256 amount, bool isAdd)
        internal
        tempMemory
        returns (bool)
    {
        (bool success,) = address(this).call(
            abi.encodeWithSignature(
                "checkpointPushDiffOriginalCheck(uint256,uint256,bool)", key, amount, isAdd
            )
        );
        return !success;
    }

    function checkpointPushDiffOriginalCheck(uint256 key, uint256 amount, bool isAdd)
        external
        view
    {
        uint256 oldValue;
        uint256 newValue;
        if (_trace.length == 0) {
            newValue = isAdd ? oldValue + amount : oldValue - amount;
        } else {
            Checkpoint storage last = _trace[_trace.length - 1];
            oldValue = last.value;
            newValue = isAdd ? oldValue + amount : oldValue - amount;
            if (last.key > key) revert("Unordered insertion");
        }
    }

    function _checkpointUpperLookupRecentOriginal(uint256 key)
        private
        view
        returns (uint256 result)
    {
        unchecked {
            uint256 n = _trace.length;
            for (uint256 i; i != n; ++i) {
                Checkpoint storage c = _trace[i];
                if (c.key > key) break;
                result = c.value;
            }
        }
    }

    function _checkpointPushDiffOriginal(uint256 key, uint256 amount, bool isAdd)
        private
        returns (uint256 oldValue, uint256 newValue)
    {
        if (_trace.length == 0) {
            newValue = isAdd ? oldValue + amount : oldValue - amount;
            _trace.push(Checkpoint(key, newValue));
        } else {
            Checkpoint storage last = _trace[_trace.length - 1];
            oldValue = last.value;
            newValue = isAdd ? oldValue + amount : oldValue - amount;
            if (last.key > key) revert("Unordered insertion");
            if (last.key == key) {
                last.value = newValue;
            } else {
                _trace.push(Checkpoint(key, newValue));
            }
        }
    }

    function _checkpointLatestKeyOriginal() private view returns (uint256) {
        return _trace.length == 0 ? 0 : _trace[_trace.length - 1].key;
    }

    function _checkpointLatestOriginal() private view returns (uint256) {
        return _trace.length == 0 ? 0 : _trace[_trace.length - 1].value;
    }

    function _checkpointPushDiff(uint256 lengthSlot, uint256 key, uint256 amount, bool isAdd)
        private
        returns (uint256 oldValue, uint256 newValue)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := sload(lengthSlot) // Checkpoint length. Must always be less than 2 ** 48.
            let checkpointSlot := shl(96, lengthSlot) // `lengthSlot` must never be zero.
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
                    sstore(not(checkpointSlot), newValue)
                    break
                }
                checkpointSlot := add(sub(n, 1), checkpointSlot)
                let lastPacked := sload(checkpointSlot)
                oldValue := shr(48, lastPacked)
                if eq(oldValue, address()) { oldValue := sload(not(checkpointSlot)) }
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
                    checkpointSlot := add(1, checkpointSlot)
                }
                if iszero(or(eq(newValue, address()), shr(208, newValue))) {
                    sstore(checkpointSlot, or(key, shl(48, newValue)))
                    break
                }
                sstore(checkpointSlot, or(key, shl(48, address())))
                sstore(not(checkpointSlot), newValue)
                break
            }
        }
    }

    function _checkpointLatest(uint256 lengthSlot) private view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := sload(lengthSlot) // Checkpoint length.
            if n {
                let checkpointSlot := add(sub(n, 1), shl(96, lengthSlot))
                result := shr(48, sload(checkpointSlot))
                if eq(result, address()) { result := sload(not(checkpointSlot)) }
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
            let checkpointSlot := shl(96, lengthSlot)
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
                if iszero(lt(key, and(sload(add(m, checkpointSlot)), 0xffffffffffff))) {
                    l := add(1, m)
                    break
                }
                h := m
                break
            }
            for {} lt(l, h) {} {
                let m := shr(1, add(l, h)) // Won't overflow in practice.
                if iszero(lt(key, and(sload(add(m, checkpointSlot)), 0xffffffffffff))) {
                    l := add(1, m)
                    continue
                }
                h := m
            }
            if h {
                checkpointSlot := add(sub(h, 1), checkpointSlot)
                result := shr(48, sload(checkpointSlot))
                if eq(result, address()) { result := sload(not(checkpointSlot)) }
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
            let checkpointSlot := add(i, shl(96, lengthSlot))
            let checkpointPacked := sload(checkpointSlot)
            key := and(0xffffffffffff, checkpointPacked)
            value := shr(48, checkpointPacked)
            if eq(value, address()) { value := sload(not(checkpointSlot)) }
        }
    }
}
