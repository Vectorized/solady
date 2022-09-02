// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "src/utils/LibSort.sol";

contract LibSortTest is Test {
    function testSortChecksumed(uint256[] memory a) public {
        unchecked {
            vm.assume(a.length < 2048);
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
            assertTrue(isSorted(a));
        }
    }

    function testSortDifferential(uint256[] memory a) public {
        unchecked {
            vm.assume(a.length < 128);
            // Make a copy of the `a` and perform insertion sort on it.
            uint256[] memory aCopy = new uint256[](a.length);
            for (uint256 i = 0; i < a.length; ++i) {
                aCopy[i] = a[i];
            }
            for (uint256 i = 1; i < aCopy.length; ++i) {
                uint256 key = aCopy[i];
                uint256 j = i;
                while (j != 0 && aCopy[j - 1] > key) {
                    aCopy[j] = aCopy[j - 1];
                    --j;
                }
                aCopy[j] = key;
            }
            LibSort.sort(a);
            assertEq(a, aCopy);
        }
    }

    function testSort(uint256[] memory a) public {
        unchecked {
            vm.assume(a.length < 2048);
            LibSort.sort(a);
            assertTrue(isSorted(a));
        }
    }

    function testSortBasicCase() public {
        unchecked {
            uint256[] memory a = new uint256[](2);
            a[0] = 3;
            a[1] = 0;
            LibSort.sort(a);
            assertTrue(isSorted(a));
        }
    }

    function testSortPsuedorandom(uint256 lcg) public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            lcg ^= 1;
            for (uint256 i; i < a.length; ++i) {
                lcg = stepLCG(lcg);
                a[i] = lcg;
            }
            LibSort.sort(a);
            assertTrue(isSorted(a));
        }
    }

    function testSortPsuedorandom() public {
        testSortPsuedorandom(123456789);
    }

    function testSortPsuedorandomNonuniform(uint256 lcg) public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            lcg ^= 1;
            for (uint256 i; i < a.length; ++i) {
                lcg = stepLCG(lcg);
                a[i] = lcg << (i & 8 == 0 ? 128 : 0);
            }
            LibSort.sort(a);
            assertTrue(isSorted(a));
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
            assertTrue(isSorted(a));
        }
    }

    function testSortReversed() public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = 999 - i;
            }
            LibSort.sort(a);
            assertTrue(isSorted(a));
        }
    }

    function testSortMostlySame() public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = i % 8 == 0 ? i : 0;
            }
            LibSort.sort(a);
            assertTrue(isSorted(a));
        }
    }

    function testSortTestOverhead() public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            uint256 lcg = 123456789;
            for (uint256 i; i < a.length; ++i) {
                a[i] = (i << 128) | lcg;
                lcg = stepLCG(lcg);
            }
            assertTrue(isSorted(a));
        }
    }

    function testSortAddressesPsuedorandomBrutalizeUpperBits() public {
        unchecked {
            address[] memory a = new address[](100);
            uint256 lcg = 123456789;
            for (uint256 i; i < a.length; ++i) {
                address addr = address(uint160(lcg));
                lcg = stepLCG(lcg);
                assembly {
                    addr := or(addr, shl(160, lcg))
                }
                a[i] = addr;
                lcg = stepLCG(lcg);
            }
            LibSort.sort(a);
            assertTrue(isSorted(a));
        }
    }

    function testSortAddressesDifferential(uint256[] memory aRaw) public {
        unchecked {
            vm.assume(aRaw.length < 128);
            address[] memory a = new address[](aRaw.length);
            for (uint256 i; i < a.length; ++i) {
                address addr;
                uint256 addrRaw = aRaw[i];
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
            LibSort.sort(a);
            assertEq(a, aCopy);
        }
    }

    function testSortAddressesPsuedorandom(uint256 lcg) public {
        unchecked {
            address[] memory a = new address[](100);
            lcg ^= 1;
            for (uint256 i; i < a.length; ++i) {
                lcg = stepLCG(lcg);
                a[i] = address(uint160(lcg));
            }
            LibSort.sort(a);
            assertTrue(isSorted(a));
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
            assertTrue(isSorted(a));
        }
    }

    function testSortAddressesReversed() public {
        unchecked {
            address[] memory a = new address[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = address(uint160(999 - i));
            }
            LibSort.sort(a);
            assertTrue(isSorted(a));
        }
    }

    function testSortOriginalPsuedorandom(uint256 lcg) public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            lcg ^= 1;
            for (uint256 i; i < a.length; ++i) {
                lcg = stepLCG(lcg);
                a[i] = lcg;
            }
            sortOriginal(a);
            assertTrue(isSorted(a));
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
            sortOriginal(a);
            assertTrue(isSorted(a));
        }
    }

    function testSortOriginalReversed() public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = 999 - i;
            }
            sortOriginal(a);
            assertTrue(isSorted(a));
        }
    }

    function testSortOriginalMostlySame() public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = i % 8 == 0 ? i : 0;
            }
            sortOriginal(a);
            assertTrue(isSorted(a));
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
        assertTrue(isUniqueArray(a));
        assertEq(a.length, 3);
    }

    function testUniquifySortedWithEmptyArray() public {
        uint256[] memory a = new uint256[](0);
        LibSort.uniquifySorted(a);
        assertTrue(isUniqueArray(a));
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
        assertTrue(isUniqueArray(a));
        assertEq(a.length, 8);
    }

    function testFuzzUniquifySorted(uint256[] memory a) public {
        LibSort.sort(a);
        LibSort.uniquifySorted(a);
        assertTrue(isUniqueArray(a));
    }

    function testFuzzUniquifySortedAddress(address[] memory a) public {
        LibSort.sort(a);
        LibSort.uniquifySorted(a);
        assertTrue(isUniqueArray(a));
    }

    function testFuzzUniquifySortedDifferential(uint256[] memory a) public {
        LibSort.sort(a);
        uint256[] memory aCopy = new uint256[](a.length);
        for (uint256 i = 0; i < a.length; ++i) {
            aCopy[i] = a[i];
        }
        LibSort.uniquifySorted(a);
        removeDuplicate(aCopy);
        assertEq(a, aCopy);
    }

    function stepLCG(uint256 input) private pure returns (uint256 output) {
        unchecked {
            output = (input * 1664525 + 1013904223) & 0xFFFFFFFF;
        }
    }

    function isSorted(address[] memory a) private pure returns (bool) {
        unchecked {
            for (uint256 i = 1; i < a.length; ++i) {
                if (a[i - 1] > a[i]) return false;
            }
            return true;
        }
    }

    function isSorted(uint256[] memory a) private pure returns (bool) {
        unchecked {
            for (uint256 i = 1; i < a.length; ++i) {
                if (a[i - 1] > a[i]) return false;
            }
            return true;
        }
    }

    function isUniqueArray(uint256[] memory a) private pure returns (bool) {
        if (a.length == 0) {
            return true;
        }
        unchecked {
            uint256 len = a.length;
            for (uint256 i = 0; i < len - 1; i++) {
                if (a[i] >= a[i + 1]) {
                    return false;
                }
            }
            return true;
        }
    }

    function isUniqueArray(address[] memory a) private pure returns (bool) {
        if (a.length == 0) {
            return true;
        }
        unchecked {
            uint256 len = a.length;
            for (uint256 i = 0; i < len - 1; i++) {
                if (a[i] >= a[i + 1]) {
                    return false;
                }
            }
            return true;
        }
    }

    function sortOriginal(uint256[] memory a) internal pure {
        sortOriginal(a, 0, int256(a.length - 1));
    }

    function sortOriginal(
        uint256[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
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
        if (left < j) sortOriginal(arr, left, j);
        if (i < right) sortOriginal(arr, i, right);
    }

    function removeDuplicate(uint256[] memory a) private pure {
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
                assembly {
                    mstore(a, add(i, 1))
                }
            }
        }
    }
}
