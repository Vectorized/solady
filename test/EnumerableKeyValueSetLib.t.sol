// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibSort} from "../src/utils/LibSort.sol";
import {LibPRNG} from "../src/utils/LibPRNG.sol";

import {
    EnumerableSetLib, EnumerableKeyValueSetLib
} from "../src/utils/EnumerableKeyValueSetLib.sol";

contract EnumerableKeyValueSetLibTest is SoladyTest {
    using EnumerableKeyValueSetLib for EnumerableKeyValueSetLib.KeyValueSet;
    using LibPRNG for *;

    address private constant _ZERO_SENTINEL = 0x0000000000000000000000fbb67FDa52D4Bfb8Bf;

    EnumerableKeyValueSetLib.KeyValueSet keyValueSet;
    EnumerableKeyValueSetLib.KeyValueSet keyValueSet2;

    function _createKeyValuePair(address key, uint96 value)
        internal
        pure
        returns (bytes32 keyValuePair)
    {
        /// @solidity memory-safe-assembly
        assembly {
            keyValuePair := or(shl(96, key), shr(160, shl(160, value)))
        }
    }

    function testEnumerableKeyValueSetNoStorageCollision() public {
        keyValueSet.add(_createKeyValuePair(address(1), 1));
        assertEq(keyValueSet2.contains(address(1)), false);
        keyValueSet2.add(_createKeyValuePair(address(2), 2));
        assertEq(keyValueSet.contains(address(1)), true);
        assertEq(keyValueSet2.contains(address(1)), false);
        assertEq(keyValueSet.contains(address(2)), false);
        keyValueSet.add(_createKeyValuePair(address(2), 2));
        assertEq(keyValueSet.contains(address(2)), true);
        assertEq(keyValueSet2.contains(address(1)), false);
        keyValueSet2.add(_createKeyValuePair(address(1), 1));
        assertEq(keyValueSet.contains(address(2)), true);
        assertEq(keyValueSet2.contains(address(1)), true);
    }

    function testEnumerableKeyValueSetBasic() public {
        bytes32[] memory data = new bytes32[](5);
        data[0] = _createKeyValuePair(address(0), 1);
        data[1] = _createKeyValuePair(address(2), 2);
        data[2] = _createKeyValuePair(address(3), 3);
        data[3] = _createKeyValuePair(address(4), 4);
        data[4] = _createKeyValuePair(address(5), 5);

        assertEq(keyValueSet.length(), 0);
        assertEq(keyValueSet.contains(address(0)), false);
        assertEq(keyValueSet.contains(address(2)), false);
        assertEq(keyValueSet.contains(address(3)), false);
        assertEq(keyValueSet.contains(address(4)), false);
        assertEq(keyValueSet.contains(address(5)), false);
        _assertKeyValueSetValues(data, 0);

        assertTrue(keyValueSet.add(_createKeyValuePair(address(0), 1)));
        assertFalse(keyValueSet.add(_createKeyValuePair(address(0), 1)));

        assertEq(keyValueSet.length(), 1);
        assertEq(keyValueSet.contains(address(0)), true);
        assertEq(keyValueSet.contains(address(2)), false);
        assertEq(keyValueSet.contains(address(3)), false);
        assertEq(keyValueSet.contains(address(4)), false);
        assertEq(keyValueSet.contains(address(5)), false);
        _assertKeyValueSetValues(data, 1);

        assertTrue(keyValueSet.add(_createKeyValuePair(address(2), 2)));
        assertFalse(keyValueSet.add(_createKeyValuePair(address(2), 2)));

        assertEq(keyValueSet.length(), 2);
        assertEq(keyValueSet.contains(address(0)), true);
        assertEq(keyValueSet.contains(address(2)), true);
        assertEq(keyValueSet.contains(address(3)), false);
        assertEq(keyValueSet.contains(address(4)), false);
        assertEq(keyValueSet.contains(address(5)), false);
        _assertKeyValueSetValues(data, 2);

        assertTrue(keyValueSet.add(_createKeyValuePair(address(3), 3)));
        assertFalse(keyValueSet.add(_createKeyValuePair(address(3), 3)));

        assertEq(keyValueSet.length(), 3);
        assertEq(keyValueSet.contains(address(0)), true);
        assertEq(keyValueSet.contains(address(2)), true);
        assertEq(keyValueSet.contains(address(3)), true);
        assertEq(keyValueSet.contains(address(4)), false);
        assertEq(keyValueSet.contains(address(5)), false);
        _assertKeyValueSetValues(data, 3);

        assertTrue(keyValueSet.add(_createKeyValuePair(address(4), 4)));
        assertFalse(keyValueSet.add(_createKeyValuePair(address(4), 4)));

        assertEq(keyValueSet.length(), 4);
        assertEq(keyValueSet.contains(address(0)), true);
        assertEq(keyValueSet.contains(address(2)), true);
        assertEq(keyValueSet.contains(address(3)), true);
        assertEq(keyValueSet.contains(address(4)), true);
        assertEq(keyValueSet.contains(address(5)), false);
        _assertKeyValueSetValues(data, 4);

        assertTrue(keyValueSet.add(_createKeyValuePair(address(5), 5)));
        assertFalse(keyValueSet.add(_createKeyValuePair(address(5), 5)));

        assertEq(keyValueSet.length(), 5);
        assertEq(keyValueSet.contains(address(0)), true);
        assertEq(keyValueSet.contains(address(2)), true);
        assertEq(keyValueSet.contains(address(3)), true);
        assertEq(keyValueSet.contains(address(4)), true);
        assertEq(keyValueSet.contains(address(5)), true);
        _assertKeyValueSetValues(data, 5);
    }

    function testEnumerableKeyValueSetBasic2() public {
        bytes32[] memory data = new bytes32[](3);
        data[0] = _createKeyValuePair(address(0), 1);
        data[1] = _createKeyValuePair(address(2), 2);
        data[2] = _createKeyValuePair(address(3), 3);

        keyValueSet.add(_createKeyValuePair(address(0), 1));
        keyValueSet.add(_createKeyValuePair(address(2), 2));
        _assertKeyValueSetValues(data, 2);
        data[0] = _createKeyValuePair(address(2), 2);

        keyValueSet.remove(address(0));
        assertEq(keyValueSet.length(), 1);
        _assertKeyValueSetValues(data, 1);
        keyValueSet.remove(address(2));
        assertEq(keyValueSet.length(), 0);
        _assertKeyValueSetValues(data, 0);

        keyValueSet.add(_createKeyValuePair(address(0), 1));
        keyValueSet.add(_createKeyValuePair(address(2), 2));
        data[0] = _createKeyValuePair(address(0), 1);
        _assertKeyValueSetValues(data, 2);

        keyValueSet.remove(address(2));
        assertEq(keyValueSet.length(), 1);
        _assertKeyValueSetValues(data, 1);
        keyValueSet.remove(address(0));
        assertEq(keyValueSet.length(), 0);
        _assertKeyValueSetValues(data, 0);

        keyValueSet.add(_createKeyValuePair(address(0), 1));
        keyValueSet.add(_createKeyValuePair(address(2), 2));
        keyValueSet.add(_createKeyValuePair(address(3), 3));
        _assertKeyValueSetValues(data, 3);

        keyValueSet.remove(address(3));
        assertEq(keyValueSet.length(), 2);
        _assertKeyValueSetValues(data, 2);
        keyValueSet.remove(address(2));
        assertEq(keyValueSet.length(), 1);
        _assertKeyValueSetValues(data, 1);
        keyValueSet.remove(address(0));
        assertEq(keyValueSet.length(), 0);
        _assertKeyValueSetValues(data, 0);

        keyValueSet.add(_createKeyValuePair(address(0), 1));
        keyValueSet.add(_createKeyValuePair(address(2), 2));
        keyValueSet.add(_createKeyValuePair(address(3), 3));
        _assertKeyValueSetValues(data, 3);

        data[0] = _createKeyValuePair(address(2), 2);
        data[1] = _createKeyValuePair(address(3), 3);

        keyValueSet.remove(address(0));
        assertEq(keyValueSet.length(), 2);
        _assertKeyValueSetValues(data, 2);

        data[0] = _createKeyValuePair(address(3), 3);

        keyValueSet.remove(address(2));
        assertEq(keyValueSet.length(), 1);
        _assertKeyValueSetValues(data, 1);
        keyValueSet.remove(address(3));
        assertEq(keyValueSet.length(), 0);
        _assertKeyValueSetValues(data, 0);
    }

    function testEnumerableSetFuzz(uint256 n) public {
        if (_randomChance(2)) {
            _testEnumerableKeyValueSetFuzz(n);
        } else {
            if (_randomChance(2)) _testEnumerableKeyValueSetFuzz();
        }
    }

    function _testEnumerableKeyValueSetFuzz(uint256 n) internal {
        unchecked {
            LibPRNG.PRNG memory prng;
            prng.state = n;
            uint256[] memory additions = new uint256[](prng.next() % 16);
            uint256 mask = _randomChance(2) ? 7 : 15;

            for (uint256 i; i != additions.length; ++i) {
                uint256 x = prng.next() & mask;
                x = uint256(_createKeyValuePair(address(uint160(x)), uint96(x)));
                additions[i] = x;
                keyValueSet.add(bytes32(x));
                assertTrue(keyValueSet.contains(EnumerableKeyValueSetLib.getAddressKey(bytes32(x))));
            }
            LibSort.sort(additions);
            LibSort.uniquifySorted(additions);
            assertEq(keyValueSet.length(), additions.length);
            {
                bytes32[] memory values = keyValueSet.values();
                _checkMemory();
                uint256[] memory valuesCasted = _toUints(values);
                LibSort.sort(valuesCasted);
                assertEq(valuesCasted, additions);
            }

            uint256[] memory removals = new uint256[](prng.next() % 16);
            for (uint256 i; i != removals.length; ++i) {
                uint256 x = prng.next() & mask;
                x = uint256(_createKeyValuePair(address(uint160(x)), uint96(x)));
                removals[i] = x;
                address key = EnumerableKeyValueSetLib.getAddressKey(bytes32(x));
                keyValueSet.remove(key);
                assertFalse(keyValueSet.contains(key));
            }
            LibSort.sort(removals);
            LibSort.uniquifySorted(removals);

            {
                uint256[] memory difference = LibSort.difference(additions, removals);
                bytes32[] memory values = keyValueSet.values();
                _checkMemory();
                if (_randomChance(8)) _checkKeyValueSetValues(values);
                uint256[] memory valuesCasted = _toUints(values);
                LibSort.sort(valuesCasted);
                assertEq(valuesCasted, difference);
            }
        }
    }

    function _testEnumerableKeyValueSetFuzz() internal {
        uint256[] memory s = _makeArray(0);
        do {
            bytes32 r = bytes32(_random());
            if (_randomChance(16)) _brutalizeMemory();
            if (_randomChance(2)) {
                keyValueSet.add(r);
                _addToArray(s, uint256(r));
                assertTrue(keyValueSet.contains(EnumerableKeyValueSetLib.getAddressKey(r)));
            } else {
                address key = EnumerableKeyValueSetLib.getAddressKey(r);
                keyValueSet.remove(key);
                _removeFromArray(s, uint256(r));
                assertFalse(keyValueSet.contains(key));
            }
            if (_randomChance(16)) _brutalizeMemory();
            if (_randomChance(16)) {
                _checkArraysSortedEq(_toUints(keyValueSet.values()), s);
                assertEq(keyValueSet.length(), s.length);
            }
            if (s.length == 512) break;
        } while (!_randomChance(8));
        _checkArraysSortedEq(_toUints(keyValueSet.values()), s);
    }

    function _checkArraysSortedEq(uint256[] memory a, uint256[] memory b) internal {
        LibSort.sort(a);
        LibSort.sort(b);
        assertEq(a, b);
    }

    function _checkKeyValueSetValues(bytes32[] memory values) internal {
        unchecked {
            for (uint256 i; i != values.length; ++i) {
                assertEq(keyValueSet.at(i), values[i]);
            }
            vm.expectRevert(EnumerableSetLib.IndexOutOfBounds.selector);
            keyValueSetAt(_bound(_random(), values.length, type(uint256).max));
        }
    }

    function testEnumerableKeyValueSetRevertsOnSentinel(uint256) public {
        do {
            address key = _randomAddress();
            if (_randomChance(32)) {
                key = _ZERO_SENTINEL;
            }
            bytes32 a = _createKeyValuePair(key, uint96(_random()));
            uint256 r = _random() % 3;
            if (r == 0) {
                if (key == _ZERO_SENTINEL) {
                    vm.expectRevert(EnumerableSetLib.ValueIsZeroSentinel.selector);
                }
                this.addToKeyValueSet(a);
            }
            if (r == 1) {
                if (key == _ZERO_SENTINEL) {
                    vm.expectRevert(EnumerableSetLib.ValueIsZeroSentinel.selector);
                }
                this.keyValueSetContains(a);
            }
            if (r == 2) {
                if (key == _ZERO_SENTINEL) {
                    vm.expectRevert(EnumerableSetLib.ValueIsZeroSentinel.selector);
                }
                this.removeFromKeyValueSet(a);
            }
        } while (!_randomChance(2));
    }

    function addToKeyValueSet(bytes32 a) public returns (bool) {
        return keyValueSet.add(a);
    }

    function keyValueSetContains(bytes32 a) public view returns (bool) {
        return keyValueSet.contains(EnumerableKeyValueSetLib.getAddressKey(a));
    }

    function removeFromKeyValueSet(bytes32 a) public returns (bool) {
        return keyValueSet.remove(EnumerableKeyValueSetLib.getAddressKey(a));
    }

    function keyValueSetAt(uint256 i) public view returns (bytes32) {
        return keyValueSet.at(i);
    }

    function _toUints(address[] memory a) private pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := a
        }
    }

    function _toUints(int256[] memory a) private pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := a
        }
    }

    function _toUints(bytes32[] memory a) private pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := a
        }
    }

    function _makeArray(uint256 size, uint256 maxCap)
        internal
        pure
        returns (uint256[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, size)
            mstore(0x40, add(result, shl(5, add(maxCap, 1))))
        }
    }

    function _makeArray(uint256 size) internal pure returns (uint256[] memory result) {
        require(size <= 512, "Size too big.");
        result = _makeArray(size, 512);
    }

    function _addToArray(uint256[] memory a, uint256 x) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let exists := 0
            let n := mload(a)
            for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                let o := add(add(a, 0x20), shl(5, i))
                if eq(shr(96, mload(o)), shr(96, x)) {
                    exists := 1
                    break
                }
            }
            if iszero(exists) {
                n := add(n, 1)
                mstore(add(a, shl(5, n)), x)
                mstore(a, n)
            }
        }
    }

    function _removeFromArray(uint256[] memory a, uint256 x) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(a)
            for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                let o := add(add(a, 0x20), shl(5, i))
                if eq(shr(96, mload(o)), shr(96, x)) {
                    mstore(o, mload(add(a, shl(5, n))))
                    mstore(a, sub(n, 1))
                    break
                }
            }
        }
    }

    function _assertKeyValueSetValues(bytes32[] memory expected, uint256 length) internal {
        uint256 originalLength;
        /// @solidity memory-safe-assembly
        assembly {
            originalLength := mload(expected)
            mstore(expected, length)
        }
        _assertKeyValueSetValues(expected);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(expected, originalLength)
        }
    }

    function _assertKeyValueSetValues(bytes32[] memory expected) internal {
        assertEq(keyValueSet.values(), expected);
        _checkKeyValueSetValues(expected);
    }
}
