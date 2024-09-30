// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import "src/utils/LibSort.sol";

contract LibSortTest is SoladyTest {
    function testInsertionSortAddressesDifferential(uint256) public {
        unchecked {
            uint256 n = _randomChance(32) ? _randomArrayLength() : _random() % 4;
            address[] memory a = _randomAddresses(n);
            // Make a copy of the `a` and perform insertion sort on it.
            address[] memory aCopy = _copy(a);
            for (uint256 i = 1; i < n; ++i) {
                address key = aCopy[i];
                uint256 j = i;
                while (j != 0 && aCopy[j - 1] > key) {
                    aCopy[j] = aCopy[j - 1];
                    --j;
                }
                aCopy[j] = key;
            }
            LibSort.insertionSort(a);
            assertEq(a, aCopy);
        }
    }

    function testInsertionSortPsuedorandom(uint256) public {
        unchecked {
            uint256[] memory a = _randomUints(32);
            LibSort.insertionSort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testInsertionSortPsuedorandom() public {
        testInsertionSortPsuedorandom(123456789);
    }

    function testSortChecksumed(uint256) public {
        unchecked {
            uint256 n = _randomArrayLength();
            uint256[] memory a = _randomUints(n);
            uint256 checksum;
            for (uint256 i = 0; i != n; ++i) {
                checksum += a[i];
            }
            LibSort.sort(a);
            uint256 checksumAfterSort;
            for (uint256 i = 0; i != n; ++i) {
                checksumAfterSort += a[i];
            }
            assertEq(checksum, checksumAfterSort);
            assertTrue(_isSorted(a));
        }
    }

    function testSortDifferential(uint256) public {
        unchecked {
            uint256[] memory a = _randomUints(_randomArrayLength());
            // Make a copy of the `a` and perform insertion sort on it.
            uint256[] memory aCopy = _copy(a);
            LibSort.insertionSort(aCopy);
            LibSort.sort(a);
            assertEq(a, aCopy);
        }
    }

    function testSort(uint256) public {
        unchecked {
            uint256[] memory a = _randomUints(_randomArrayLength());
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortBasicCase() public {
        unchecked {
            uint256[] memory a = new uint256[](2);
            a[0] = 3;
            a[1] = 0;
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortPsuedorandom(uint256) public {
        unchecked {
            uint256[] memory a = _randomUints(100);
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortPsuedorandom() public {
        testSortPsuedorandom(123456789);
    }

    function testSortPsuedorandomNonuniform(uint256) public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = _random() << (i & 8 == 0 ? 128 : 0);
            }
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortPsuedorandomNonuniform() public {
        testSortPsuedorandomNonuniform(123456789);
    }

    function testSortSorted() public {
        unchecked {
            uint256 n = 100;
            uint256[] memory a = new uint256[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = i;
            }
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortReversed() public {
        unchecked {
            uint256 n = 100;
            uint256[] memory a = new uint256[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = 999 - i;
            }
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortMostlySame() public {
        unchecked {
            uint256 n = 100;
            uint256[] memory a = new uint256[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = i % 8 == 0 ? i : 0;
            }
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortTestOverhead() public {
        unchecked {
            uint256 n = 100;
            uint256[] memory a = new uint256[](n);
            uint256 mask = (1 << 128) - 1;
            for (uint256 i; i != n; ++i) {
                a[i] = (i << 128) | (_random() & mask);
            }
            assertTrue(_isSorted(a));
        }
    }

    function testSortAddressesPsuedorandomBrutalizeUpperBits() public {
        unchecked {
            uint256 n = 100;
            address[] memory a = new address[](n);
            for (uint256 i; i != n; ++i) {
                address addr = address(uint160(_random()));
                uint256 randomness = _random();
                /// @solidity memory-safe-assembly
                assembly {
                    addr := or(addr, shl(160, randomness))
                }
                a[i] = addr;
            }
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortAddressesDifferential(uint256) public {
        unchecked {
            uint256 n = _randomArrayLength();
            uint256[] memory aRaw = _randomUints(n);
            address[] memory a = new address[](n);
            for (uint256 i; i != n; ++i) {
                address addr;
                uint256 addrRaw = aRaw[i];
                /// @solidity memory-safe-assembly
                assembly {
                    addr := addrRaw
                }
                a[i] = addr;
            }
            // Make a copy of the `a` and perform insertion sort on it.
            address[] memory aCopy = _copy(a);
            LibSort.insertionSort(aCopy);
            LibSort.sort(a);
            assertEq(a, aCopy);
        }
    }

    function testSortAddressesPsuedorandom(uint256) public {
        unchecked {
            address[] memory a = _randomAddresses(100);
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortAddressesPsuedorandom() public {
        testSortAddressesPsuedorandom(123456789);
    }

    function testSortAddressesSorted() public {
        unchecked {
            uint256 n = 100;
            address[] memory a = new address[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = address(uint160(i));
            }
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortAddressesReversed() public {
        unchecked {
            uint256 n = 100;
            address[] memory a = new address[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = address(uint160(999 - i));
            }
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortOriginalPsuedorandom(uint256) public {
        unchecked {
            uint256 n = 100;
            uint256[] memory a = new uint256[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = _random();
            }
            _sortOriginal(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortOriginalPsuedorandom() public {
        testSortOriginalPsuedorandom(123456789);
    }

    function testSortOriginalSorted() public {
        unchecked {
            uint256 n = 100;
            uint256[] memory a = new uint256[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = i;
            }
            _sortOriginal(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortOriginalReversed() public {
        unchecked {
            uint256 n = 100;
            uint256[] memory a = new uint256[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = 999 - i;
            }
            _sortOriginal(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortOriginalMostlySame() public {
        unchecked {
            uint256 n = 100;
            uint256[] memory a = new uint256[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = i % 8 == 0 ? i : 0;
            }
            _sortOriginal(a);
            assertTrue(_isSorted(a));
        }
    }

    function testUniquifySorted() public {
        uint256[] memory a = new uint256[](5);
        a[0] = 1;
        a[1] = 1;
        a[2] = 3;
        a[3] = 3;
        a[4] = 5;
        LibSort.uniquifySorted(a);
        assertTrue(_isSortedAndUniquified(a));
        assertEq(a.length, 3);
    }

    function testUniquifySortedWithEmptyArray() public {
        uint256[] memory a = new uint256[](0);
        LibSort.uniquifySorted(a);
        assertTrue(_isSortedAndUniquified(a));
        assertEq(a.length, 0);
    }

    function testUniquifySortedAddress() public {
        address[] memory a = new address[](10);
        a[0] = address(0x1efF47bc3a10a45D4B230B5d10E37751FE6AA718);
        a[1] = address(0x1efF47bc3a10a45D4B230B5d10E37751FE6AA718);
        a[2] = address(0x1efF47bC3A10a45d4b630B5D10E37751FE6aA718);
        a[3] = address(0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF);
        a[4] = address(0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69);
        a[5] = address(0x6813eb9362372Eef6200f3B1dbC3f819671cbA70);
        a[6] = address(0xe1AB8145F7E55DC933d51a18c793F901A3A0b276);
        a[7] = address(0xe1AB8145F7E55DC933d51a18c793F901A3A0b276);
        a[8] = address(0xE1Ab8145F7e55Dc933D61a18c793f901A3a0B276);
        a[9] = address(0xe1ab8145f7E55Dc933D61A18c793f901A3A0B288);
        LibSort.uniquifySorted(a);
        assertTrue(_isSortedAndUniquified(a));
        assertEq(a.length, 8);
    }

    function testUniquifySorted(uint256) public {
        uint256[] memory a = _randomUints(_randomArrayLength());
        LibSort.sort(a);
        LibSort.uniquifySorted(a);
        assertTrue(_isSortedAndUniquified(a));
    }

    function testUniquifySortedAddress(uint256) public {
        address[] memory a = _randomAddresses(_randomArrayLength());
        LibSort.sort(a);
        LibSort.uniquifySorted(a);
        assertTrue(_isSortedAndUniquified(a));
    }

    function testUniquifySortedDifferential(uint256) public {
        uint256 n = _randomArrayLength();
        uint256[] memory a = _randomUints(n);
        LibSort.sort(a);
        uint256[] memory aCopy = new uint256[](n);
        for (uint256 i; i != n; ++i) {
            aCopy[i] = a[i];
        }
        LibSort.uniquifySorted(a);
        _uniquifyOriginal(aCopy);
        assertEq(a, aCopy);
    }

    function testSearchSortedBasicCases() public {
        uint256[] memory a = new uint256[](6);
        a[0] = 0;
        a[1] = 1;
        a[2] = 2;
        a[3] = 3;
        a[4] = 4;
        a[5] = 5;
        (bool found, uint256 index) = LibSort.searchSorted(a, 2);
        assertTrue(found);
        assertEq(index, 2);

        a[0] = 0;
        a[1] = 1;
        a[2] = 2;
        a[3] = 3;
        a[4] = 4;
        a[5] = 5;
        (found, index) = LibSort.searchSorted(a, 5);
        assertTrue(found);
        assertEq(index, 5);
    }

    function testSearchSortedEdgeCases() public {
        uint256[] memory a = new uint256[](1);
        a[0] = 2;
        (bool found, uint256 index) = LibSort.searchSorted(a, 1);
        assertFalse(found);

        a = new uint256[](2);
        a[0] = 45;
        a[1] = 46;
        (found, index) = LibSort.searchSorted(a, 2);
        assertFalse(found);
    }

    function testSearchSortedWithEmptyArray() public {
        uint256[] memory a = new uint256[](0);
        (bool found, uint256 index) = LibSort.searchSorted(a, 1);
        assertFalse(found);
        assertEq(index, 0);
    }

    function testSearchSortedElementNotInArray() public {
        uint256[] memory a = new uint256[](5);
        a[0] = 1;
        a[1] = 2;
        a[2] = 3;
        a[3] = 4;
        a[4] = 5;
        (bool found, uint256 index) = LibSort.searchSorted(a, 0);
        assertFalse(found);
        assertEq(index, 0);

        a[0] = 15;
        a[1] = 25;
        a[2] = 35;
        a[3] = 45;
        a[4] = 55;
        (found, index) = LibSort.searchSorted(a, 10);
        assertFalse(found);
        assertEq(index, 0);
        (found, index) = LibSort.searchSorted(a, 20);
        assertFalse(found);
        assertEq(index, 0);
        (found, index) = LibSort.searchSorted(a, 30);
        assertFalse(found);
        assertEq(index, 1);
        (found, index) = LibSort.searchSorted(a, 40);
        assertFalse(found);
        assertEq(index, 2);
        (found, index) = LibSort.searchSorted(a, 50);
        assertFalse(found);
        assertEq(index, 3);
        (found, index) = LibSort.searchSorted(a, 60);
        assertFalse(found);
        assertEq(index, 4);
    }

    function testSearchSortedElementInArray(uint256) public {
        unchecked {
            _misalignFreeMemoryPointer();
            uint256[] memory a = _randomUints(_randomNonZeroArrayLength());
            LibSort.sort(a);
            if (_randomChance(2)) {
                LibSort.uniquifySorted(a);
            }
            uint256 randomIndex = _random() % a.length;
            uint256 value = a[randomIndex];
            (bool found, uint256 index) = LibSort.searchSorted(a, value);
            if (_randomChance(16)) {
                assertEq(LibSort.inSorted(a, value), found);
            }
            assertTrue(found);
            assertEq(a[index], value);
        }
    }

    function testSearchSortedElementNotInArray(uint256) public {
        unchecked {
            _misalignFreeMemoryPointer();
            uint256[] memory a = _randomUints(_randomNonZeroArrayLength());
            LibSort.sort(a);
            if (_randomChance(2)) {
                LibSort.uniquifySorted(a);
            }
            uint256 randomIndex = _random() % a.length;
            uint256 missingValue;
            if (_randomChance(2)) {
                if (_randomChance(2)) {
                    missingValue = a[randomIndex] + 1;
                    if (missingValue == 0) return;
                } else {
                    missingValue = a[randomIndex] - 1;
                    if (missingValue == type(uint256).max) return;
                }
                if (_exists(a, missingValue)) return;
                (bool found, uint256 index) = LibSort.searchSorted(a, missingValue);
                assertFalse(found);
                assertEq(a[index], a[_nearestIndexBefore(a, missingValue)]);
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    mstore(0x00, missingValue)
                    missingValue := keccak256(0x00, 0x20)
                }
                (bool found,) = LibSort.searchSorted(a, missingValue);
                assertFalse(found);
            }
        }
    }

    function _exists(uint256[] memory a, uint256 x) internal pure returns (bool result) {
        unchecked {
            uint256 n = a.length;
            for (uint256 i; i != n; ++i) {
                if (a[i] == x) {
                    return true;
                }
            }
            return false;
        }
    }

    function _nearestIndexBefore(uint256[] memory a, uint256 x)
        internal
        pure
        returns (uint256 nearestIndex)
    {
        unchecked {
            uint256 nearestDist = type(uint256).max;
            uint256 n = a.length;
            for (uint256 i; i != n; ++i) {
                uint256 y = a[i];
                if (y > x) continue;
                uint256 dist = x - y;
                if (dist < nearestDist) {
                    nearestIndex = i;
                    nearestDist = dist;
                }
            }
        }
    }

    function testSearchSorted() public {
        unchecked {
            uint256 n = 100;
            uint256[] memory a = new uint256[](n);
            for (uint256 i; i != n; i++) {
                a[i] = i;
            }
            for (uint256 i; i != n; i++) {
                (bool found, uint256 index) = LibSort.searchSorted(a, i);
                assertTrue(found);
                assertEq(index, i);
            }
        }
    }

    function testSearchSortedDifferential(uint256) public {
        uint256[] memory a = _randomUints(_randomArrayLength());
        uint256 needle = _random();
        if (_randomChance(2) && a.length != 0) {
            needle = a[_random() % a.length];
        }
        (bool found, uint256 index) = LibSort.searchSorted(a, needle);
        if (found) {
            assertEq(a[index], needle);
        }
        LibSort.sort(a);
        (found, index) = LibSort.searchSorted(a, needle);
        assertEq(found, _exists(a, needle));
        if (found) {
            assertEq(a[index], needle);
        }
    }

    function testSearchSortedInts() public {
        unchecked {
            uint256 n = 100;
            int256[] memory a = new int256[](n);
            for (uint256 i = 0; i != n; i++) {
                a[i] = int256(i) - 50;
            }
            for (uint256 i; i != n; i++) {
                (bool found, uint256 index) = LibSort.searchSorted(a, int256(i) - 50);
                assertTrue(found);
                assertEq(index, i);
            }
        }
    }

    function testSearchSortedInts(int256[] memory a, int256 needle) public {
        (bool found, uint256 index) = LibSort.searchSorted(a, needle);
        if (found) {
            assertEq(a[index], needle);
        }
    }

    function testSearchSortedAddresses() public {
        unchecked {
            uint256 n = 100;
            address[] memory a = new address[](n);
            for (uint256 i; i != n; i++) {
                a[i] = address(uint160(i));
            }
            for (uint256 i; i != n; i++) {
                (bool found, uint256 index) = LibSort.searchSorted(a, address(uint160(i)));
                assertTrue(found);
                assertEq(index, i);
                (found,) = LibSort.searchSorted(a, address(uint160(i + n)));
                assertFalse(found);
            }
        }
    }

    function testInsertionSortInts() public {
        unchecked {
            for (uint256 t; t != 16; ++t) {
                int256[] memory a = _randomInts(_bound(_random(), 0, 8));
                LibSort.insertionSort(a);
                assertTrue(_isSorted(a));
            }
        }
    }

    function testSortInts() public {
        unchecked {
            for (uint256 t; t != 16; ++t) {
                int256[] memory a = _randomInts(_bound(_random(), 0, 64));
                LibSort.insertionSort(a);
                assertTrue(_isSorted(a));
            }
        }
    }

    function testTwoComplementConversionSort(int256 a, int256 b) public {
        uint256 w = 1 << 255;
        /// @solidity memory-safe-assembly
        assembly {
            let aConverted := add(a, w)
            let bConverted := add(b, w)
            if iszero(lt(aConverted, bConverted)) {
                let t := aConverted
                aConverted := bConverted
                bConverted := t
            }
            a := add(aConverted, w)
            b := add(bConverted, w)
        }
        assertTrue(a <= b);
    }

    function testReverse() public {
        unchecked {
            for (uint256 t; t != 16; ++t) {
                uint256 n = _bound(_random(), 0, 8);
                uint256[] memory a = new uint256[](n);
                uint256[] memory reversed = new uint256[](n);
                for (uint256 i; i != n; ++i) {
                    reversed[n - 1 - i] = (a[i] = _random());
                }
                bytes32 originalHash = keccak256(abi.encode(a));
                LibSort.reverse(a);
                assertEq(a, reversed);
                LibSort.reverse(a);
                assertEq(originalHash, keccak256(abi.encode(a)));
            }
        }
    }

    function testCopy(uint256) public {
        unchecked {
            uint256[] memory a;
            if (!_randomChance(32)) a = _randomUints(_random() % 4);
            if (_randomChance(32)) _brutalizeMemory();
            uint256[] memory aCopy = LibSort.copy(a);
            if (_randomChance(32)) _brutalizeMemory();
            assertEq(aCopy, a);
            for (uint256 i; i != a.length; ++i) {
                aCopy[i] *= 2;
            }
            for (uint256 i; i != a.length; ++i) {
                assertEq(aCopy[i], a[i] * 2);
            }
        }
    }

    function testSortedUnionDifferential(uint256) public {
        (uint256[] memory a, uint256[] memory b) = _randomUintsPair();
        uint256[] memory c = LibSort.union(a, b);
        assertTrue(_isSorted(c));
        assertEq(c, _unionOriginal(a, b));
    }

    function testSortedUnionDifferential() public {
        unchecked {
            for (uint256 t; t != 16; ++t) {
                testSortedUnionDifferential(t);
            }
        }
    }

    function testSortedUnionDifferentialInt(uint256) public {
        (int256[] memory a, int256[] memory b) = _randomIntsPair();
        int256[] memory c = LibSort.union(a, b);
        assertTrue(_isSorted(c));
        assertEq(c, _unionOriginal(a, b));
    }

    function testSortedIntersectionDifferential(uint256) public {
        (uint256[] memory a, uint256[] memory b) = _randomUintsPair();
        uint256[] memory c = LibSort.intersection(a, b);
        assertTrue(_isSorted(c));
        assertEq(c, _intersectionOriginal(a, b));
    }

    function testSortedIntersectionDifferential() public {
        unchecked {
            for (uint256 t; t != 16; ++t) {
                testSortedIntersectionDifferential(t);
            }
        }
    }

    function testSortedIntersectionDifferentialInt(uint256) public {
        (int256[] memory a, int256[] memory b) = _randomIntsPair();
        int256[] memory c = LibSort.intersection(a, b);
        assertTrue(_isSorted(c));
        assertEq(c, _intersectionOriginal(a, b));
    }

    function testSortedDifferenceDifferential(uint256) public {
        (uint256[] memory a, uint256[] memory b) = _randomUintsPair();
        uint256[] memory c = LibSort.difference(a, b);
        assertTrue(_isSorted(c));
        assertEq(c, _differenceOriginal(a, b));
    }

    function testSortedDifferenceDifferential() public {
        unchecked {
            for (uint256 t; t != 16; ++t) {
                testSortedDifferenceDifferential(t);
            }
        }
    }

    function testSortedDifferenceDifferentialInt(uint256) public {
        (int256[] memory a, int256[] memory b) = _randomIntsPair();
        int256[] memory c = LibSort.difference(a, b);
        assertTrue(_isSorted(c));
        assertEq(c, _differenceOriginal(a, b));
    }

    function testSortedDifferenceUnionIntersection(uint256) public {
        unchecked {
            bool found;
            (uint256[] memory a, uint256[] memory b) = _randomUintsPair();

            uint256[] memory aSubB = LibSort.difference(a, b);
            assertTrue(_isSorted(aSubB));
            for (uint256 i; i != aSubB.length; ++i) {
                (found,) = LibSort.searchSorted(a, aSubB[i]);
                assertTrue(found);
                (found,) = LibSort.searchSorted(b, aSubB[i]);
                assertFalse(found);
            }
            for (uint256 i; i != b.length; ++i) {
                (found,) = LibSort.searchSorted(aSubB, b[i]);
                assertFalse(found);
            }

            uint256[] memory bSubA = LibSort.difference(b, a);
            assertTrue(_isSorted(bSubA));
            for (uint256 i; i != bSubA.length; ++i) {
                (found,) = LibSort.searchSorted(b, bSubA[i]);
                assertTrue(found);
                (found,) = LibSort.searchSorted(a, bSubA[i]);
                assertFalse(found);
            }
            for (uint256 i; i != a.length; ++i) {
                (found,) = LibSort.searchSorted(bSubA, a[i]);
                assertFalse(found);
            }

            uint256[] memory aIntersectionB = LibSort.intersection(a, b);
            for (uint256 i; i != aIntersectionB.length; ++i) {
                (found,) = LibSort.searchSorted(b, aIntersectionB[i]);
                assertTrue(found);
                (found,) = LibSort.searchSorted(a, aIntersectionB[i]);
                assertTrue(found);
            }

            uint256[] memory aUnionB = LibSort.union(a, b);
            uint256[] memory aSubBUnionBSubA = LibSort.union(aSubB, bSubA);
            uint256[] memory emptySet;
            assertEq(emptySet, LibSort.intersection(aSubB, bSubA));
            assertEq(emptySet, LibSort.intersection(aSubBUnionBSubA, aIntersectionB));
            assertEq(a, LibSort.union(aIntersectionB, aSubB));
            assertEq(b, LibSort.union(aIntersectionB, bSubA));
            assertEq(aIntersectionB, LibSort.intersection(b, a));
            assertEq(aUnionB, LibSort.union(b, a));
            assertEq(LibSort.union(aSubB, b), LibSort.union(b, aSubB));
            assertEq(LibSort.union(bSubA, a), LibSort.union(a, bSubA));
            assertEq(aUnionB, LibSort.union(aSubBUnionBSubA, aIntersectionB));
        }
    }

    function testIsSortedDifferential(uint256) public {
        unchecked {
            uint256 n = _randomChance(2) ? _random() % 4 : _randomArrayLength();
            uint256[] memory a = new uint256[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = _random() % 4;
            }
            assertEq(LibSort.isSorted(a), _isSorted(a));
            LibSort.sort(a);
            assertEq(LibSort.isSorted(a), _isSorted(a));
            if (n != 0) {
                a[_random() % n] = 0;
                if (_randomChance(2)) {
                    a[_random() % n] = a[_random() % n];
                }
            }
            assertEq(LibSort.isSorted(a), _isSorted(a));
        }
    }

    function testIsSortedIntsDifferential(uint256) public {
        unchecked {
            uint256 n = _randomChance(2) ? _random() % 4 : _randomArrayLength();
            int256[] memory a = new int256[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = int256(_random() % 4);
                if (_randomChance(2)) {
                    a[i] = -a[i];
                }
            }
            assertEq(LibSort.isSorted(a), _isSorted(a));
            LibSort.sort(a);
            assertEq(LibSort.isSorted(a), _isSorted(a));
            if (n != 0) {
                a[_random() % n] = 0;
                if (_randomChance(2)) {
                    a[_random() % n] = a[_random() % n];
                }
            }
            assertEq(LibSort.isSorted(a), _isSorted(a));
        }
    }

    function testIsSortedAddressesDifferential(uint256) public {
        unchecked {
            uint256 n = _randomChance(2) ? _random() % 4 : _randomArrayLength();
            address[] memory a = new address[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = address(uint160(_random() % 4));
            }
            assertEq(LibSort.isSorted(a), _isSorted(a));
            LibSort.sort(a);
            assertEq(LibSort.isSorted(a), _isSorted(a));
            if (n != 0) {
                a[_random() % n] = address(0);
                if (_randomChance(2)) {
                    a[_random() % n] = a[_random() % n];
                }
            }
            assertEq(LibSort.isSorted(a), _isSorted(a));
        }
    }

    function testIsSortedAndUniquifiedDifferential(uint256) public {
        unchecked {
            uint256 n = _randomChance(2) ? _random() % 4 : _randomArrayLength();
            uint256[] memory a = new uint256[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = _random() % 4;
            }
            assertEq(LibSort.isSortedAndUniquified(a), _isSortedAndUniquified(a));
            LibSort.sort(a);
            assertEq(LibSort.isSortedAndUniquified(a), _isSortedAndUniquified(a));
            if (n != 0) {
                a[_random() % n] = 0;
                if (_randomChance(2)) {
                    a[_random() % n] = a[_random() % n];
                }
            }
            assertEq(LibSort.isSortedAndUniquified(a), _isSortedAndUniquified(a));
        }
    }

    function testIsSortedAndUniquifiedIntsDifferential(uint256) public {
        unchecked {
            uint256 n = _randomChance(2) ? _random() % 4 : _randomArrayLength();
            int256[] memory a = new int256[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = int256(_random() % 4);
                if (_randomChance(2)) {
                    a[i] = -a[i];
                }
            }
            assertEq(LibSort.isSortedAndUniquified(a), _isSortedAndUniquified(a));
            LibSort.sort(a);
            assertEq(LibSort.isSortedAndUniquified(a), _isSortedAndUniquified(a));
            if (n != 0) {
                a[_random() % n] = 0;
                if (_randomChance(2)) {
                    a[_random() % n] = a[_random() % n];
                }
            }
            assertEq(LibSort.isSortedAndUniquified(a), _isSortedAndUniquified(a));
        }
    }

    function testIsSortedAndUniquifiedAddressesDifferential(uint256) public {
        unchecked {
            uint256 n = _randomChance(2) ? _random() % 4 : _randomArrayLength();
            address[] memory a = new address[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = address(uint160(_random() % 4));
            }
            assertEq(LibSort.isSortedAndUniquified(a), _isSortedAndUniquified(a));
            LibSort.sort(a);
            assertEq(LibSort.isSortedAndUniquified(a), _isSortedAndUniquified(a));
            if (n != 0) {
                a[_random() % n] = address(0);
                if (_randomChance(2)) {
                    a[_random() % n] = a[_random() % n];
                }
            }
            assertEq(LibSort.isSortedAndUniquified(a), _isSortedAndUniquified(a));
        }
    }

    function _unionOriginal(uint256[] memory a, uint256[] memory b)
        private
        pure
        returns (uint256[] memory c)
    {
        unchecked {
            c = new uint256[](a.length + b.length);
            uint256 o;
            for (uint256 i; i != a.length; ++i) {
                c[o++] = a[i];
            }
            for (uint256 i; i != b.length; ++i) {
                c[o++] = b[i];
            }
            LibSort.insertionSort(c);
            LibSort.uniquifySorted(c);
        }
    }

    function _unionOriginal(int256[] memory a, int256[] memory b)
        private
        pure
        returns (int256[] memory c)
    {
        unchecked {
            c = new int256[](a.length + b.length);
            uint256 o;
            for (uint256 i; i != a.length; ++i) {
                c[o++] = a[i];
            }
            for (uint256 i; i != b.length; ++i) {
                c[o++] = b[i];
            }
            LibSort.insertionSort(c);
            LibSort.uniquifySorted(c);
        }
    }

    function _intersectionOriginal(uint256[] memory a, uint256[] memory b)
        private
        pure
        returns (uint256[] memory c)
    {
        unchecked {
            c = new uint256[](a.length + b.length);
            uint256 o;
            bool found;
            for (uint256 i; i != a.length; ++i) {
                (found,) = LibSort.searchSorted(b, a[i]);
                if (found) c[o++] = a[i];
            }
            /// @solidity memory-safe-assembly
            assembly {
                mstore(c, o)
            }
            LibSort.insertionSort(c);
            LibSort.uniquifySorted(c);
        }
    }

    function _intersectionOriginal(int256[] memory a, int256[] memory b)
        private
        pure
        returns (int256[] memory c)
    {
        unchecked {
            c = new int256[](a.length + b.length);
            uint256 o;
            bool found;
            for (uint256 i; i != a.length; ++i) {
                (found,) = LibSort.searchSorted(b, a[i]);
                if (found) c[o++] = a[i];
            }
            /// @solidity memory-safe-assembly
            assembly {
                mstore(c, o)
            }
            LibSort.insertionSort(c);
            LibSort.uniquifySorted(c);
        }
    }

    function _differenceOriginal(uint256[] memory a, uint256[] memory b)
        private
        pure
        returns (uint256[] memory c)
    {
        unchecked {
            c = new uint256[](a.length + b.length);
            uint256 o;
            bool found;
            for (uint256 i; i != a.length; ++i) {
                (found,) = LibSort.searchSorted(b, a[i]);
                if (!found) c[o++] = a[i];
            }
            /// @solidity memory-safe-assembly
            assembly {
                mstore(c, o)
            }
            LibSort.insertionSort(c);
            LibSort.uniquifySorted(c);
        }
    }

    function _differenceOriginal(int256[] memory a, int256[] memory b)
        private
        pure
        returns (int256[] memory c)
    {
        unchecked {
            c = new int256[](a.length + b.length);
            uint256 o;
            bool found;
            for (uint256 i; i != a.length; ++i) {
                (found,) = LibSort.searchSorted(b, a[i]);
                if (!found) c[o++] = a[i];
            }
            /// @solidity memory-safe-assembly
            assembly {
                mstore(c, o)
            }
            LibSort.insertionSort(c);
            LibSort.uniquifySorted(c);
        }
    }

    function _isSorted(address[] memory a) private pure returns (bool) {
        unchecked {
            for (uint256 i = 1; i < a.length; ++i) {
                if (a[i - 1] > a[i]) return false;
            }
            return true;
        }
    }

    function _isSorted(uint256[] memory a) private pure returns (bool) {
        unchecked {
            for (uint256 i = 1; i < a.length; ++i) {
                if (a[i - 1] > a[i]) return false;
            }
            return true;
        }
    }

    function _isSorted(int256[] memory a) private pure returns (bool) {
        unchecked {
            for (uint256 i = 1; i < a.length; ++i) {
                if (a[i - 1] > a[i]) return false;
            }
            return true;
        }
    }

    function _isSortedAndUniquified(uint256[] memory a) private pure returns (bool) {
        if (a.length == 0) {
            return true;
        }
        unchecked {
            uint256 end = a.length - 1;
            for (uint256 i = 0; i != end; ++i) {
                if (a[i] >= a[i + 1]) {
                    return false;
                }
            }
            return true;
        }
    }

    function _isSortedAndUniquified(int256[] memory a) private pure returns (bool) {
        if (a.length == 0) {
            return true;
        }
        unchecked {
            uint256 end = a.length - 1;
            for (uint256 i = 0; i != end; ++i) {
                if (a[i] >= a[i + 1]) {
                    return false;
                }
            }
            return true;
        }
    }

    function _isSortedAndUniquified(address[] memory a) private pure returns (bool) {
        if (a.length == 0) {
            return true;
        }
        unchecked {
            uint256 end = a.length - 1;
            for (uint256 i = 0; i != end; ++i) {
                if (a[i] >= a[i + 1]) {
                    return false;
                }
            }
            return true;
        }
    }

    function _sortOriginal(uint256[] memory a) internal pure {
        _sortOriginal(a, 0, int256(a.length - 1));
    }

    function _sortOriginal(uint256[] memory arr, int256 left, int256 right) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) {
                unchecked {
                    ++i;
                }
            }
            while (pivot < arr[uint256(j)]) {
                unchecked {
                    --j;
                }
            }
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                unchecked {
                    ++i;
                    --j;
                }
            }
        }
        if (left < j) _sortOriginal(arr, left, j);
        if (i < right) _sortOriginal(arr, i, right);
    }

    function _copy(uint256[] memory a) private view returns (uint256[] memory b) {
        /// @solidity memory-safe-assembly
        assembly {
            b := mload(0x40)
            let n := add(shl(5, mload(a)), 0x20)
            pop(staticcall(gas(), 4, a, n, b, n))
            mstore(0x40, add(b, n))
        }
    }

    function _copy(int256[] memory a) private view returns (int256[] memory b) {
        /// @solidity memory-safe-assembly
        assembly {
            b := mload(0x40)
            let n := add(shl(5, mload(a)), 0x20)
            pop(staticcall(gas(), 4, a, n, b, n))
            mstore(0x40, add(b, n))
        }
    }

    function _copy(address[] memory a) private view returns (address[] memory b) {
        /// @solidity memory-safe-assembly
        assembly {
            b := mload(0x40)
            let n := add(shl(5, mload(a)), 0x20)
            pop(staticcall(gas(), 4, a, n, b, n))
            mstore(0x40, add(b, n))
        }
    }

    function _randomUints(uint256 n) private returns (uint256[] memory a) {
        unchecked {
            _misalignFreeMemoryPointer();
            /// @solidity memory-safe-assembly
            assembly {
                a := mload(0x40)
                mstore(a, n)
                mstore(0x40, add(add(0x20, a), shl(5, n)))
            }
            for (uint256 i; i != n; ++i) {
                a[i] = _random();
            }
        }
    }

    function _randomAddresses(uint256 n) private returns (address[] memory a) {
        unchecked {
            _misalignFreeMemoryPointer();
            /// @solidity memory-safe-assembly
            assembly {
                a := mload(0x40)
                mstore(a, n)
                mstore(0x40, add(add(0x20, a), shl(5, n)))
            }
            for (uint256 i; i != n; ++i) {
                a[i] = address(uint160(_random()));
            }
        }
    }

    function _randomInts(uint256 n) private returns (int256[] memory a) {
        unchecked {
            uint256[] memory aRaw = _randomUints(n);
            /// @solidity memory-safe-assembly
            assembly {
                a := aRaw
            }
        }
    }

    function _uniquifyOriginal(uint256[] memory a) private pure {
        if (a.length != 0) {
            unchecked {
                uint256 n = a.length;
                uint256 i = 0;
                for (uint256 j = 1; j < n; j++) {
                    if (a[i] != a[j]) {
                        i++;
                        a[i] = a[j];
                    }
                }
                /// @solidity memory-safe-assembly
                assembly {
                    mstore(a, add(i, 1))
                }
            }
        }
    }

    function _randomUintsPair() private returns (uint256[] memory a, uint256[] memory b) {
        uint256 r = _random();
        a = _randomUints(r & 7);
        b = _randomUints((r >> 128) & 7);
        LibSort.insertionSort(a);
        LibSort.uniquifySorted(a);
        LibSort.insertionSort(b);
        LibSort.uniquifySorted(b);
    }

    function _randomAddressesPair() private returns (address[] memory a, address[] memory b) {
        uint256 r = _random();
        a = _randomAddresses(r & 7);
        b = _randomAddresses((r >> 128) & 7);
        LibSort.insertionSort(a);
        LibSort.uniquifySorted(a);
        LibSort.insertionSort(b);
        LibSort.uniquifySorted(b);
    }

    function _randomIntsPair() private returns (int256[] memory a, int256[] memory b) {
        uint256 r = _random();
        a = _randomInts(r & 7);
        b = _randomInts((r >> 128) & 7);
        LibSort.insertionSort(a);
        LibSort.uniquifySorted(a);
        LibSort.insertionSort(b);
        LibSort.uniquifySorted(b);
    }

    function _randomArrayLength() internal returns (uint256 r) {
        r = _random();
        /// @solidity memory-safe-assembly
        assembly {
            let m := 0x070707070707070707070707070707070f0f0f0f0f0f0f1f1f1f1f1f1f3f7fff
            r := and(byte(1, r), byte(and(r, 31), m))
        }
    }

    function _randomNonZeroArrayLength() internal returns (uint256 r) {
        do {
            r = _randomArrayLength();
        } while (r == 0);
    }

    function testClean(uint256 n) public {
        address[] memory a;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, n)
            n := and(n, 7)
            a := mload(0x40)
            mstore(a, n)
            for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                mstore(0x20, i)
                mstore(add(add(a, 0x20), shl(5, i)), keccak256(0x00, 0x40))
            }
            mstore(0x40, add(add(a, 0x20), shl(5, n)))
        }
        address[] memory aCopy = LibSort.copy(a);
        assertEq(a, aCopy);
        LibSort.clean(a);
        assertEq(a, aCopy);
        assertEq(a.length, n);
        uint256 orAll;
        /// @solidity memory-safe-assembly
        assembly {
            for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                mstore(0x20, i)
                orAll := or(orAll, mload(add(add(a, 0x20), shl(5, i))))
            }
        }
        assertEq(orAll >> 160, 0);
    }
}
