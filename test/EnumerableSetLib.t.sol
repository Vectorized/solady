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

    EnumerableSetLib.Bytes32Set bytes32Set;
    EnumerableSetLib.Bytes32Set bytes32Set2;

    EnumerableSetLib.Uint256Set uint256Set;
    EnumerableSetLib.Int256Set int256Set;

    EnumerableSetLib.Uint8Set uint8Set;

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

    function testEnumerableBytes32SetNoStorageCollision() public {
        bytes32Set.add(bytes32(uint256(1)));
        assertEq(bytes32Set2.contains(bytes32(uint256(1))), false);
        bytes32Set2.add(bytes32(uint256(2)));
        assertEq(bytes32Set.contains(bytes32(uint256(1))), true);
        assertEq(bytes32Set2.contains(bytes32(uint256(1))), false);
        assertEq(bytes32Set.contains(bytes32(uint256(2))), false);
        bytes32Set.add(bytes32(uint256(2)));
        assertEq(bytes32Set.contains(bytes32(uint256(2))), true);
        assertEq(bytes32Set2.contains(bytes32(uint256(1))), false);
        bytes32Set2.add(bytes32(uint256(1)));
        assertEq(bytes32Set.contains(bytes32(uint256(2))), true);
        assertEq(bytes32Set2.contains(bytes32(uint256(1))), true);
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

    function testEnumerableBytes32SetBasic() public {
        assertEq(bytes32Set.length(), 0);
        assertEq(bytes32Set.contains(bytes32(uint256(1))), false);
        assertEq(bytes32Set.contains(bytes32(uint256(2))), false);
        assertEq(bytes32Set.contains(bytes32(uint256(3))), false);
        assertEq(bytes32Set.contains(bytes32(uint256(4))), false);
        assertEq(bytes32Set.contains(bytes32(uint256(5))), false);

        assertTrue(bytes32Set.add(bytes32(uint256(1))));
        assertFalse(bytes32Set.add(bytes32(uint256(1))));

        assertEq(bytes32Set.length(), 1);
        assertEq(bytes32Set.contains(bytes32(uint256(1))), true);
        assertEq(bytes32Set.contains(bytes32(uint256(2))), false);
        assertEq(bytes32Set.contains(bytes32(uint256(3))), false);
        assertEq(bytes32Set.contains(bytes32(uint256(4))), false);
        assertEq(bytes32Set.contains(bytes32(uint256(5))), false);

        assertTrue(bytes32Set.add(bytes32(uint256(2))));
        assertFalse(bytes32Set.add(bytes32(uint256(2))));

        assertEq(bytes32Set.length(), 2);
        assertEq(bytes32Set.contains(bytes32(uint256(1))), true);
        assertEq(bytes32Set.contains(bytes32(uint256(2))), true);
        assertEq(bytes32Set.contains(bytes32(uint256(3))), false);
        assertEq(bytes32Set.contains(bytes32(uint256(4))), false);
        assertEq(bytes32Set.contains(bytes32(uint256(5))), false);

        assertTrue(bytes32Set.add(bytes32(uint256(3))));
        assertFalse(bytes32Set.add(bytes32(uint256(3))));

        assertEq(bytes32Set.length(), 3);
        assertEq(bytes32Set.contains(bytes32(uint256(1))), true);
        assertEq(bytes32Set.contains(bytes32(uint256(2))), true);
        assertEq(bytes32Set.contains(bytes32(uint256(3))), true);
        assertEq(bytes32Set.contains(bytes32(uint256(4))), false);
        assertEq(bytes32Set.contains(bytes32(uint256(5))), false);

        assertTrue(bytes32Set.add(bytes32(uint256(4))));
        assertFalse(bytes32Set.add(bytes32(uint256(4))));

        assertEq(bytes32Set.length(), 4);
        assertEq(bytes32Set.contains(bytes32(uint256(1))), true);
        assertEq(bytes32Set.contains(bytes32(uint256(2))), true);
        assertEq(bytes32Set.contains(bytes32(uint256(3))), true);
        assertEq(bytes32Set.contains(bytes32(uint256(4))), true);
        assertEq(bytes32Set.contains(bytes32(uint256(5))), false);

        assertTrue(bytes32Set.add(bytes32(uint256(5))));
        assertFalse(bytes32Set.add(bytes32(uint256(5))));

        assertEq(bytes32Set.length(), 5);
        assertEq(bytes32Set.contains(bytes32(uint256(1))), true);
        assertEq(bytes32Set.contains(bytes32(uint256(2))), true);
        assertEq(bytes32Set.contains(bytes32(uint256(3))), true);
        assertEq(bytes32Set.contains(bytes32(uint256(4))), true);
        assertEq(bytes32Set.contains(bytes32(uint256(5))), true);
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

    function testEnumerableBytes32SetBasic2() public {
        bytes32Set.add(bytes32(uint256(1)));
        bytes32Set.add(bytes32(uint256(2)));

        bytes32Set.remove(bytes32(uint256(1)));
        assertEq(bytes32Set.length(), 1);
        bytes32Set.remove(bytes32(uint256(2)));
        assertEq(bytes32Set.length(), 0);

        bytes32Set.add(bytes32(uint256(1)));
        bytes32Set.add(bytes32(uint256(2)));

        bytes32Set.remove(bytes32(uint256(2)));
        assertEq(bytes32Set.length(), 1);
        bytes32Set.remove(bytes32(uint256(1)));
        assertEq(bytes32Set.length(), 0);

        bytes32Set.add(bytes32(uint256(1)));
        bytes32Set.add(bytes32(uint256(2)));
        bytes32Set.add(bytes32(uint256(3)));

        bytes32Set.remove(bytes32(uint256(3)));
        assertEq(bytes32Set.length(), 2);
        bytes32Set.remove(bytes32(uint256(2)));
        assertEq(bytes32Set.length(), 1);
        bytes32Set.remove(bytes32(uint256(1)));
        assertEq(bytes32Set.length(), 0);

        bytes32Set.add(bytes32(uint256(1)));
        bytes32Set.add(bytes32(uint256(2)));
        bytes32Set.add(bytes32(uint256(3)));

        bytes32Set.remove(bytes32(uint256(1)));
        assertEq(bytes32Set.length(), 2);
        bytes32Set.remove(bytes32(uint256(2)));
        assertEq(bytes32Set.length(), 1);
        bytes32Set.remove(bytes32(uint256(3)));
        assertEq(bytes32Set.length(), 0);
    }

    function testEnumerableSetFuzz(uint256 n) public {
        if (_randomChance(2)) {
            _testEnumerableAddressSetFuzz(n);
            _testEnumerableBytes32SetFuzz(n);
        } else {
            if (_randomChance(2)) _testEnumerableAddressSetFuzz();
            if (_randomChance(2)) _testEnumerableBytes32SetFuzz();
            if (_randomChance(2)) _testEnumerableUint256SetFuzz();
            if (_randomChance(2)) _testEnumerableInt256SetFuzz();
        }
    }

    function _testEnumerableAddressSetFuzz(uint256 n) internal {
        unchecked {
            LibPRNG.PRNG memory prng;
            prng.state = n;
            uint256[] memory additions = new uint256[](prng.next() % 16);
            uint256 mask = _randomChance(2) ? 7 : 15;

            for (uint256 i; i != additions.length; ++i) {
                uint256 x = prng.next() & mask;
                additions[i] = x;
                addressSet.add(_brutalized(address(uint160(x))));
                assertTrue(addressSet.contains(_brutalized(address(uint160(x)))));
            }
            LibSort.sort(additions);
            LibSort.uniquifySorted(additions);
            assertEq(addressSet.length(), additions.length);
            {
                address[] memory values = addressSet.values();
                _checkMemory();
                uint256[] memory valuesCasted = _toUints(values);
                LibSort.sort(valuesCasted);
                assertEq(valuesCasted, additions);
            }

            uint256[] memory removals = new uint256[](prng.next() % 16);
            for (uint256 i; i != removals.length; ++i) {
                uint256 x = prng.next() & mask;
                removals[i] = x;
                addressSet.remove(_brutalized(address(uint160(x))));
                assertFalse(addressSet.contains(_brutalized(address(uint160(x)))));
            }
            LibSort.sort(removals);
            LibSort.uniquifySorted(removals);

            {
                uint256[] memory difference = LibSort.difference(additions, removals);
                address[] memory values = addressSet.values();
                _checkMemory();
                if (_randomChance(8)) _checkAddressSetValues(values);
                uint256[] memory valuesCasted = _toUints(values);
                LibSort.sort(valuesCasted);
                assertEq(valuesCasted, difference);
            }
        }
    }

    function _testEnumerableAddressSetFuzz() internal {
        uint256[] memory s = _makeArray(0);
        do {
            address r = address(uint160(_random()));
            if (_randomChance(16)) _brutalizeMemory();
            if (_randomChance(2)) {
                addressSet.add(r);
                _addToArray(s, uint256(uint160(r)));
                assertTrue(addressSet.contains(r));
            } else {
                addressSet.remove(r);
                _removeFromArray(s, uint256(uint160(r)));
                assertFalse(addressSet.contains(r));
            }
            if (_randomChance(16)) _brutalizeMemory();
            if (_randomChance(8)) {
                _checkArraysSortedEq(_toUints(addressSet.values()), s);
            }
            assertEq(addressSet.length(), s.length);
            if (s.length == 512) break;
        } while (!_randomChance(8));
        assertEq(addressSet.length(), s.length);
        _checkArraysSortedEq(_toUints(addressSet.values()), s);
        if (_randomChance(4)) {
            unchecked {
                for (uint256 i; i != s.length; ++i) {
                    assertTrue(addressSet.contains(address(uint160(s[i]))));
                }
            }
        }
    }

    function _testEnumerableBytes32SetFuzz(uint256 n) internal {
        unchecked {
            LibPRNG.PRNG memory prng;
            prng.state = n;
            uint256[] memory additions = new uint256[](prng.next() % 16);
            uint256 mask = _randomChance(2) ? 7 : 15;

            for (uint256 i; i != additions.length; ++i) {
                uint256 x = prng.next() & mask;
                additions[i] = x;
                bytes32Set.add(bytes32(x));
                assertTrue(bytes32Set.contains(bytes32(x)));
            }
            LibSort.sort(additions);
            LibSort.uniquifySorted(additions);
            assertEq(bytes32Set.length(), additions.length);
            {
                bytes32[] memory values = bytes32Set.values();
                _checkMemory();
                uint256[] memory valuesCasted = _toUints(values);
                LibSort.sort(valuesCasted);
                assertEq(valuesCasted, additions);
            }

            uint256[] memory removals = new uint256[](prng.next() % 16);
            for (uint256 i; i != removals.length; ++i) {
                uint256 x = prng.next() & mask;
                removals[i] = x;
                bytes32Set.remove(bytes32(x));
                assertFalse(bytes32Set.contains(bytes32(x)));
            }
            LibSort.sort(removals);
            LibSort.uniquifySorted(removals);

            {
                uint256[] memory difference = LibSort.difference(additions, removals);
                bytes32[] memory values = bytes32Set.values();
                _checkMemory();
                if (_randomChance(8)) _checkBytes32SetValues(values);
                uint256[] memory valuesCasted = _toUints(values);
                LibSort.sort(valuesCasted);
                assertEq(valuesCasted, difference);
            }
        }
    }

    function _testEnumerableBytes32SetFuzz() internal {
        uint256[] memory s = _makeArray(0);
        do {
            bytes32 r = bytes32(_random());
            if (_randomChance(16)) _brutalizeMemory();
            if (_randomChance(2)) {
                bytes32Set.add(r);
                _addToArray(s, uint256(r));
                assertTrue(bytes32Set.contains(r));
            } else {
                bytes32Set.remove(r);
                _removeFromArray(s, uint256(r));
                assertFalse(bytes32Set.contains(r));
            }
            if (_randomChance(16)) _brutalizeMemory();
            if (_randomChance(16)) {
                _checkArraysSortedEq(_toUints(bytes32Set.values()), s);
                assertEq(bytes32Set.length(), s.length);
            }
            if (s.length == 512) break;
        } while (!_randomChance(8));
        _checkArraysSortedEq(_toUints(bytes32Set.values()), s);
    }

    function _testEnumerableUint256SetFuzz() public {
        uint256[] memory s = _makeArray(0);
        uint256 mask = _randomChance(2) ? 7 : type(uint256).max;
        do {
            uint256 r = _random() & mask;
            if (_randomChance(2)) {
                uint256Set.add(r);
                _addToArray(s, r);
            } else {
                uint256Set.remove(r);
                _removeFromArray(s, r);
            }
            if (_randomChance(8)) {
                _checkArraysSortedEq(uint256Set.values(), s);
                assertEq(uint256Set.length(), s.length);
            }
            if (s.length == 512) break;
        } while (!_randomChance(16));
        _checkArraysSortedEq(uint256Set.values(), s);
        if (_randomChance(4)) {
            unchecked {
                for (uint256 i; i != s.length; ++i) {
                    assertTrue(uint256Set.contains(s[i]));
                }
            }
        }
    }

    function _testEnumerableInt256SetFuzz() public {
        uint256[] memory s = _makeArray(0);
        do {
            uint256 r = _random();
            if (_randomChance(2)) {
                int256Set.add(int256(r));
                _addToArray(s, uint256(r));
            } else {
                int256Set.remove(int256(r));
                _removeFromArray(s, uint256(r));
            }
            if (_randomChance(16)) {
                _checkArraysSortedEq(_toUints(int256Set.values()), s);
                assertEq(int256Set.length(), s.length);
            }
            if (s.length == 512) break;
        } while (!_randomChance(8));
        _checkArraysSortedEq(_toUints(int256Set.values()), s);
    }

    function _checkArraysSortedEq(uint256[] memory a, uint256[] memory b) internal {
        LibSort.sort(a);
        LibSort.sort(b);
        assertEq(a, b);
    }

    function _checkAddressSetValues(address[] memory values) internal {
        unchecked {
            for (uint256 i; i != values.length; ++i) {
                assertEq(addressSet.at(i), values[i]);
            }
            vm.expectRevert(EnumerableSetLib.IndexOutOfBounds.selector);
            addressSetAt(_bound(_random(), values.length, type(uint256).max));
        }
    }

    function _checkBytes32SetValues(bytes32[] memory values) internal {
        unchecked {
            for (uint256 i; i != values.length; ++i) {
                assertEq(bytes32Set.at(i), values[i]);
            }
            vm.expectRevert(EnumerableSetLib.IndexOutOfBounds.selector);
            bytes32SetAt(_bound(_random(), values.length, type(uint256).max));
        }
    }

    function testEnumerableSetDifferential(bytes32) public {
        address[] memory a;
        uint256[] memory s = _makeArray(0);
        while (a.length == 0) {
            a = _sampleUniqueAddresses(_randomUniform() & 0xf);
        }
        do {
            for (uint256 q = _randomUniform() & 7; q != 0; --q) {
                address x = a[_randomUniform() % a.length];
                if (_randomChance(2)) {
                    uint256Set.add(uint160(x));
                    addressSet.add(x);
                    _addToArray(s, uint160(x));
                } else {
                    uint256Set.remove(uint160(x));
                    addressSet.remove(x);
                    _removeFromArray(s, uint160(x));
                }
            }
        } while (_randomChance(2));
    }

    function _checkDifferential(uint256[] memory s) internal tempMemory {
        uint256[] memory uint256s = uint256Set.values();
        address[] memory addresses = addressSet.values();
        unchecked {
            for (uint256 i; i < uint256s.length; ++i) {
                assertEq(uint256Set.at(i), uint256s[i]);
            }
            for (uint256 i; i < addresses.length; ++i) {
                assertEq(addressSet.at(i), addresses[i]);
            }
        }
        LibSort.insertionSort(uint256s);
        LibSort.insertionSort(addresses);
        bytes memory encoded = abi.encode(addresses);
        assertEq(encoded, abi.encode(uint256s));
        LibSort.insertionSort(s);
        assertEq(encoded, abi.encode(s));
    }

    function _sampleUniqueAddresses(uint256 n) internal returns (address[] memory result) {
        unchecked {
            result = new address[](n);
            for (uint256 i; i != n; ++i) {
                result[i] = _randomUniqueHashedAddress();
            }
        }
    }

    function testEnumerableAddressSetRevertsOnSentinel(uint256) public {
        do {
            address a = address(uint160(_random()));
            if (_randomChance(32)) {
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
        } while (!_randomChance(2));
    }

    function testEnumerableBytes32SetRevertsOnSentinel(uint256) public {
        do {
            bytes32 a = bytes32(_random());
            if (_randomChance(32)) {
                a = bytes32(_ZERO_SENTINEL);
            }
            uint256 r = _random() % 3;
            if (r == 0) {
                if (a == bytes32(_ZERO_SENTINEL)) {
                    vm.expectRevert(EnumerableSetLib.ValueIsZeroSentinel.selector);
                }
                this.addToBytes32Set(a);
            }
            if (r == 1) {
                if (a == bytes32(_ZERO_SENTINEL)) {
                    vm.expectRevert(EnumerableSetLib.ValueIsZeroSentinel.selector);
                }
                this.bytes32SetContains(a);
            }
            if (r == 2) {
                if (a == bytes32(_ZERO_SENTINEL)) {
                    vm.expectRevert(EnumerableSetLib.ValueIsZeroSentinel.selector);
                }
                this.removeFromBytes32Set(a);
            }
        } while (!_randomChance(2));
    }

    function testEnumerableUint8Set() public {
        uint8[] memory ordinals = _flagsToOrdinals(0xff00000000ff);
        unchecked {
            for (uint256 i; i != ordinals.length; ++i) {
                uint8Set.add(ordinals[i]);
            }
            uint8[] memory values = uint8Set.values();
            for (uint256 i; i != ordinals.length; ++i) {
                assertEq(uint8Set.at(i), values[i]);
            }
            assertEq(values.length, 16);
        }
    }

    function testEnumerableUint8Set(uint256 flags, bytes32) public {
        uint8[] memory ordinals = _flagsToOrdinals(flags);
        bytes32 sortedHash = keccak256(abi.encodePacked(ordinals));
        _shuffle(ordinals);
        unchecked {
            for (uint256 i; i != ordinals.length; ++i) {
                assertTrue(uint8Set.add(ordinals[i]));
            }
            if (_randomChance(16)) {
                _shuffle(ordinals);
                for (uint256 i; i != ordinals.length; ++i) {
                    assertFalse(uint8Set.add(ordinals[i]));
                }
            }
            if (_randomChance(16)) {
                for (uint256 i; i != 256; ++i) {
                    assertEq(uint8Set.contains(uint8(i)), flags & (1 << i) != 0);
                }
            }
            uint8[] memory values = uint8Set.values();
            assertEq(keccak256(abi.encodePacked(values)), sortedHash);
            assertEq(values.length, uint8Set.length());
            if (_randomChance(16)) {
                for (uint256 i; i != ordinals.length; ++i) {
                    assertEq(uint8Set.at(i), values[i]);
                }
                vm.expectRevert(EnumerableSetLib.IndexOutOfBounds.selector);
                this.uint8SetAt(_bound(_random(), ordinals.length, type(uint256).max));
            }
            if (_randomChance(16)) {
                _shuffle(ordinals);
                for (uint256 i; i != ordinals.length; ++i) {
                    assertTrue(uint8Set.remove(ordinals[i]));
                    assertFalse(uint8Set.remove(ordinals[i]));
                }
                if (_randomChance(32)) {
                    for (uint256 i; i != 256; ++i) {
                        assertFalse(uint8Set.contains(uint8(i)));
                    }
                }
                assertEq(uint8Set.length(), 0);
            }
        }
    }

    function _shuffle(uint8[] memory a) internal {
        LibPRNG.PRNG memory prng;
        prng.state = _random();
        uint256[] memory casted;
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
        prng.shuffle(casted);
    }

    function _flagsToOrdinals(uint256 flags) internal pure returns (uint8[] memory ordinals) {
        ordinals = new uint8[](256);
        uint256 n;
        unchecked {
            for (uint256 i; i != 256; ++i) {
                if (flags & (1 << i) != 0) ordinals[n++] = uint8(i);
            }
        }
        /// @solidity memory-safe-assembly
        assembly {
            mstore(ordinals, n)
        }
    }

    function uint8SetAt(uint256 i) public view returns (uint8) {
        return uint8Set.at(i);
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

    function addressSetAt(uint256 i) public view returns (address) {
        return addressSet.at(i);
    }

    function addToBytes32Set(bytes32 a) public returns (bool) {
        return bytes32Set.add(a);
    }

    function bytes32SetContains(bytes32 a) public view returns (bool) {
        return bytes32Set.contains(a);
    }

    function removeFromBytes32Set(bytes32 a) public returns (bool) {
        return bytes32Set.remove(a);
    }

    function bytes32SetAt(uint256 i) public view returns (bytes32) {
        return bytes32Set.at(i);
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
                if eq(mload(o), x) {
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
                if eq(mload(o), x) {
                    mstore(o, mload(add(a, shl(5, n))))
                    mstore(a, sub(n, 1))
                    break
                }
            }
        }
    }
}
