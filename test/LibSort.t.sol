// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import "src/utils/LibSort.sol";

contract LibSortTest is TestPlus {
    function testInsertionSortAddressesDifferential(uint256[] memory aRaw) public {
        unchecked {
            _boundArrayLength(aRaw, 32);
            address[] memory a = new address[](aRaw.length);
            for (uint256 i; i < a.length; ++i) {
                address addr;
                uint256 addrRaw = aRaw[i];
                /// @solidity memory-safe-assembly
                assembly {
                    addr := addrRaw
                }
                a[i] = addr;
            }
            // Make a copy of the `a` and perform insertion sort on it.
            address[] memory aCopy = new address[](a.length);
            for (uint256 i = 0; i < a.length; ++i) {
                aCopy[i] = a[i];
            }
            for (uint256 i = 1; i < aCopy.length; ++i) {
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
            uint256[] memory a = new uint256[](32);
            for (uint256 i; i < a.length; ++i) {
                a[i] = _random();
            }
            LibSort.insertionSort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testInsertionSortPsuedorandom() public {
        testInsertionSortPsuedorandom(123456789);
    }

    function testSortChecksumed(uint256[] memory a) public {
        unchecked {
            _boundArrayLength(a, 2048);
            uint256 checksum;
            for (uint256 i = 0; i < a.length; ++i) {
                checksum += a[i];
            }
            LibSort.sort(a);
            uint256 checksumAfterSort;
            for (uint256 i = 0; i < a.length; ++i) {
                checksumAfterSort += a[i];
            }
            assertEq(checksum, checksumAfterSort);
            assertTrue(_isSorted(a));
        }
    }

    function testSortDifferential(uint256[] memory a) public {
        unchecked {
            _boundArrayLength(a, 128);
            // Make a copy of the `a` and perform insertion sort on it.
            uint256[] memory aCopy = new uint256[](a.length);
            for (uint256 i = 0; i < a.length; ++i) {
                aCopy[i] = a[i];
            }
            LibSort.insertionSort(aCopy);
            LibSort.sort(a);
            assertEq(a, aCopy);
        }
    }

    function testSort(uint256[] memory a) public {
        unchecked {
            _boundArrayLength(a, 2048);
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
            uint256[] memory a = new uint256[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = _random();
            }
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
            uint256[] memory a = new uint256[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = i;
            }
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortReversed() public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = 999 - i;
            }
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortMostlySame() public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = i % 8 == 0 ? i : 0;
            }
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortTestOverhead() public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            uint256 mask = (1 << 128) - 1;
            for (uint256 i; i < a.length; ++i) {
                a[i] = (i << 128) | (_random() & mask);
            }
            assertTrue(_isSorted(a));
        }
    }

    function testSortAddressesPsuedorandomBrutalizeUpperBits() public {
        unchecked {
            address[] memory a = new address[](100);
            for (uint256 i; i < a.length; ++i) {
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

    function testSortAddressesDifferential(uint256[] memory aRaw) public {
        unchecked {
            _boundArrayLength(aRaw, 128);
            address[] memory a = new address[](aRaw.length);
            for (uint256 i; i < a.length; ++i) {
                address addr;
                uint256 addrRaw = aRaw[i];
                /// @solidity memory-safe-assembly
                assembly {
                    addr := addrRaw
                }
                a[i] = addr;
            }
            // Make a copy of the `a` and perform insertion sort on it.
            address[] memory aCopy = new address[](a.length);
            for (uint256 i = 0; i < a.length; ++i) {
                aCopy[i] = a[i];
            }
            LibSort.insertionSort(aCopy);
            LibSort.sort(a);
            assertEq(a, aCopy);
        }
    }

    function testSortAddressesPsuedorandom(uint256) public {
        unchecked {
            address[] memory a = new address[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = address(uint160(_random()));
            }
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortAddressesPsuedorandom() public {
        testSortAddressesPsuedorandom(123456789);
    }

    function testSortAddressesSorted() public {
        unchecked {
            address[] memory a = new address[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = address(uint160(i));
            }
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortAddressesReversed() public {
        unchecked {
            address[] memory a = new address[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = address(uint160(999 - i));
            }
            LibSort.sort(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortOriginalPsuedorandom(uint256) public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            for (uint256 i; i < a.length; ++i) {
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
            uint256[] memory a = new uint256[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = i;
            }
            _sortOriginal(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortOriginalReversed() public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = 999 - i;
            }
            _sortOriginal(a);
            assertTrue(_isSorted(a));
        }
    }

    function testSortOriginalMostlySame() public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            for (uint256 i; i < a.length; ++i) {
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

    function testUniquifySorted(uint256[] memory a) public {
        _boundArrayLength(a, 256);
        LibSort.sort(a);
        LibSort.uniquifySorted(a);
        assertTrue(_isSortedAndUniquified(a));
    }

    function testUniquifySortedAddress(address[] memory a) public {
        _boundArrayLength(a, 256);
        LibSort.sort(a);
        LibSort.uniquifySorted(a);
        assertTrue(_isSortedAndUniquified(a));
    }

    function testUniquifySortedDifferential(uint256[] memory a) public {
        _boundArrayLength(a, 256);
        LibSort.sort(a);
        uint256[] memory aCopy = new uint256[](a.length);
        for (uint256 i = 0; i < a.length; ++i) {
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

    function testSearchSortedElementInArray(uint256[] memory a, uint256 randomness) public {
        unchecked {
            vm.assume(a.length != 0);
            LibSort.sort(a);
            uint256 randomIndex = randomness % a.length;
            uint256 value = a[randomIndex];
            (bool found, uint256 index) = LibSort.searchSorted(a, value);
            assertTrue(found);
            assertEq(a[index], value);
        }
    }

    function testSearchSortedElementInUniquifiedArray(uint256[] memory a, uint256 randomness)
        public
    {
        unchecked {
            vm.assume(a.length != 0);
            LibSort.sort(a);
            LibSort.uniquifySorted(a);
            uint256 expectedIndex = randomness % a.length;
            uint256 value = a[expectedIndex];
            (bool found, uint256 index) = LibSort.searchSorted(a, value);
            assertTrue(found);
            assertEq(index, expectedIndex);
        }
    }

    function testSearchSortedElementNotInArray(uint256[] memory a, uint256 randomness) public {
        unchecked {
            vm.assume(a.length != 0);
            LibSort.sort(a);

            uint256 randomIndex = randomness % a.length;
            uint256 value = a[randomIndex];
            if (value == type(uint256).max) return;

            for (uint256 i = randomIndex + 1; i < a.length; ++i) {
                if (a[i] != value) {
                    if (a[i] == value + 1) return;

                    (bool found, uint256 index) = LibSort.searchSorted(a, value + 1);
                    assertFalse(found);
                    assertEq(a[index], value);

                    return;
                }
            }
        }
    }

    function testSearchSortedElementNotInArrayNarrow(uint256[] memory a, uint256 randomness)
        public
    {
        unchecked {
            for (uint256 i; i != a.length; ++i) {
                a[i] = a[i] % 32;
            }
            testSearchSortedElementNotInArray(a, randomness);
        }
    }

    function testSearchSortedElementNotInUniquifiedArray(uint256[] memory a, uint256 randomness)
        public
    {
        unchecked {
            vm.assume(a.length != 0);
            LibSort.sort(a);
            LibSort.uniquifySorted(a);
            uint256 expectedIndex = randomness % a.length;
            uint256 value = a[expectedIndex];
            if (value == type(uint256).max) return;
            value = value + 1;
            if (expectedIndex + 1 < a.length) {
                if (a[expectedIndex + 1] == value) return;
            }
            (bool found, uint256 index) = LibSort.searchSorted(a, value);
            assertFalse(found);
            assertEq(index, expectedIndex);
        }
    }

    function testSearchSortedElementNotInUniquifiedArrayNarrow(
        uint256[] memory a,
        uint256 randomness
    ) public {
        unchecked {
            for (uint256 i; i != a.length; ++i) {
                a[i] = a[i] % 32;
            }
            testSearchSortedElementNotInUniquifiedArray(a, randomness);
        }
    }

    function testSearchSorted() public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            for (uint256 i = 0; i < 100; i++) {
                a[i] = i;
            }
            for (uint256 i = 0; i < 100; i++) {
                (bool found, uint256 index) = LibSort.searchSorted(a, i);
                assertTrue(found);
                assertEq(index, i);
            }
        }
    }

    function testSearchSortedOnRandomArrays(uint256[] memory a, uint256 needle) public {
        (bool found, uint256 index) = LibSort.searchSorted(a, needle);
        if (found) {
            assertEq(a[index], needle);
        }
    }

    function testInsertionSortInts() public {
        unchecked {
            for (uint256 t; t != 16; ++t) {
                int256[] memory a = _getRandomInts(_bound(_random(), 0, 8));
                LibSort.insertionSort(a);
                assertTrue(_isSorted(a));
            }
        }
    }

    function testSortInts() public {
        unchecked {
            for (uint256 t; t != 16; ++t) {
                int256[] memory a = _getRandomInts(_bound(_random(), 0, 64));
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
            for (uint256 t; t != 256; ++t) {
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

    function _getRandomInts(uint256 n) private view returns (int256[] memory a) {
        unchecked {
            uint256[] memory aRaw = new uint256[](n);
            for (uint256 i; i != n; ++i) {
                aRaw[i] = _random();
            }
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

    function _boundArrayLength(uint256[] memory a, uint256 n) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(mload(a), n)) { mstore(a, n) }
        }
    }

    function _boundArrayLength(address[] memory a, uint256 n) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(mload(a), n)) { mstore(a, n) }
        }
    }
}
