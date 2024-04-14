// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {EnumerableSetLib} from "../src/utils/EnumerableSetLib.sol";
import {LibSort} from "../src/utils/LibSort.sol";
import {LibPRNG} from "../src/utils/LibPRNG.sol";

contract EnumerableSetLibTest is SoladyTest {
    using EnumerableSetLib for *;
    using LibPRNG for *;

    uint256 private constant _ZERO_SENTINEL = 0xfbb67fda52d4bfb8bf;

    EnumerableSetLib.AddressSet addressSet;
    EnumerableSetLib.AddressSet addressSet2;

    function testEnumerableAddressSetNoStorageCollision() public {
        addressSet.add(address(1));
        assertEq(addressSet2.contains(address(1)), false);
        addressSet2.add(address(2));
        assertEq(addressSet.contains(address(1)), true);
        assertEq(addressSet2.contains(address(1)), false);
        assertEq(addressSet.contains(address(2)), false);
        addressSet.add(address(2));
        assertEq(addressSet.contains(address(2)), true);
        assertEq(addressSet2.contains(address(1)), false);
        addressSet2.add(address(1));
        assertEq(addressSet.contains(address(2)), true);
        assertEq(addressSet2.contains(address(1)), true);
    }

    function testEnumerableAddressSetBasic() public {
        assertEq(addressSet.length(), 0);
        assertEq(addressSet.contains(address(1)), false);
        assertEq(addressSet.contains(address(2)), false);
        assertEq(addressSet.contains(address(3)), false);
        assertEq(addressSet.contains(address(4)), false);
        assertEq(addressSet.contains(address(5)), false);

        assertTrue(addressSet.add(address(1)));
        assertFalse(addressSet.add(address(1)));

        assertEq(addressSet.length(), 1);
        assertEq(addressSet.contains(address(1)), true);
        assertEq(addressSet.contains(address(2)), false);
        assertEq(addressSet.contains(address(3)), false);
        assertEq(addressSet.contains(address(4)), false);
        assertEq(addressSet.contains(address(5)), false);

        assertTrue(addressSet.add(address(2)));
        assertFalse(addressSet.add(address(2)));

        assertEq(addressSet.length(), 2);
        assertEq(addressSet.contains(address(1)), true);
        assertEq(addressSet.contains(address(2)), true);
        assertEq(addressSet.contains(address(3)), false);
        assertEq(addressSet.contains(address(4)), false);
        assertEq(addressSet.contains(address(5)), false);

        assertTrue(addressSet.add(address(3)));
        assertFalse(addressSet.add(address(3)));

        assertEq(addressSet.length(), 3);
        assertEq(addressSet.contains(address(1)), true);
        assertEq(addressSet.contains(address(2)), true);
        assertEq(addressSet.contains(address(3)), true);
        assertEq(addressSet.contains(address(4)), false);
        assertEq(addressSet.contains(address(5)), false);

        assertTrue(addressSet.add(address(4)));
        assertFalse(addressSet.add(address(4)));

        assertEq(addressSet.length(), 4);
        assertEq(addressSet.contains(address(1)), true);
        assertEq(addressSet.contains(address(2)), true);
        assertEq(addressSet.contains(address(3)), true);
        assertEq(addressSet.contains(address(4)), true);
        assertEq(addressSet.contains(address(5)), false);

        assertTrue(addressSet.add(address(5)));
        assertFalse(addressSet.add(address(5)));

        assertEq(addressSet.length(), 5);
        assertEq(addressSet.contains(address(1)), true);
        assertEq(addressSet.contains(address(2)), true);
        assertEq(addressSet.contains(address(3)), true);
        assertEq(addressSet.contains(address(4)), true);
        assertEq(addressSet.contains(address(5)), true);
    }

    function testEnumerableAddressSetBasic2() public {
        addressSet.add(address(1));
        addressSet.add(address(2));

        addressSet.remove(address(1));
        assertEq(addressSet.length(), 1);
        addressSet.remove(address(2));
        assertEq(addressSet.length(), 0);

        addressSet.add(address(1));
        addressSet.add(address(2));

        addressSet.remove(address(2));
        assertEq(addressSet.length(), 1);
        addressSet.remove(address(1));
        assertEq(addressSet.length(), 0);

        addressSet.add(address(1));
        addressSet.add(address(2));
        addressSet.add(address(3));

        addressSet.remove(address(3));
        assertEq(addressSet.length(), 2);
        addressSet.remove(address(2));
        assertEq(addressSet.length(), 1);
        addressSet.remove(address(1));
        assertEq(addressSet.length(), 0);

        addressSet.add(address(1));
        addressSet.add(address(2));
        addressSet.add(address(3));

        addressSet.remove(address(1));
        assertEq(addressSet.length(), 2);
        addressSet.remove(address(2));
        assertEq(addressSet.length(), 1);
        addressSet.remove(address(3));
        assertEq(addressSet.length(), 0);
    }

    function testEnumerableAddressSetFuzz(uint256 n) public {
        unchecked {
            LibPRNG.PRNG memory prng;
            prng.state = n;
            uint256[] memory additions = new uint256[](prng.next() % 16);

            for (uint256 i; i != additions.length; ++i) {
                uint256 x = prng.next() & 7;
                additions[i] = x;
                addressSet.add(_brutalized(address(uint160(x))));
                assertTrue(addressSet.contains(_brutalized(address(uint160(x)))));
            }
            LibSort.sort(additions);
            LibSort.uniquifySorted(additions);
            assertEq(addressSet.length(), additions.length);
            {
                address[] memory values = addressSet.values();
                uint256[] memory valuesCasted = _toUints(values);
                LibSort.sort(valuesCasted);
                assertEq(valuesCasted, additions);
            }

            uint256[] memory removals = new uint256[](prng.next() % 16);
            for (uint256 i; i != removals.length; ++i) {
                uint256 x = prng.next() & 7;
                removals[i] = x;
                addressSet.remove(_brutalized(address(uint160(x))));
                assertFalse(addressSet.contains(_brutalized(address(uint160(x)))));
            }
            LibSort.sort(removals);
            LibSort.uniquifySorted(removals);

            {
                uint256[] memory difference = LibSort.difference(additions, removals);
                address[] memory values = addressSet.values();
                if (_random() % 8 == 0) _checkAddressSetValues(values);
                uint256[] memory valuesCasted = _toUints(values);
                LibSort.sort(valuesCasted);
                assertEq(valuesCasted, difference);
            }
        }
    }

    function _checkAddressSetValues(address[] memory values) internal {
        unchecked {
            for (uint256 i; i != values.length; ++i) {
                assertEq(addressSet.at(i), values[i]);
            }
        }
    }

    function testEnumerableAddressRevertsOnSentinel(uint256) public {
        do {
            address a = address(uint160(_random()));
            if (_random() % 32 == 0) {
                a = address(uint160(_ZERO_SENTINEL));
            }
            uint256 r = _random() % 3;
            if (r == 0) {
                if (a == address(uint160(_ZERO_SENTINEL))) {
                    vm.expectRevert(EnumerableSetLib.ValueIsZeroSentinel.selector);
                }
                this.addToAddressSet(a);
            }
            if (r == 1) {
                if (a == address(uint160(_ZERO_SENTINEL))) {
                    vm.expectRevert(EnumerableSetLib.ValueIsZeroSentinel.selector);
                }
                this.addressSetContains(a);
            }
            if (r == 2) {
                if (a == address(uint160(_ZERO_SENTINEL))) {
                    vm.expectRevert(EnumerableSetLib.ValueIsZeroSentinel.selector);
                }
                this.removeFromAddressSet(a);
            }
        } while (_random() % 2 != 0);
    }

    function addToAddressSet(address a) public returns (bool) {
        return addressSet.add(a);
    }

    function addressSetContains(address a) public view returns (bool) {
        return addressSet.contains(a);
    }

    function removeFromAddressSet(address a) public returns (bool) {
        return addressSet.remove(a);
    }

    function _brutalized(address a) private view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, gas())
            result := or(shl(160, keccak256(0x00, 0x20)), a)
        }
    }

    function _toUints(address[] memory a) private pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := a
        }
    }
}
