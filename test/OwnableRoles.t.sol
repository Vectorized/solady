// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import "./utils/mocks/MockOwnableRoles.sol";

contract OwnableRolesTest is SoladyTest {
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    event OwnershipHandoverRequested(address indexed pendingOwner);

    event OwnershipHandoverCanceled(address indexed pendingOwner);

    event RolesUpdated(address indexed user, uint256 indexed roles);

    MockOwnableRoles mockOwnableRoles;

    function setUp() public {
        mockOwnableRoles = new MockOwnableRoles();
    }

    function testBytecodeSize() public {
        MockOwnableRolesBytecodeSizer mock = new MockOwnableRolesBytecodeSizer();
        assertTrue(address(mock).code.length > 0);
        assertEq(mock.owner(), address(this));
    }

    function testInitializeOwnerDirect() public {
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(0), address(1));
        mockOwnableRoles.initializeOwnerDirect(address(1));
    }

    function testSetOwnerDirect(address newOwner) public {
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), _cleaned(newOwner));
        mockOwnableRoles.setOwnerDirect(newOwner);
        assertEq(mockOwnableRoles.owner(), newOwner);
    }

    function testGrantAndRemoveRolesDirect(
        address user,
        uint256 rolesToGrant,
        uint256 rolesToRemove
    ) public {
        mockOwnableRoles.removeRolesDirect(user, mockOwnableRoles.rolesOf(user));
        assertEq(mockOwnableRoles.rolesOf(user), 0);
        mockOwnableRoles.grantRolesDirect(user, rolesToGrant);
        assertEq(mockOwnableRoles.rolesOf(user), rolesToGrant);
        mockOwnableRoles.removeRolesDirect(user, rolesToRemove);
        assertEq(mockOwnableRoles.rolesOf(user), rolesToGrant ^ (rolesToGrant & rolesToRemove));
    }

    struct _TestTemps {
        address userA;
        address userB;
        uint256 rolesA;
        uint256 rolesB;
    }

    function testSetRolesDirect(uint256) public {
        _TestTemps memory t;
        t.userA = _randomNonZeroAddress();
        t.userB = _randomNonZeroAddress();
        while (t.userA == t.userB) t.userA = _randomNonZeroAddress();
        _testSetRolesDirect(t);
        _testSetRolesDirect(t);
    }

    function _testSetRolesDirect(_TestTemps memory t) internal {
        t.rolesA = _random();
        t.rolesB = _random();
        vm.expectEmit(true, true, true, true);
        emit RolesUpdated(_cleaned(t.userA), t.rolesA);
        mockOwnableRoles.setRolesDirect(t.userA, t.rolesA);
        emit RolesUpdated(_cleaned(t.userB), t.rolesB);
        mockOwnableRoles.setRolesDirect(t.userB, t.rolesB);
        assertEq(mockOwnableRoles.rolesOf(t.userA), t.rolesA);
        assertEq(mockOwnableRoles.rolesOf(t.userB), t.rolesB);
    }

    function testSetOwnerDirect() public {
        testSetOwnerDirect(address(1));
    }

    function testRenounceOwnership() public {
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), address(0));
        mockOwnableRoles.renounceOwnership();
        assertEq(mockOwnableRoles.owner(), address(0));
    }

    function testTransferOwnership(
        address newOwner,
        bool setNewOwnerToZeroAddress,
        bool callerIsOwner
    ) public {
        assertEq(mockOwnableRoles.owner(), address(this));

        while (newOwner == address(this)) newOwner = _randomNonZeroAddress();

        if (newOwner == address(0) || setNewOwnerToZeroAddress) {
            newOwner = address(0);
            vm.expectRevert(Ownable.NewOwnerIsZeroAddress.selector);
        } else if (callerIsOwner) {
            vm.expectEmit(true, true, true, true);
            emit OwnershipTransferred(address(this), _cleaned(newOwner));
        } else {
            vm.prank(newOwner);
            vm.expectRevert(Ownable.Unauthorized.selector);
        }

        mockOwnableRoles.transferOwnership(newOwner);

        if (newOwner != address(0) && callerIsOwner) {
            assertEq(mockOwnableRoles.owner(), newOwner);
        }
    }

    function testTransferOwnership() public {
        testTransferOwnership(address(1), false, true);
    }

    function testGrantRoles() public {
        vm.expectEmit(true, true, true, true);
        emit RolesUpdated(address(1), 111111);
        mockOwnableRoles.grantRoles(address(1), 111111);
    }

    function testGrantAndRevokeOrRenounceRoles(
        address user,
        bool granterIsOwner,
        bool useRenounce,
        bool revokerIsOwner,
        uint256 rolesToGrant,
        uint256 rolesToRevoke
    ) public {
        while (user == address(this)) user = _randomNonZeroAddress();

        uint256 rolesAfterRevoke = rolesToGrant ^ (rolesToGrant & rolesToRevoke);

        assertTrue(rolesAfterRevoke & rolesToRevoke == 0);
        assertTrue((rolesAfterRevoke | rolesToRevoke) & rolesToGrant == rolesToGrant);

        if (granterIsOwner) {
            vm.expectEmit(true, true, true, true);
            emit RolesUpdated(_cleaned(user), rolesToGrant);
        } else {
            vm.prank(user);
            vm.expectRevert(Ownable.Unauthorized.selector);
        }
        mockOwnableRoles.grantRoles(user, rolesToGrant);

        if (!granterIsOwner) return;

        assertEq(mockOwnableRoles.rolesOf(user), rolesToGrant);

        if (useRenounce) {
            vm.expectEmit(true, true, true, true);
            emit RolesUpdated(_cleaned(user), rolesAfterRevoke);
            vm.prank(user);
            mockOwnableRoles.renounceRoles(rolesToRevoke);
        } else if (revokerIsOwner) {
            vm.expectEmit(true, true, true, true);
            emit RolesUpdated(_cleaned(user), rolesAfterRevoke);
            mockOwnableRoles.revokeRoles(user, rolesToRevoke);
        } else {
            vm.prank(user);
            vm.expectRevert(Ownable.Unauthorized.selector);
            mockOwnableRoles.revokeRoles(user, rolesToRevoke);
            return;
        }

        assertEq(mockOwnableRoles.rolesOf(user), rolesAfterRevoke);
    }

    function testHasAllRoles(
        address user,
        uint256 rolesToGrant,
        uint256 rolesToGrantBrutalizer,
        uint256 rolesToCheck,
        bool useSameRoles
    ) public {
        if (useSameRoles) {
            rolesToGrant = rolesToCheck;
        }
        rolesToGrant |= rolesToGrantBrutalizer;
        mockOwnableRoles.grantRoles(user, rolesToGrant);

        bool hasAllRoles = (rolesToGrant & rolesToCheck) == rolesToCheck;
        assertEq(mockOwnableRoles.hasAllRoles(user, rolesToCheck), hasAllRoles);
    }

    function testHasAnyRole(address user, uint256 rolesToGrant, uint256 rolesToCheck) public {
        mockOwnableRoles.grantRoles(user, rolesToGrant);
        assertEq(mockOwnableRoles.hasAnyRole(user, rolesToCheck), rolesToGrant & rolesToCheck != 0);
    }

    function testRolesFromOrdinals(uint8[] memory ordinals) public {
        uint256 roles;
        unchecked {
            for (uint256 i; i < ordinals.length; ++i) {
                roles |= 1 << uint256(ordinals[i]);
            }
        }
        assertEq(mockOwnableRoles.rolesFromOrdinals(ordinals), roles);
    }

    function testRolesFromOrdinals() public {
        unchecked {
            for (uint256 t; t != 32; ++t) {
                uint8[] memory ordinals = new uint8[](_random() % 32);
                for (uint256 i; i != ordinals.length; ++i) {
                    uint256 randomness = _random();
                    uint8 r;
                    assembly {
                        r := randomness
                    }
                    ordinals[i] = r;
                }
                testRolesFromOrdinals(ordinals);
            }
        }
    }

    function testOrdinalsFromRoles(uint256 roles) public {
        uint8[] memory ordinals = new uint8[](256);
        uint256 n;
        unchecked {
            for (uint256 i; i < 256; ++i) {
                if (roles & (1 << i) != 0) ordinals[n++] = uint8(i);
            }
        }
        uint8[] memory results = mockOwnableRoles.ordinalsFromRoles(roles);
        assertEq(results.length, n);
        unchecked {
            for (uint256 i; i < n; ++i) {
                assertEq(results[i], ordinals[i]);
            }
        }
    }

    function testOrdinalsFromRoles() public {
        unchecked {
            for (uint256 t; t != 32; ++t) {
                testOrdinalsFromRoles(_random());
            }
        }
    }

    function testOnlyOwnerModifier(address nonOwner, bool callerIsOwner) public {
        while (nonOwner == address(this)) nonOwner = _randomNonZeroAddress();

        if (!callerIsOwner) {
            vm.prank(nonOwner);
            vm.expectRevert(Ownable.Unauthorized.selector);
        }
        mockOwnableRoles.updateFlagWithOnlyOwner();
    }

    function testOnlyRolesModifier(address user, uint256 rolesToGrant, uint256 rolesToCheck)
        public
    {
        mockOwnableRoles.grantRoles(user, rolesToGrant);

        if (rolesToGrant & rolesToCheck == 0) {
            vm.expectRevert(Ownable.Unauthorized.selector);
        }
        vm.prank(user);
        mockOwnableRoles.updateFlagWithOnlyRoles(rolesToCheck);
    }

    function testOnlyOwnerOrRolesModifier(
        address user,
        bool callerIsOwner,
        uint256 rolesToGrant,
        uint256 rolesToCheck
    ) public {
        while (user == address(this)) user = _randomNonZeroAddress();

        mockOwnableRoles.grantRoles(user, rolesToGrant);

        if ((rolesToGrant & rolesToCheck == 0) && !callerIsOwner) {
            vm.expectRevert(Ownable.Unauthorized.selector);
        }
        if (!callerIsOwner) {
            vm.prank(user);
        }
        mockOwnableRoles.updateFlagWithOnlyOwnerOrRoles(rolesToCheck);
    }

    function testOnlyRolesOrOwnerModifier(
        address user,
        bool callerIsOwner,
        uint256 rolesToGrant,
        uint256 rolesToCheck
    ) public {
        while (user == address(this)) user = _randomNonZeroAddress();

        mockOwnableRoles.grantRoles(user, rolesToGrant);

        if ((rolesToGrant & rolesToCheck == 0) && !callerIsOwner) {
            vm.expectRevert(Ownable.Unauthorized.selector);
        }
        if (!callerIsOwner) {
            vm.prank(user);
        }
        mockOwnableRoles.updateFlagWithOnlyRolesOrOwner(rolesToCheck);
    }

    function testOnlyOwnerOrRolesModifier() public {
        testOnlyOwnerOrRolesModifier(address(1), false, 1, 2);
    }

    function testHandoverOwnership(address pendingOwner) public {
        vm.prank(pendingOwner);
        vm.expectEmit(true, true, true, true);
        emit OwnershipHandoverRequested(_cleaned(pendingOwner));
        mockOwnableRoles.requestOwnershipHandover();
        assertTrue(mockOwnableRoles.ownershipHandoverExpiresAt(pendingOwner) > block.timestamp);

        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), _cleaned(pendingOwner));

        mockOwnableRoles.completeOwnershipHandover(pendingOwner);

        assertEq(mockOwnableRoles.owner(), pendingOwner);
    }

    function testHandoverOwnership() public {
        testHandoverOwnership(address(1));
    }

    function testHandoverOwnershipRevertsIfCompleteIsNotOwner() public {
        address pendingOwner = address(1);
        vm.prank(pendingOwner);
        mockOwnableRoles.requestOwnershipHandover();

        vm.prank(pendingOwner);
        vm.expectRevert(Ownable.Unauthorized.selector);
        mockOwnableRoles.completeOwnershipHandover(pendingOwner);
    }

    function testHandoverOwnershipWithCancellation() public {
        address pendingOwner = address(1);

        vm.prank(pendingOwner);
        vm.expectEmit(true, true, true, true);
        emit OwnershipHandoverRequested(_cleaned(pendingOwner));
        mockOwnableRoles.requestOwnershipHandover();
        assertTrue(mockOwnableRoles.ownershipHandoverExpiresAt(pendingOwner) > block.timestamp);

        vm.expectEmit(true, true, true, true);
        emit OwnershipHandoverCanceled(_cleaned(pendingOwner));
        vm.prank(pendingOwner);
        mockOwnableRoles.cancelOwnershipHandover();
        assertEq(mockOwnableRoles.ownershipHandoverExpiresAt(pendingOwner), 0);
        vm.expectRevert(Ownable.NoHandoverRequest.selector);

        mockOwnableRoles.completeOwnershipHandover(pendingOwner);
    }

    function testHandoverOwnershipBeforeExpiration() public {
        address pendingOwner = address(1);
        vm.prank(pendingOwner);
        mockOwnableRoles.requestOwnershipHandover();

        vm.warp(block.timestamp + mockOwnableRoles.ownershipHandoverValidFor());

        mockOwnableRoles.completeOwnershipHandover(pendingOwner);
    }

    function testHandoverOwnershipAfterExpiration() public {
        address pendingOwner = address(1);
        vm.prank(pendingOwner);
        mockOwnableRoles.requestOwnershipHandover();

        vm.warp(block.timestamp + mockOwnableRoles.ownershipHandoverValidFor() + 1);

        vm.expectRevert(Ownable.NoHandoverRequest.selector);

        mockOwnableRoles.completeOwnershipHandover(pendingOwner);
    }

    function testOwnershipHandoverValidForDefaultValue() public {
        assertEq(mockOwnableRoles.ownershipHandoverValidFor(), 48 * 3600);
    }
}
