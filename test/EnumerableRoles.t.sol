// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import "./utils/mocks/MockEnumerableRoles.sol";

contract EnumerableRolesTest is SoladyTest {
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
        if (role > maxRole && !maxRoleReverts) {
            vm.expectRevert(EnumerableRoles.RoleExceedsMaxRole.selector);
        }
        mockEnumerableRoles.setRoleDirect(_randomNonZeroAddress(), role, _randomChance(2));
    }
}
