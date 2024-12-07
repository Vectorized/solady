// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {EnumerableMapLib} from "../src/utils/EnumerableMapLib.sol";

contract EnumerableMapLibTest is SoladyTest {
    using EnumerableMapLib for *;

    EnumerableMapLib.AddressToUint256Map map;

    function testEnumerableMap(bytes32) public {
        address key0 = _randomNonZeroAddress();
        address key1 = _randomNonZeroAddress();
        uint256 value0 = _random();
        uint256 value1 = _random();

        assertFalse(map.contains(key0));
        assertTrue(map.set(key0, value0));
        assertTrue(map.contains(key0));

        if (key0 != key1) {
            (bool exists, uint256 retrieved) = map.tryGet(key0);
            assertTrue(exists);
            assertEq(retrieved, value0);
            (exists, retrieved) = map.tryGet(key1);
            assertFalse(exists);
            assertEq(retrieved, 0);
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

            (address retrievedKey, uint256 retrieved) = map.at(0);
            assertEq(retrievedKey, key0);
            assertEq(retrieved, value0);
            (retrievedKey, retrieved) = map.at(1);
            assertEq(retrievedKey, key1);
            assertEq(retrieved, value1);

            address[] memory retrievedKeys = map.keys();
            assertEq(retrievedKeys.length, 2);
            assertEq(retrievedKeys[0], key0);
            assertEq(retrievedKeys[1], key1);

            assertTrue(map.remove(key0));
            assertEq(map.length(), 1);
            assertFalse(map.remove(key0));
            assertEq(map.length(), 1);
        } else {
            address[] memory retrievedKeys = map.keys();
            assertEq(retrievedKeys.length, 1);
            assertEq(retrievedKeys[0], key0);

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
