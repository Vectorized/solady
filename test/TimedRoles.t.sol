// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibSort} from "../src/utils/LibSort.sol";
import {LibPRNG} from "../src/utils/LibPRNG.sol";
import {DynamicArrayLib} from "../src/utils/DynamicArrayLib.sol";
import {EnumerableSetLib} from "../src/utils/EnumerableSetLib.sol";
import "./utils/SoladyTest.sol";
import "./utils/mocks/MockTimedRoles.sol";

contract TimedRolesTest is SoladyTest {
    using DynamicArrayLib for *;

    MockTimedRoles mockTimedRoles;

    function setUp() public {
        mockTimedRoles = new MockTimedRoles();
        mockTimedRoles.setMaxTimedRole(type(uint256).max);
        mockTimedRoles.setOwner(address(this));
    }

    struct TimedRoleConfig {
        address holder;
        uint256 role;
        uint40 start;
        uint40 end;
    }

    function _sampleTimedRoleConfigs() internal returns (TimedRoleConfig[] memory a) {
        a = new TimedRoleConfig[](_randomUniform() & 7);
        unchecked {
            uint256 m = 0xf00000000000000000000000000000000000000000000000000000000000000f;
            for (uint256 i; i != a.length; ++i) {
                TimedRoleConfig memory c = a[i];
                c.holder = _randomUniqueHashedAddress();
                c.role = _randomUniform() & m;
                (c.start, c.end) = _sampleValidActiveTimeRange();
            }
        }
    }

    function _sampleValidActiveTimeRange() internal returns (uint40 start, uint40 end) {
        do {
            start = uint40(_random());
            end = uint40(_random());
        } while (end < start);
    }

    function testSetAndGetRoles(bytes32) public {
        TimedRoleConfig[] memory a = _sampleTimedRoleConfigs();
        for (uint256 i; i != a.length; ++i) {
            TimedRoleConfig memory c = a[i];
            mockTimedRoles.setTimedRoleDirect(c.holder, c.role, c.start, c.end);
        }
    }
    //     _TestTemps memory t;
    //     t.holders = _sampleUniqueAddresses(_randomUniform() & 7);
    //     t.roles = new uint256[][](t.holders.length);
    //     t.rolesLookup = new uint256[][](t.holders.length);
    //     unchecked {
    //         for (uint256 i; i != t.holders.length; ++i) {
    //             uint256[] memory roles = _sampleRoles(_randomUniform() & 7);
    //             t.roles[i] = roles;
    //             roles = LibSort.copy(roles);
    //             LibSort.insertionSort(roles);
    //             LibSort.uniquifySorted(roles);
    //             t.rolesLookup[i] = roles;
    //             t.combinedRoles = LibSort.union(roles, t.combinedRoles);
    //         }

    //         for (uint256 i; i != t.holders.length; ++i) {
    //             uint256[] memory roles = t.roles[i];
    //             for (uint256 j; j != roles.length; ++j) {
    //                 mockEnumerableRoles.setRoleDirect(t.holders[i], roles[j], true);
    //             }
    //         }

    //         if (_randomChance(2)) {
    //             for (uint256 i; i < t.combinedRoles.length; ++i) {
    //                 if (!_randomChance(8)) continue;
    //                 uint256 role = t.combinedRoles.get(i);
    //                 DynamicArrayLib.DynamicArray memory expected;
    //                 for (uint256 j; j != t.holders.length; ++j) {
    //                     if (LibSort.inSorted(t.rolesLookup[j], role)) {
    //                         expected.p(t.holders[j]);
    //                     }
    //                 }
    //                 LibSort.insertionSort(expected.data);
    //                 assertEq(abi.encode(expected.data), abi.encode(_sortedRoleHolders(role)));
    //             }
    //         }

    //         if (_randomChance(2)) {
    //             for (uint256 i; i != t.holders.length; ++i) {
    //                 uint256[] memory roles = t.roles[i];
    //                 for (uint256 j; j != roles.length; ++j) {
    //                     mockEnumerableRoles.setRoleDirect(t.holders[i], roles[j], false);
    //                 }
    //             }

    //             for (uint256 i; i < t.combinedRoles.length; ++i) {
    //                 uint256 role = t.combinedRoles.get(i);
    //                 assertEq(mockEnumerableRoles.roleHolders(role).length, 0);
    //                 assertEq(mockEnumerableRoles.roleHolderCount(role), 0);
    //             }
    //         }
    //     }
    // }

    function _sampleUniqueAddresses(uint256 n) internal returns (address[] memory) {
        unchecked {
            uint256[] memory a = DynamicArrayLib.malloc(n);
            for (uint256 i; i != n; ++i) {
                a.set(i, _randomUniqueHashedAddress());
            }
            return a.asAddressArray();
        }
    }

    function _sampleRoles(uint256 n) internal returns (uint256[] memory roles) {
        unchecked {
            uint256 m = 0xf00000000000000000000000000000000000000000000000000000000000000f;
            roles = DynamicArrayLib.malloc(n);
            for (uint256 i; i != n; ++i) {
                roles.set(i, _randomUniform() & m);
            }
        }
    }
}
