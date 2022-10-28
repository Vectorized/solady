// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {LibBitmap} from "../src/utils/LibBitmap.sol";
import {LibBit} from "../src/utils/LibBit.sol";

contract LibBitmapTest is TestPlus {
    using LibBitmap for LibBitmap.Bitmap;

    error AlreadyClaimed();

    LibBitmap.Bitmap bitmap;

    function get(uint256 index) public view returns (bool result) {
        result = bitmap.get(index);
    }

    function set(uint256 index) public {
        bitmap.set(index);
    }

    function unset(uint256 index) public {
        bitmap.unset(index);
    }

    function toggle(uint256 index) public {
        bitmap.toggle(index);
    }

    function setTo(uint256 index, bool shouldSet) public {
        bitmap.setTo(index, shouldSet);
    }

    function claimWithGetSet(uint256 index) public {
        if (bitmap.get(index)) {
            revert AlreadyClaimed();
        }
        bitmap.set(index);
    }

    function claimWithToggle(uint256 index) public {
        if (bitmap.toggle(index) == false) {
            revert AlreadyClaimed();
        }
    }

    function testBitmapGet() public {
        testBitmapGet(111111);
    }

    function testBitmapGet(uint256 index) public {
        assertFalse(get(index));
    }

    function testBitmapSetAndGet(uint256 index) public {
        set(index);
        bool result = get(index);
        bool resultIsOne;
        /// @solidity memory-safe-assembly
        assembly {
            resultIsOne := eq(result, 1)
        }
        assertTrue(result);
        assertTrue(resultIsOne);
    }

    function testBitmapSet() public {
        testBitmapSet(222222);
    }

    function testBitmapSet(uint256 index) public {
        set(index);
        assertTrue(get(index));
    }

    function testBitmapUnset() public {
        testBitmapSet(333333);
    }

    function testBitmapUnset(uint256 index) public {
        set(index);
        assertTrue(get(index));
        unset(index);
        assertFalse(get(index));
    }

    function testBitmapSetTo() public {
        testBitmapSetTo(555555, true, 0);
        testBitmapSetTo(555555, false, 0);
    }

    function testBitmapSetTo(
        uint256 index,
        bool shouldSet,
        uint256 randomness
    ) public {
        bool shouldSetBrutalized;
        /// @solidity memory-safe-assembly
        assembly {
            if shouldSet {
                shouldSetBrutalized := or(iszero(randomness), randomness)
            }
        }
        setTo(index, shouldSetBrutalized);
        assertEq(get(index), shouldSet);
    }

    function testBitmapSetTo(uint256 index, uint256 randomness) public {
        randomness = _stepRandomness(randomness);
        unchecked {
            for (uint256 i; i < 5; ++i) {
                bool shouldSet;
                /// @solidity memory-safe-assembly
                assembly {
                    shouldSet := and(shr(i, randomness), 1)
                }
                testBitmapSetTo(index, shouldSet, randomness);
            }
        }
    }

    function testBitmapToggle() public {
        testBitmapToggle(777777, true);
        testBitmapToggle(777777, false);
    }

    function testBitmapToggle(uint256 index, bool initialValue) public {
        setTo(index, initialValue);
        assertEq(get(index), initialValue);
        toggle(index);
        assertEq(get(index), !initialValue);
    }

    function testBitmapClaimWithGetSet() public {
        uint256 index = 888888;
        this.claimWithGetSet(index);
        vm.expectRevert(AlreadyClaimed.selector);
        this.claimWithGetSet(index);
    }

    function testBitmapClaimWithToggle() public {
        uint256 index = 999999;
        this.claimWithToggle(index);
        vm.expectRevert(AlreadyClaimed.selector);
        this.claimWithToggle(index);
    }

    function testBitmapSetBatchWithinSingleBucket() public {
        _testBitmapSetBatch(257, 30);
    }

    function testBitmapSetBatchAcrossMultipleBuckets() public {
        _testBitmapSetBatch(10, 512);
    }

    function testBitmapSetBatch() public {
        unchecked {
            uint256 randomness = 123;
            for (uint256 i; i < 8; ++i) {
                randomness = _stepRandomness(randomness);
                uint256 start = randomness;
                randomness = _stepRandomness(randomness);
                uint256 amount = randomness;
                _testBitmapSetBatch(start, amount);
            }
        }
    }

    function testBitmapUnsetBatchWithinSingleBucket() public {
        _testBitmapUnsetBatch(257, 30);
    }

    function testBitmapUnsetBatchAcrossMultipleBuckets() public {
        _testBitmapUnsetBatch(10, 512);
    }

    function testBitmapUnsetBatch() public {
        unchecked {
            uint256 randomness = 123;
            for (uint256 i; i < 8; ++i) {
                randomness = _stepRandomness(randomness);
                uint256 start = randomness;
                randomness = _stepRandomness(randomness);
                uint256 amount = randomness;
                _testBitmapUnsetBatch(start, amount);
            }
        }
    }

    function testBitmapPopCountWithinSingleBucket() public {
        _testBitmapPopCount(1, 150);
    }

    function testBitmapPopCountAcrossMultipleBuckets() public {
        _testBitmapPopCount(10, 512);
    }

    function testBitmapPopCount(
        uint256 start,
        uint256 amount,
        uint256 randomness
    ) public {
        unchecked {
            uint256 n = 1000;
            uint256 expectedCount;
            _resetBitmap(0, n / 256 + 1);

            (start, amount) = _boundStartAndAmount(start, amount, n);

            uint256 jPrev = 0xff + 1;
            uint256 j = randomness & 0xff;
            while (true) {
                bitmap.set(j);
                if (j != jPrev && start <= j && j < start + amount) {
                    expectedCount += 1;
                }
                if (start + amount <= j && randomness & 7 == 0) break;
                randomness = _stepRandomness(randomness);
                jPrev = j;
                j += randomness & 0xff;
            }
            assertEq(bitmap.popCount(start, amount), expectedCount);
        }
    }

    function testBitmapPopCount() public {
        unchecked {
            uint256 randomness = 123;
            for (uint256 i; i < 8; ++i) {
                randomness = _stepRandomness(randomness);
                uint256 start = randomness;
                randomness = _stepRandomness(randomness);
                uint256 amount = randomness;
                randomness = _stepRandomness(randomness);
                testBitmapPopCount(start, amount, randomness);
            }
        }
    }

    function testBitmapFindLastSet() public {
        unchecked {
            bitmap.unsetBatch(0, 2000);
            bitmap.set(1000);
            for (uint256 i = 0; i < 1000; ++i) {
                assertEq(bitmap.findLastSet(i), LibBitmap.NOT_FOUND);
            }
            bitmap.set(100);
            bitmap.set(10);
            for (uint256 i = 0; i < 10; ++i) {
                assertEq(bitmap.findLastSet(i), LibBitmap.NOT_FOUND);
            }
            for (uint256 i = 10; i < 100; ++i) {
                assertEq(bitmap.findLastSet(i), 10);
            }
            for (uint256 i = 100; i < 600; ++i) {
                assertEq(bitmap.findLastSet(i), 100);
            }
            for (uint256 i = 1000; i < 1100; ++i) {
                assertEq(bitmap.findLastSet(i), 1000);
            }
            bitmap.set(0);
            for (uint256 i = 0; i < 10; ++i) {
                assertEq(bitmap.findLastSet(i), 0);
            }
        }
    }

    function testBitmapFindLastSet(uint256 before, uint256 randomness) public {
        uint256 n = 1000;
        unchecked {
            _resetBitmap(0, n / 256 + 1);
            before = before % n;
            randomness = randomness % n;
        }
        bitmap.set(randomness);
        if (randomness <= before) {
            assertEq(bitmap.findLastSet(before), randomness);
            uint256 nextLcg = _stepRandomness(randomness);
            bitmap.set(nextLcg);
            if (nextLcg <= before) {
                assertEq(bitmap.findLastSet(before), (randomness < nextLcg ? nextLcg : randomness));
            }
        } else {
            assertEq(bitmap.findLastSet(before), LibBitmap.NOT_FOUND);
            uint256 nextLcg = _stepRandomness(randomness);
            bitmap.set(nextLcg);
            if (nextLcg <= before) {
                assertEq(bitmap.findLastSet(before), nextLcg);
            } else {
                assertEq(bitmap.findLastSet(before), LibBitmap.NOT_FOUND);
            }
        }
    }

    function _testBitmapSetBatch(uint256 start, uint256 amount) internal {
        uint256 n = 1000;
        (start, amount) = _boundStartAndAmount(start, amount, n);

        unchecked {
            _resetBitmap(0, n / 256 + 1);
            bitmap.setBatch(start, amount);
            for (uint256 i; i < n; ++i) {
                if (i < start) {
                    assertFalse(bitmap.get(i));
                } else if (i < start + amount) {
                    assertTrue(bitmap.get(i));
                } else {
                    assertFalse(bitmap.get(i));
                }
            }
        }
    }

    function _testBitmapUnsetBatch(uint256 start, uint256 amount) internal {
        uint256 n = 1000;
        (start, amount) = _boundStartAndAmount(start, amount, n);

        unchecked {
            _resetBitmap(type(uint256).max, n / 256 + 1);
            bitmap.unsetBatch(start, amount);
            for (uint256 i; i < n; ++i) {
                if (i < start) {
                    assertTrue(bitmap.get(i));
                } else if (i < start + amount) {
                    assertFalse(bitmap.get(i));
                } else {
                    assertTrue(bitmap.get(i));
                }
            }
        }
    }

    function _testBitmapPopCount(uint256 start, uint256 amount) internal {
        uint256 n = 1000;
        (start, amount) = _boundStartAndAmount(start, amount, n);

        unchecked {
            _resetBitmap(0, n / 256 + 1);
            bitmap.setBatch(start, amount);
            assertEq(bitmap.popCount(0, n), amount);
            if (start > 0) {
                assertEq(bitmap.popCount(0, start - 1), 0);
            }
            if (start + amount < n) {
                assertEq(bitmap.popCount(start + amount, n - (start + amount)), 0);
            }
        }
    }

    function _boundStartAndAmount(
        uint256 start,
        uint256 amount,
        uint256 n
    ) private pure returns (uint256 boundedStart, uint256 boundedAmount) {
        unchecked {
            boundedStart = start % n;
            uint256 end = boundedStart + (amount % n);
            if (end > n) end = n;
            boundedAmount = end - boundedStart;
        }
    }

    function _resetBitmap(uint256 bucketValue, uint256 bucketEnd) private {
        unchecked {
            for (uint256 i; i < bucketEnd; ++i) {
                bitmap.map[i] = bucketValue;
            }
        }
    }
}
