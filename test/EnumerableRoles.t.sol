// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibSort} from "../src/utils/LibSort.sol";
import {LibPRNG} from "../src/utils/LibPRNG.sol";
import {DynamicArrayLib} from "../src/utils/DynamicArrayLib.sol";
import {EnumerableSetLib} from "../src/utils/EnumerableSetLib.sol";
import "./utils/SoladyTest.sol";
import "./utils/mocks/MockEnumerableRoles.sol";

contract EnumerableRolesTest is SoladyTest {
    using DynamicArrayLib for *;
    using EnumerableSetLib for EnumerableSetLib.AddressSet;
    using EnumerableSetLib for EnumerableSetLib.Uint256Set;

    event RoleSet(address indexed holder, uint256 indexed role, bool indexed active);

    MockEnumerableRoles mockEnumerableRoles;

    mapping(uint256 => EnumerableSetLib.AddressSet) roleHolders;

    function setUp() public {
        mockEnumerableRoles = new MockEnumerableRoles();
        mockEnumerableRoles.setMaxRole(type(uint256).max);
        mockEnumerableRoles.setOwner(address(this));
    }

    function testIsContractOwner(address owner, address sender, bool ownerReverts) public {
        mockEnumerableRoles.setOwner(owner);
        mockEnumerableRoles.setOwnerReverts(ownerReverts);
        while (sender == address(0)) sender = _randomNonZeroAddress();
        assertEq(mockEnumerableRoles.isContractOwner(sender), sender == owner && !ownerReverts);
    }

    function testSetRoleReverts(address holder, uint256 role, uint256 maxRole, bool maxRoleReverts)
        public
    {
        mockEnumerableRoles.setMaxRole(maxRole);
        mockEnumerableRoles.setMaxRoleReverts(maxRoleReverts);
        bool active = _randomChance(2);
        if (_randomChance(64)) {
            mockEnumerableRoles.setOwner(address(1));
            vm.expectRevert(EnumerableRoles.EnumerableRolesUnauthorized.selector);
            mockEnumerableRoles.setRole(holder, role, active);
            return;
        }
        if (role > maxRole && !maxRoleReverts) {
            vm.expectRevert(EnumerableRoles.RoleExceedsMaxRole.selector);
            mockEnumerableRoles.setRole(holder, role, active);
        } else if (holder == address(0)) {
            vm.expectRevert(EnumerableRoles.RoleHolderIsZeroAddress.selector);
            mockEnumerableRoles.setRole(holder, role, active);
        } else {
            vm.expectEmit(true, true, true, true);
            emit RoleSet(_cleaned(holder), role, active);
            mockEnumerableRoles.setRole(holder, role, active);
        }
    }

    struct _TestTemps {
        address[] users;
        uint256[][] roles;
        uint256[][] rolesLookup;
        uint256[] combinedRoles;
    }

    function testHasAnyRoles(bytes32) public {
        uint256[] memory rolesToSet = _sampleRoles(_randomUniform() & 7);
        uint256[] memory rolesToCheck = _sampleRoles(_randomUniform() & 7);
        address user = _randomNonZeroAddress();
        unchecked {
            for (uint256 i; i != rolesToSet.length; ++i) {
                mockEnumerableRoles.setRole(user, rolesToSet.get(i), true);
            }
        }
        LibSort.insertionSort(rolesToSet);
        LibSort.uniquifySorted(rolesToSet);
        LibSort.insertionSort(rolesToCheck);
        LibSort.uniquifySorted(rolesToCheck);
        uint256 intersectionLength = LibSort.intersection(rolesToSet, rolesToCheck).length;
        if (_randomChance(32)) {
            uint256 numFound;
            for (uint256 i; i != rolesToCheck.length; ++i) {
                uint256 role = rolesToCheck.get(i);
                if (mockEnumerableRoles.hasRole(user, role)) ++numFound;
            }
            assertEq(intersectionLength, numFound);
        }
        assertEq(
            mockEnumerableRoles.hasAnyRoles(user, abi.encodePacked(rolesToCheck)),
            intersectionLength != 0
        );

        if (_randomChance(8)) {
            mockEnumerableRoles.setAllowedRolesEncoded(abi.encodePacked(rolesToCheck));
            address pranker = address(this);
            if (_randomChance(2)) pranker = user;
            if (_randomChance(2)) pranker = _randomNonZeroAddress();
            vm.startPrank(pranker);
            if (pranker == address(this)) {
                mockEnumerableRoles.guardedByOnlyOwnerOrRoles();
            } else if (pranker == user && pranker != address(this)) {
                if (intersectionLength == 0) {
                    vm.expectRevert(EnumerableRoles.EnumerableRolesUnauthorized.selector);
                }
                mockEnumerableRoles.guardedByOnlyOwnerOrRoles();
            } else {
                vm.expectRevert(EnumerableRoles.EnumerableRolesUnauthorized.selector);
                mockEnumerableRoles.guardedByOnlyOwnerOrRoles();
            }
            vm.stopPrank();
        }
    }

    function testSetAndGetRolesDifferential(bytes32) public {
        uint256[] memory roles;
        address[] memory users;
        while (roles.length == 0 || users.length == 0) {
            roles = _sampleRoles(8);
            users = _sampleUniqueAddresses(32);
        }
        uint256 q;
        do {
            uint256 role = roles[_randomUniform() % roles.length];
            address user = users[_randomUniform() % users.length];
            bool active = _randomChance(2);
            mockEnumerableRoles.setRoleDirect(user, role, active);
            if (active) {
                roleHolders[role].add(user);
            } else {
                roleHolders[role].remove(user);
            }
            assertEq(mockEnumerableRoles.hasRole(user, role), active);
            if (_randomChance(8)) _checkRoleHolders(roles);
        } while (++q < 8 || _randomChance(2));
        _checkRoleHolders(roles);
    }

    function _checkRoleHolders(uint256[] memory roles) internal {
        for (uint256 i; i != roles.length; ++i) {
            uint256 role = roles[i];
            address[] memory expected = roleHolders[role].values();
            LibSort.insertionSort(expected);
            assertEq(_sortedRoleHolders(role), expected);
        }
    }

    function testSetAndGetRoles(bytes32) public {
        _TestTemps memory t;
        t.users = _sampleUniqueAddresses(_randomUniform() & 7);
        t.roles = new uint256[][](t.users.length);
        t.rolesLookup = new uint256[][](t.users.length);
        unchecked {
            for (uint256 i; i != t.users.length; ++i) {
                uint256[] memory roles = _sampleRoles(_randomUniform() & 7);
                t.roles[i] = roles;
                roles = LibSort.copy(roles);
                LibSort.insertionSort(roles);
                LibSort.uniquifySorted(roles);
                t.rolesLookup[i] = roles;
                t.combinedRoles = LibSort.union(roles, t.combinedRoles);
            }

            for (uint256 i; i != t.users.length; ++i) {
                uint256[] memory roles = t.roles[i];
                for (uint256 j; j != roles.length; ++j) {
                    mockEnumerableRoles.setRoleDirect(t.users[i], roles[j], true);
                }
            }

            if (_randomChance(2)) {
                for (uint256 i; i < t.combinedRoles.length; ++i) {
                    if (!_randomChance(8)) continue;
                    uint256 role = t.combinedRoles.get(i);
                    DynamicArrayLib.DynamicArray memory expected;
                    for (uint256 j; j != t.users.length; ++j) {
                        if (LibSort.inSorted(t.rolesLookup[j], role)) {
                            expected.p(t.users[j]);
                        }
                    }
                    LibSort.insertionSort(expected.data);
                    assertEq(abi.encode(expected.data), abi.encode(_sortedRoleHolders(role)));
                }
            }

            if (_randomChance(2)) {
                for (uint256 i; i != t.users.length; ++i) {
                    uint256[] memory roles = t.roles[i];
                    for (uint256 j; j != roles.length; ++j) {
                        mockEnumerableRoles.setRoleDirect(t.users[i], roles[j], false);
                    }
                }

                for (uint256 i; i < t.combinedRoles.length; ++i) {
                    uint256 role = t.combinedRoles.get(i);
                    assertEq(mockEnumerableRoles.roleHolders(role).length, 0);
                    assertEq(mockEnumerableRoles.roleHolderCount(role), 0);
                }
            }
        }
    }

    function _sortedRoleHolders(uint256 role) internal returns (address[] memory result) {
        result = mockEnumerableRoles.roleHolders(role);
        if (result.length != 0) {
            if (_randomChance(8)) {
                uint256 j = _randomUniform() % result.length;
                assertEq(mockEnumerableRoles.roleHolderAt(role, j), result[j]);
                assertEq(mockEnumerableRoles.roleHolderCount(role), result.length);
                if (_randomChance(8)) {
                    j = _bound(_randomUniform(), 0, result.length + 10);
                    if (j >= result.length) {
                        vm.expectRevert(EnumerableRoles.RoleHoldersIndexOutOfBounds.selector);
                        mockEnumerableRoles.roleHolderAt(role, j);
                    }
                }
            }
            LibSort.insertionSort(result);
        }
    }

    function _sampleUniqueAddresses(uint256 n) internal returns (address[] memory) {
        unchecked {
            DynamicArrayLib.DynamicArray memory a;
            for (uint256 i; i != n; ++i) {
                a.p(_randomNonZeroAddress());
            }
            LibSort.insertionSort(a.data);
            LibSort.uniquifySorted(a.data);
            _shuffle(a.data);
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
            _shuffle(roles);
        }
    }

    function _shuffle(uint256[] memory a) internal {
        LibPRNG.PRNG memory prng;
        prng.state = _randomUniform();
        LibPRNG.shuffle(prng, a);
    }
}
