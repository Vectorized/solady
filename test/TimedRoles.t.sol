// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibSort} from "../src/utils/LibSort.sol";
import "./utils/SoladyTest.sol";
import "./utils/mocks/MockTimedRoles.sol";

contract TimedRolesTest is SoladyTest {
    event TimedRoleSet(address indexed holder, uint256 indexed timedRole, uint40 start, uint40 end);

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

    function _sampleTimedRoleConfig() internal returns (TimedRoleConfig memory c) {
        uint256 m = 0xf00000000000000000000000000000000000000000000000000000000000000f;
        c.holder = _randomNonZeroAddress();
        c.role = _randomUniform() & m;
        (c.start, c.end) = _sampleValidActiveTimeRange();
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

    function _sampleValidActiveTimeRange() internal returns (uint40 start, uint40 end) {
        do {
            start = uint40(_random());
            end = uint40(_random());
        } while (end < start);
    }

    function _sampleInvalidActiveTimeRange() internal returns (uint40 start, uint40 end) {
        do {
            start = uint40(_random());
            end = uint40(_random());
        } while (!(end < start));
    }

    function testSetAndGetRoles(bytes32) public {
        TimedRoleConfig[] memory a = _sampleTimedRoleConfigs();

        uint256 targetTimestamp = _bound(_random(), 0, 2 ** 41 - 1);
        vm.warp(targetTimestamp);

        for (uint256 i; i != a.length; ++i) {
            TimedRoleConfig memory c = a[i];
            vm.expectEmit(true, true, true, true);
            emit TimedRoleSet(c.holder, c.role, c.start, c.end);
            mockTimedRoles.setTimedRole(c.holder, c.role, c.start, c.end);
            (bool isActive, uint40 start, uint40 end) =
                mockTimedRoles.timedRoleActive(c.holder, c.role);
            assertEq(start, c.start);
            assertEq(end, c.end);
            assertEq(isActive, start <= targetTimestamp && targetTimestamp < end);
        }
        if (!_hasDuplicateKeys(a)) {
            for (uint256 i; i != a.length; ++i) {
                TimedRoleConfig memory c = a[i];
                (bool isActive, uint40 start, uint40 end) =
                    mockTimedRoles.timedRoleActive(c.holder, c.role);
                assertEq(start, c.start);
                assertEq(end, c.end);
                assertEq(isActive, start <= targetTimestamp && targetTimestamp < end);
            }
        }
        if (_randomChance(16)) {
            TimedRoleConfig memory c = _sampleTimedRoleConfig();
            (c.start, c.end) = _sampleInvalidActiveTimeRange();
            vm.expectRevert(TimedRoles.InvalidTimedRoleRange.selector);
            mockTimedRoles.setTimedRole(c.holder, c.role, c.start, c.end);
        }
        if (_randomChance(16)) {
            TimedRoleConfig memory c = _sampleTimedRoleConfig();
            mockTimedRoles.setOwner(_randomUniqueHashedAddress());
            vm.expectRevert(TimedRoles.TimedRolesUnauthorized.selector);
            mockTimedRoles.setTimedRole(c.holder, c.role, c.start, c.end);
            mockTimedRoles.setOwner(address(this));
            if (_randomChance(16)) {
                c.holder = address(0);
                vm.expectRevert(TimedRoles.TimedRoleHolderIsZeroAddress.selector);
            }
            mockTimedRoles.setTimedRole(c.holder, c.role, c.start, c.end);
        }
        if (_randomChance(16)) {
            uint256 maxTimedRole = _random();
            mockTimedRoles.setMaxTimedRole(maxTimedRole);
            TimedRoleConfig memory c = _sampleTimedRoleConfig();
            if (c.role > maxTimedRole) {
                vm.expectRevert(TimedRoles.InvalidTimedRole.selector);
            }
            mockTimedRoles.setTimedRole(c.holder, c.role, c.start, c.end);
        }
    }
}
