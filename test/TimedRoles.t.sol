// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibSort} from "../src/utils/LibSort.sol";
import {DynamicArrayLib} from "../src/utils/DynamicArrayLib.sol";
import "./utils/SoladyTest.sol";
import "./utils/mocks/MockTimedRoles.sol";

contract TimedRolesTest is SoladyTest {
    using DynamicArrayLib for *;

    event TimedRoleSet(
        address indexed holder, uint256 indexed timedRole, uint40 start, uint40 expires
    );

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
        uint40 expires;
    }

    function _sampleTimedRoleConfig() internal returns (TimedRoleConfig memory c) {
        uint256 m = 0xf00000000000000000000000000000000000000000000000000000000000000f;
        c.holder = _randomNonZeroAddress();
        c.role = _randomUniform() & m;
        (c.start, c.expires) = _sampleValidActiveTimeRange();
    }

    function _hasDuplicateKeys(TimedRoleConfig[] memory a) internal pure returns (bool) {
        bytes32[] memory hashes = new bytes32[](a.length);
        for (uint256 i; i != a.length; ++i) {
            hashes[i] = keccak256(abi.encode(a[i].holder, a[i].role));
        }
        LibSort.insertionSort(hashes);
        LibSort.uniquifySorted(hashes);
        return hashes.length != a.length;
    }

    function _sampleTimedRoleConfigs() internal returns (TimedRoleConfig[] memory a) {
        a = new TimedRoleConfig[](_randomUniform() & 3);
        for (uint256 i; i != a.length; ++i) {
            a[i] = _sampleTimedRoleConfig();
        }
    }

    function _sampleActiveTimeRange() internal returns (uint40 start, uint40 expires) {
        if (_randomChance(2)) {
            start = uint40(_random());
            expires = uint40(_random());
        } else {
            start = uint8(_random());
            expires = uint8(_random());
        }
    }

    function _sampleValidActiveTimeRange() internal returns (uint40 start, uint40 expires) {
        do {
            (start, expires) = _sampleActiveTimeRange();
        } while (expires < start);
    }

    function _sampleInvalidActiveTimeRange() internal returns (uint40 start, uint40 expires) {
        do {
            (start, expires) = _sampleActiveTimeRange();
        } while (!(expires < start));
    }

    function testSetAndGetTimedRoles(bytes32) public {
        TimedRoleConfig[] memory a = _sampleTimedRoleConfigs();

        uint256 targetTimestamp = _bound(_random(), 0, _randomChance(2) ? 0xff : 2 ** 41 - 1);
        vm.warp(targetTimestamp);

        for (uint256 i; i != a.length; ++i) {
            TimedRoleConfig memory c = a[i];
            vm.expectEmit(true, true, true, true);
            emit TimedRoleSet(c.holder, c.role, c.start, c.expires);
            mockTimedRoles.setTimedRole(c.holder, c.role, c.start, c.expires);
            (bool isActive, uint40 start, uint40 expires) =
                mockTimedRoles.timedRoleActive(c.holder, c.role);
            assertEq(start, c.start);
            assertEq(expires, c.expires);
            assertEq(isActive, start <= targetTimestamp && targetTimestamp <= expires);
        }
        if (!_hasDuplicateKeys(a)) {
            for (uint256 i; i != a.length; ++i) {
                TimedRoleConfig memory c = a[i];
                (bool isActive, uint40 start, uint40 expires) =
                    mockTimedRoles.timedRoleActive(c.holder, c.role);
                assertEq(start, c.start);
                assertEq(expires, c.expires);
                assertEq(isActive, start <= targetTimestamp && targetTimestamp <= expires);
            }
        }
        if (_randomChance(16)) {
            TimedRoleConfig memory c = _sampleTimedRoleConfig();
            (c.start, c.expires) = _sampleInvalidActiveTimeRange();
            vm.expectRevert(TimedRoles.InvalidTimedRoleRange.selector);
            mockTimedRoles.setTimedRole(c.holder, c.role, c.start, c.expires);
        }
        if (_randomChance(16)) {
            TimedRoleConfig memory c = _sampleTimedRoleConfig();
            mockTimedRoles.setOwner(_randomUniqueHashedAddress());
            vm.expectRevert(TimedRoles.TimedRolesUnauthorized.selector);
            mockTimedRoles.setTimedRole(c.holder, c.role, c.start, c.expires);
            mockTimedRoles.setOwner(address(this));
            if (_randomChance(16)) {
                c.holder = address(0);
                vm.expectRevert(TimedRoles.TimedRoleHolderIsZeroAddress.selector);
            }
            mockTimedRoles.setTimedRole(c.holder, c.role, c.start, c.expires);
        }
        if (_randomChance(16)) {
            uint256 maxTimedRole = _random();
            mockTimedRoles.setMaxTimedRole(maxTimedRole);
            TimedRoleConfig memory c = _sampleTimedRoleConfig();
            if (c.role > maxTimedRole) {
                vm.expectRevert(TimedRoles.InvalidTimedRole.selector);
            }
            mockTimedRoles.setTimedRole(c.holder, c.role, c.start, c.expires);
        }
    }

    function testTimedRolesModifiers(bytes32) public {
        TimedRoleConfig memory c = _sampleTimedRoleConfig();
        c.start = 0;
        c.expires = 0xffffffffff;
        mockTimedRoles.setTimedRole(c.holder, c.role, c.start, c.expires);
        uint256[] memory allowedTimeRoles = _sampleRoles(3);
        mockTimedRoles.setAllowedTimedRole(allowedTimeRoles[0]);
        vm.warp(_bound(_randomUniform(), c.start, c.expires));

        if (allowedTimeRoles[0] == c.role) {
            vm.prank(c.holder);
            mockTimedRoles.guardedByOnlyOwnerOrTimedRole();
        } else {
            vm.prank(c.holder);
            vm.expectRevert(TimedRoles.TimedRolesUnauthorized.selector);
            mockTimedRoles.guardedByOnlyOwnerOrTimedRole();
        }

        mockTimedRoles.setAllowedTimedRolesEncoded(abi.encodePacked(allowedTimeRoles));

        if (allowedTimeRoles.contains(c.role)) {
            vm.prank(c.holder);
            mockTimedRoles.guardedByOnlyOwnerOrTimedRoles();
        } else {
            vm.prank(c.holder);
            vm.expectRevert(TimedRoles.TimedRolesUnauthorized.selector);
            mockTimedRoles.guardedByOnlyOwnerOrTimedRoles();
        }

        if (_randomChance(128)) {
            mockTimedRoles.guardedByOnlyOwnerOrTimedRole();
            mockTimedRoles.guardedByOnlyOwnerOrTimedRoles();
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
