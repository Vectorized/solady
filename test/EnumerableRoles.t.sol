// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibSort} from "../src/utils/LibSort.sol";
import {DynamicArrayLib} from "../src/utils/DynamicArrayLib.sol";
import "./utils/SoladyTest.sol";
import "./utils/mocks/MockEnumerableRoles.sol";

contract EnumerableRolesTest is SoladyTest {
    using DynamicArrayLib for *;

    event RoleSet(address indexed holder, uint8 indexed role, bool indexed active);

    MockEnumerableRoles mockEnumerableRoles;

    function setUp() public {
        mockEnumerableRoles = new MockEnumerableRoles();
    }

    function testIsContractOwner(address owner, address sender, bool ownerReverts) public {
        mockEnumerableRoles.setOwner(owner);
        mockEnumerableRoles.setOwnerReverts(ownerReverts);
        while (sender == address(0)) sender = _randomNonZeroAddress();
        assertEq(mockEnumerableRoles.isContractOwner(sender), sender == owner && !ownerReverts);
    }

    function testSetRoleOverMaxRoleReverts(
        bytes32,
        uint8 role,
        uint256 maxRole,
        bool maxRoleReverts
    ) public {
        maxRole = _bound(maxRole, 0, 512);
        mockEnumerableRoles.setMaxRole(maxRole);
        mockEnumerableRoles.setMaxRoleReverts(maxRoleReverts);
        address holder = _randomNonZeroAddress();
        bool active = _randomChance(2);
        if (role > maxRole && !maxRoleReverts) {
            vm.expectRevert(EnumerableRoles.RoleExceedsMaxRole.selector);
            mockEnumerableRoles.setRoleDirect(holder, role, active);
        } else {
            vm.expectEmit(true, true, true, true);
            emit RoleSet(holder, role, active);
            mockEnumerableRoles.setRoleDirect(holder, role, active);
        }
    }

    function testSetAndGetRoles(bytes32, address user0, address user1) public {
        while (user0 == address(0) || user1 == address(0) || user0 == user1) {
            user0 = _randomNonZeroAddress();
            user1 = _randomNonZeroAddress();
        }
        _testSetAndGetRoles(user0, user1, _sampleRoles(), _sampleRoles());
    }

    function testSetAndGetRoles() public {
        uint256[] memory allRoles = DynamicArrayLib.malloc(256);
        unchecked {
            for (uint256 i; i < 256; ++i) {
                allRoles.set(i, i);
            }
        }
        _testSetAndGetRoles(address(1), address(2), allRoles, allRoles);
    }

    function _testSetAndGetRoles(
        address user0,
        address user1,
        uint256[] memory user0Roles,
        uint256[] memory user1Roles
    ) internal {
        mockEnumerableRoles.setMaxRole(255);
        mockEnumerableRoles.setOwner(address(this));
        unchecked {
            for (uint256 i; i != user0Roles.length; ++i) {
                mockEnumerableRoles.setRole(user0, uint8(user0Roles.get(i)), true);
            }
            for (uint256 i; i != user1Roles.length; ++i) {
                mockEnumerableRoles.setRole(user1, uint8(user1Roles.get(i)), true);
            }
            _checkRoles(user0, user0Roles);
            _checkRoles(user1, user1Roles);
            if (_randomChance(32)) {
                uint256[] memory user0RolesLookup = _sortedAndUniquifiedCopy(user0Roles);
                uint256[] memory user1RolesLookup = _sortedAndUniquifiedCopy(user1Roles);
                for (uint256 role; role < 256; ++role) {
                    if (!_randomChance(8)) continue;
                    DynamicArrayLib.DynamicArray memory expected;
                    if (LibSort.inSorted(user0RolesLookup, role)) expected.p(user0);
                    if (LibSort.inSorted(user1RolesLookup, role)) expected.p(user1);
                    LibSort.sort(expected.data);
                    address[] memory roleHolders = mockEnumerableRoles.roleHolders(uint8(role));
                    LibSort.sort(roleHolders);
                    assertEq(abi.encodePacked(expected.data), abi.encodePacked(roleHolders));
                }
            }
            for (uint256 i; i != user0Roles.length; ++i) {
                mockEnumerableRoles.setRole(user0, uint8(user0Roles.get(i)), false);
            }
            for (uint256 i; i != user1Roles.length; ++i) {
                mockEnumerableRoles.setRole(user1, uint8(user1Roles.get(i)), false);
            }
            assertEq(mockEnumerableRoles.rolesOf(user0).length, 0);
            assertEq(mockEnumerableRoles.rolesOf(user1).length, 0);
            if (_randomChance(32)) {
                for (uint256 i; i < 256; ++i) {
                    uint8 role = uint8(i);
                    assertEq(mockEnumerableRoles.roleHolders(role).length, 0);
                }
            }
        }
    }

    function _sortedAndUniquifiedCopy(uint256[] memory a)
        internal
        pure
        returns (uint256[] memory result)
    {
        result = LibSort.copy(a);
        LibSort.sort(result);
        LibSort.uniquifySorted(result);
    }

    function _checkRoles(address user, uint256[] memory sampledRoles) internal {
        uint8[] memory roles = mockEnumerableRoles.rolesOf(user);
        LibSort.sort(_toUint256Array(roles));
        assertEq(_toUint256Array(roles), _sortedAndUniquifiedCopy(sampledRoles));
    }

    function _toUint256Array(uint8[] memory a) internal pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := a
        }
    }

    function _sampleRoles(uint256 n) internal returns (uint256[] memory roles) {
        unchecked {
            roles = DynamicArrayLib.malloc(n);
            for (uint256 i; i != n; ++i) {
                roles.set(i, _randomUniform() & 0xff);
            }
        }
    }

    function _sampleRoles() internal returns (uint256[] memory roles) {
        return _sampleRoles(_randomUniform() & 0xf);
    }
}
