// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {Sort} from "../src/utils/Sort.sol";

contract SortTest is Test {
    function testSortChecksumed(uint256[] memory a) public {
        unchecked {
            vm.assume(a.length < 2048);
            uint256 checksum;
            for (uint256 i = 0; i < a.length; ++i) {
                checksum += a[i];
            }
            Sort.sort(a);
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
            Sort.sort(a);
            assertEq(a, aCopy);
        }
    }

    function testSort(uint256[] memory a) public {
        unchecked {
            vm.assume(a.length < 2048);
            Sort.sort(a);
            assertTrue(isSorted(a));
        }
    }

    function testSortBasicCase() public {
        unchecked {
            uint256[] memory a = new uint256[](2);
            a[0] = 3;
            a[1] = 0;
            Sort.sort(a);
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
            Sort.sort(a);
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
            Sort.sort(a);
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
            Sort.sort(a);
            assertTrue(isSorted(a));
        }
    }

    function testSortReversed() public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = 999 - i;
            }
            Sort.sort(a);
            assertTrue(isSorted(a));
        }
    }

    function testSortMostlySame() public {
        unchecked {
            uint256[] memory a = new uint256[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = i % 8 == 0 ? i : 0;
            }
            Sort.sort(a);
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
            Sort.sort(a);
            assertTrue(isSorted(a));
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
            Sort.sort(a);
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
            Sort.sort(a);
            assertTrue(isSorted(a));
        }
    }

    function testSortAddressesReversed() public {
        unchecked {
            address[] memory a = new address[](100);
            for (uint256 i; i < a.length; ++i) {
                a[i] = address(uint160(999 - i));
            }
            Sort.sort(a);
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
}
