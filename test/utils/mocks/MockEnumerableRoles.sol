// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableRoles} from "../../../src/auth/EnumerableRoles.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockEnumerableRoles is EnumerableRoles, Brutalizer {
    struct MockEnumerableRolesStorage {
        uint256 maxRole;
        bool maxRoleReverts;
        address owner;
        bool ownerReverts;
        bytes allowedRolesEncoded;
        uint256 allowedRole;
    }

    event Yo();

    MockEnumerableRolesStorage internal $;

    function setOwner(address value) public {
        $.owner = value;
    }

    function setOwnerReverts(bool value) public {
        $.ownerReverts = value;
    }

    function setMaxRole(uint256 value) public {
        $.maxRole = value;
    }

    function setMaxRoleReverts(bool value) public {
        $.maxRoleReverts = value;
    }

    function MAX_ROLE() public view returns (uint256) {
        if ($.maxRoleReverts) revert();
        return $.maxRole;
    }

    function owner() public view returns (address) {
        if ($.ownerReverts) revert();
        return $.owner;
    }

    function setRoleDirect(address holder, uint256 role, bool active) public {
        _setRole(_brutalized(holder), role, active);
    }

    function hasAnyRoles(address holder, bytes memory encodedRoles) public view returns (bool) {
        return _hasAnyRoles(_brutalized(holder), encodedRoles);
    }

    function setAllowedRolesEncoded(bytes memory value) public {
        $.allowedRolesEncoded = value;
    }

    function setAllowedRole(uint256 role) public {
        $.allowedRole = role;
    }

    function guardedByOnlyOwnerOrRoles() public onlyOwnerOrRoles($.allowedRolesEncoded) {
        emit Yo();
    }

    function guardedByOnlyOwnerOrRole() public onlyOwnerOrRole($.allowedRole) {
        emit Yo();
    }

    function guardedByOnlyRoles() public onlyRoles($.allowedRolesEncoded) {
        emit Yo();
    }
}
