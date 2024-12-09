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

    function setUp() public {
        mockEnumerableRoles = new MockEnumerableRoles();
        mockEnumerableRoles.setMaxRole(type(uint256).max);
        mockEnumerableRoles.setOwner(address(this));
    }

    function testStorageLayoutTrick(uint256 role, uint32 slotSeed, address holder) public {
        bytes32 rootSlot;
        bytes32 positionSlot;
        holder = _brutalized(holder);
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(0x18, holder)
            mstore(0x04, slotSeed)
            mstore(0x00, role)
            rootSlot := keccak256(0x00, 0x24)
            positionSlot := keccak256(0x00, 0x38)
            mstore(0x24, shl(96, holder))
            if iszero(eq(keccak256(0x00, 0x24), rootSlot)) { invalid() }
            if iszero(eq(keccak256(0x00, 0x38), positionSlot)) { invalid() }
            if iszero(eq(mload(0x40), m)) { invalid() }
        }
        assertEq(positionSlot, keccak256(abi.encodePacked(role, slotSeed, holder)));
        assertEq(rootSlot, keccak256(abi.encodePacked(role, slotSeed)));
    }

    function testIsContractOwner(address owner, address pranker, bool ownerReverts) public {
        mockEnumerableRoles.setOwner(owner);
        mockEnumerableRoles.setOwnerReverts(ownerReverts);
        while (pranker == address(0)) pranker = _randomNonZeroAddress();
        if (pranker != owner || ownerReverts) {
            vm.expectRevert(EnumerableRoles.EnumerableRolesUnauthorized.selector);
        }
        vm.prank(pranker);
        mockEnumerableRoles.setRole(address(1), 0, true);
    }

    function _roleHolders(uint256 role)
        internal
        pure
        returns (EnumerableSetLib.AddressSet storage holders)
    {
        /// @solidity memory-safe-assembly
        assembly {
            holders.slot := add(role, 0x97)
        }
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
            vm.expectRevert(EnumerableRoles.InvalidRole.selector);
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
        address[] holders;
        uint256[][] roles;
        uint256[][] rolesLookup;
        uint256[] combinedRoles;
    }

    function testHasAnyRoles(bytes32) public {
        uint256[] memory rolesToSet = _sampleRoles(_randomUniform() & 7);
        uint256[] memory rolesToCheck = _sampleRoles(_randomUniform() & 7);
        address holder = _randomNonZeroAddress();
        unchecked {
            for (uint256 i; i != rolesToSet.length; ++i) {
                mockEnumerableRoles.setRole(holder, rolesToSet.get(i), true);
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
                if (mockEnumerableRoles.hasRole(holder, rolesToCheck.get(i))) ++numFound;
            }
            assertEq(intersectionLength, numFound);
        }
        assertEq(
            mockEnumerableRoles.hasAnyRoles(holder, _encodeRolesToCheck(rolesToCheck)),
            intersectionLength != 0
        );

        if (_randomChance(8)) {
            mockEnumerableRoles.setAllowedRolesEncoded(_encodeRolesToCheck(rolesToCheck));
            address pranker = address(this);
            if (_randomChance(2)) pranker = holder;
            if (_randomChance(2)) pranker = _randomNonZeroAddress();
            vm.startPrank(pranker);
            if (pranker == address(this)) {
                mockEnumerableRoles.guardedByOnlyOwnerOrRoles();
                if (pranker != holder) {
                    vm.expectRevert(EnumerableRoles.EnumerableRolesUnauthorized.selector);
                }
                mockEnumerableRoles.guardedByOnlyRoles();
            } else if (pranker == holder && pranker != address(this)) {
                if (intersectionLength == 0) {
                    vm.expectRevert(EnumerableRoles.EnumerableRolesUnauthorized.selector);
                }
                mockEnumerableRoles.guardedByOnlyOwnerOrRoles();
                if (intersectionLength == 0) {
                    vm.expectRevert(EnumerableRoles.EnumerableRolesUnauthorized.selector);
                }
                mockEnumerableRoles.guardedByOnlyRoles();
            } else {
                vm.expectRevert(EnumerableRoles.EnumerableRolesUnauthorized.selector);
                mockEnumerableRoles.guardedByOnlyOwnerOrRoles();
                vm.expectRevert(EnumerableRoles.EnumerableRolesUnauthorized.selector);
                mockEnumerableRoles.guardedByOnlyRoles();
            }
            vm.stopPrank();
        }
    }

    function _encodeRolesToCheck(uint256[] memory roles) internal returns (bytes memory) {
        if (_randomChance(2)) {
            bytes memory dirt;
            uint256 dirtLength = _randomUniform() & 31;
            uint256 dirtBits = _random();
            /// @solidity memory-safe-assembly
            assembly {
                dirt := mload(0x40)
                mstore(dirt, dirtLength)
                mstore(add(dirt, 0x20), dirtBits)
                mstore(0x40, add(dirt, 0x40))
            }
            return abi.encodePacked(roles, dirt);
        } else {
            return abi.encodePacked(roles);
        }
    }

    function testSetAndGetRolesDifferential(bytes32) public {
        uint256[] memory roles;
        address[] memory holders;
        while (roles.length == 0 || holders.length == 0) {
            roles = _sampleRoles(1 + (_randomUniform() & 7));
            holders = _sampleUniqueAddresses(16 + (_randomUniform() & 15));
        }
        do {
            for (uint256 q = _randomUniform() & 7; q != 0; --q) {
                uint256 role = roles[_randomUniform() % roles.length];
                address holder = holders[_randomUniform() % holders.length];
                bool active = _randomChance(2);
                mockEnumerableRoles.setRoleDirect(holder, role, active);
                if (active) {
                    _roleHolders(role).add(holder);
                } else {
                    _roleHolders(role).remove(holder);
                }
                assertEq(mockEnumerableRoles.hasRole(holder, role), active);
                if (_randomChance(8)) _checkRoleHolders(roles);
            }
        } while (_randomChance(2));
        _checkRoleHolders(roles);
    }

    function _checkRoleHolders(uint256[] memory roles) internal tempMemory {
        for (uint256 i; i != roles.length; ++i) {
            uint256 role = roles[i];
            address[] memory expected = _roleHolders(role).values();
            LibSort.insertionSort(expected);
            assertEq(_sortedRoleHolders(role), expected);
            uint256 n = _roleHolders(role).length();
            assertEq(mockEnumerableRoles.roleHolderCount(role), n);
            assertEq(expected.length, n);
        }
    }

    function testOnlyOwnerOrRole(uint256 allowedRole, uint256 holderRole) public {
        address holder = _randomUniqueHashedAddress();
        assertEq(mockEnumerableRoles.owner(), address(this));
        if (holder == address(this)) return;
        mockEnumerableRoles.setAllowedRole(allowedRole);
        mockEnumerableRoles.setRoleDirect(holder, holderRole, true);
        if (_randomChance(32)) {
            mockEnumerableRoles.guardedByOnlyOwnerOrRole();
        }
        if (holderRole != allowedRole) {
            vm.prank(holder);
            vm.expectRevert(EnumerableRoles.EnumerableRolesUnauthorized.selector);
            mockEnumerableRoles.guardedByOnlyOwnerOrRole();
        } else {
            vm.prank(holder);
            mockEnumerableRoles.guardedByOnlyOwnerOrRole();
        }
    }

    function testSetAndGetRoles(bytes32) public {
        _TestTemps memory t;
        t.holders = _sampleUniqueAddresses(_randomUniform() & 7);
        t.roles = new uint256[][](t.holders.length);
        t.rolesLookup = new uint256[][](t.holders.length);
        unchecked {
            for (uint256 i; i != t.holders.length; ++i) {
                uint256[] memory roles = _sampleRoles(_randomUniform() & 7);
                t.roles[i] = roles;
                roles = LibSort.copy(roles);
                LibSort.insertionSort(roles);
                LibSort.uniquifySorted(roles);
                t.rolesLookup[i] = roles;
                t.combinedRoles = LibSort.union(roles, t.combinedRoles);
            }

            for (uint256 i; i != t.holders.length; ++i) {
                uint256[] memory roles = t.roles[i];
                for (uint256 j; j != roles.length; ++j) {
                    mockEnumerableRoles.setRoleDirect(t.holders[i], roles[j], true);
                }
            }

            if (_randomChance(2)) {
                for (uint256 i; i < t.combinedRoles.length; ++i) {
                    if (!_randomChance(8)) continue;
                    uint256 role = t.combinedRoles.get(i);
                    DynamicArrayLib.DynamicArray memory expected;
                    for (uint256 j; j != t.holders.length; ++j) {
                        if (LibSort.inSorted(t.rolesLookup[j], role)) {
                            expected.p(t.holders[j]);
                        }
                    }
                    LibSort.insertionSort(expected.data);
                    assertEq(abi.encode(expected.data), abi.encode(_sortedRoleHolders(role)));
                }
            }

            if (_randomChance(2)) {
                for (uint256 i; i != t.holders.length; ++i) {
                    uint256[] memory roles = t.roles[i];
                    for (uint256 j; j != roles.length; ++j) {
                        mockEnumerableRoles.setRoleDirect(t.holders[i], roles[j], false);
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
                j = _bound(_randomUniform(), 0, result.length + 10);
                if (j >= result.length) {
                    vm.expectRevert(EnumerableRoles.RoleHoldersIndexOutOfBounds.selector);
                    mockEnumerableRoles.roleHolderAt(role, j);
                }
            }
            LibSort.insertionSort(result);
        }
    }

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
