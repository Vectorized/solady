// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {EnumerableMapLib} from "../src/utils/EnumerableMapLib.sol";

contract EnumerableMapLibTest is SoladyTest {
    using EnumerableMapLib for *;

    EnumerableMapLib.AddressToUint256Map map;

    struct _TestTemps {
        bool exists;
        address key;
        uint256 value;
        address[] keys;
    }

    function testEnumerableMap(bytes32) public {
        address key0 = _randomNonZeroAddress();
        address key1 = _randomNonZeroAddress();
        uint256 value0 = _random();
        uint256 value1 = _random();
        _TestTemps memory t;

        assertFalse(map.contains(key0));
        assertTrue(map.set(key0, value0));
        assertTrue(map.contains(key0));

        if (key0 != key1) {
            (t.exists, t.value) = map.tryGet(key0);
            assertTrue(t.exists);
            assertEq(t.value, value0);
            (t.exists, t.value) = map.tryGet(key1);
            assertFalse(t.exists);
            assertEq(t.value, 0);
            vm.expectRevert(EnumerableMapLib.EnumerableMapKeyNotFound.selector);
            this.get(key1);
            assertEq(this.get(key0), value0);
        }

        assertEq(map.length(), 1);
        assertFalse(map.set(key0, value0));
        assertEq(map.length(), 1);

        if (key0 != key1) {
            assertTrue(map.set(key1, value1));
            assertEq(map.length(), 2);

            (t.key, t.value) = map.at(0);
            assertEq(t.key, key0);
            assertEq(t.value, value0);
            (t.key, t.value) = map.at(1);
            assertEq(t.key, key1);
            assertEq(t.value, value1);

            t.keys = map.keys();
            assertEq(t.keys.length, 2);
            assertEq(t.keys[0], key0);
            assertEq(t.keys[1], key1);

            assertTrue(map.remove(key0));
            assertEq(map.length(), 1);
            assertFalse(map.remove(key0));
            assertEq(map.length(), 1);
        } else {
            t.keys = map.keys();
            assertEq(t.keys.length, 1);
            assertEq(t.keys[0], key0);

            assertTrue(map.remove(key0));
            assertEq(map.length(), 0);
            assertFalse(map.remove(key0));
            assertEq(map.length(), 0);
        }
    }

    function get(address key) public view returns (uint256) {
        return map.get(key);
    }
}
