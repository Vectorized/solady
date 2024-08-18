// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

contract TestPlusrTest is SoladyTest {
    function testRandomUnique(bytes32 groupIdA, bytes32 groupIdB) public {
        uint256 r0A = _randomUnique(groupIdA);
        uint256 r1A = _randomUnique(groupIdA);
        assertNotEq(r0A, r1A);
        uint256 r0B = _randomUnique(groupIdB);
        uint256 r1B = _randomUnique(groupIdB);
        assertNotEq(r0B, r1B);
        if (groupIdA == groupIdB) {
            assertNotEq(r0A, r1B);
            assertNotEq(r0A, r0B);
            assertNotEq(r1A, r1B);
            assertNotEq(r1A, r0B);
        }
    }

    function testRandomUniqueAddress(bytes32 groupIdA, bytes32 groupIdB) public {
        address r0A = _randomUniqueAddress(groupIdA);
        address r1A = _randomUniqueAddress(groupIdA);
        assertNotEq(r0A, r1A);
        address r0B = _randomUniqueAddress(groupIdB);
        address r1B = _randomUniqueAddress(groupIdB);
        assertNotEq(r0B, r1B);
        if (groupIdA == groupIdB) {
            assertNotEq(r0A, r1B);
            assertNotEq(r0A, r0B);
            assertNotEq(r1A, r1B);
            assertNotEq(r1A, r0B);
        }
    }
}
