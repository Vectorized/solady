// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TimedRoles} from "../../../src/auth/TimedRoles.sol";
import {EnumerableRoles} from "../../../src/auth/EnumerableRoles.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockTimedRoles is TimedRoles, EnumerableRoles, Brutalizer {
    struct MockTimedRolesStorage {
        uint256 maxTimedRole;
        bool maxTimedRoleReverts;
        address owner;
        bool ownerReverts;
        bytes allowedTimedRolesEncoded;
        uint256 allowedTimedRole;
    }

    event Yo();

    MockTimedRolesStorage internal $;

    function setOwner(address value) public {
        $.owner = value;
    }

    function setOwnerReverts(bool value) public {
        $.ownerReverts = value;
    }

    function setMaxTimedRole(uint256 value) public {
        $.maxTimedRole = value;
    }

    function setMaxTimedRoleReverts(bool value) public {
        $.maxTimedRoleReverts = value;
    }

    function MAX_TIMED_ROLE() public view returns (uint256) {
        if ($.maxTimedRoleReverts) revert();
        return $.maxTimedRole;
    }

    function owner() public view returns (address) {
        if ($.ownerReverts) revert();
        return $.owner;
    }

    function setTimedRoleDirect(address holder, uint256 timedRole, uint40 start, uint40 end)
        public
    {
        _setTimedRole(_brutalized(holder), timedRole, start, end);
    }

    function hasAnyTimedRoles(address holder, bytes memory encodedTimedRoles)
        public
        view
        returns (bool)
    {
        return _hasAnyTimedRoles(_brutalized(holder), encodedTimedRoles);
    }

    function setAllowedTimedRolesEncoded(bytes memory value) public {
        $.allowedTimedRolesEncoded = value;
    }

    function setAllowedTimedRole(uint256 timedRole) public {
        $.allowedTimedRole = timedRole;
    }

    function guardedByOnlyOwnerOrTimedRoles()
        public
        onlyOwnerOrTimedRoles($.allowedTimedRolesEncoded)
    {
        emit Yo();
    }

    function guardedByOnlyOwnerOrTimedRole() public onlyOwnerOrTimedRole($.allowedTimedRole) {
        emit Yo();
    }

    function guardedByOnlyTimedRoles() public onlyTimedRoles($.allowedTimedRolesEncoded) {
        emit Yo();
    }
}
