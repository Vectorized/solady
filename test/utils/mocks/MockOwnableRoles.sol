// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnableRoles} from "../../../src/auth/OwnableRoles.sol";

contract MockOwnableRoles is OwnableRoles {
    bool public flag;

    constructor() {
        _initializeOwner(msg.sender);

        // Perform the tests on the helper functions.

        address brutalizedAddress = _brutalizedAddress(address(0));
        bool brutalizedAddressIsBrutalized;
        assembly {
            brutalizedAddressIsBrutalized := gt(shr(160, brutalizedAddress), 0)
        }

        if (!brutalizedAddressIsBrutalized) {
            revert("Setup failed");
        }

        bool badBool;
        assembly {
            badBool := 2
        }

        bool checkedBadBool = _checkedBool(badBool);

        if (checkedBadBool) {
            revert("Setup failed");
        }
    }

    function initializeOwnerDirect(address newOwner) public {
        _initializeOwner(_brutalizedAddress(newOwner));
    }

    function setOwnerDirect(address newOwner) public {
        _setOwner(_brutalizedAddress(newOwner));
    }

    function grantRolesDirect(address user, uint256 roles) public {
        _grantRoles(_brutalizedAddress(user), roles);
    }

    function removeRolesDirect(address user, uint256 roles) public {
        _removeRoles(_brutalizedAddress(user), roles);
    }

    function grantRoles(address user, uint256 roles) public virtual override(OwnableRoles) {
        OwnableRoles.grantRoles(_brutalizedAddress(user), roles);
    }

    function revokeRoles(address user, uint256 roles) public virtual override(OwnableRoles) {
        OwnableRoles.revokeRoles(_brutalizedAddress(user), roles);
    }

    function completeOwnershipHandover(address pendingOwner) public virtual override(OwnableRoles) {
        OwnableRoles.completeOwnershipHandover(_brutalizedAddress(pendingOwner));
    }

    function hasAnyRole(address user, uint256 roles) public view virtual override(OwnableRoles) returns (bool result) {
        result = _checkedBool(OwnableRoles.hasAnyRole(_brutalizedAddress(user), roles));
    }

    function hasAllRoles(address user, uint256 roles) public view virtual override(OwnableRoles) returns (bool result) {
        result = _checkedBool(OwnableRoles.hasAllRoles(_brutalizedAddress(user), roles));
    }

    function transferOwnership(address newOwner) public virtual override(OwnableRoles) {
        OwnableRoles.transferOwnership(_brutalizedAddress(newOwner));
    }

    function rolesOf(address user) public view virtual override(OwnableRoles) returns (uint256 result) {
        result = OwnableRoles.rolesOf(_brutalizedAddress(user));
    }

    function ownershipHandoverExpiresAt(address pendingOwner)
        public
        view
        virtual
        override(OwnableRoles)
        returns (uint256 result)
    {
        result = OwnableRoles.ownershipHandoverExpiresAt(_brutalizedAddress(pendingOwner));
    }

    function ownershipHandoverValidFor() public view virtual override(OwnableRoles) returns (uint64 result) {
        result = OwnableRoles.ownershipHandoverValidFor();
        assembly {
            // Some acrobatics to make the brutalized bits psuedorandomly
            // different with every call.
            mstore(0x00, or(calldataload(0), mload(0x40)))
            mstore(0x20, or(timestamp(), mload(0x00)))
            // Just brutalize the upper unused bits of the result to see if it causes any issue.
            result := or(shl(64, keccak256(0x00, 0x40)), result)
            mstore(0x40, add(0x20, mload(0x40)))
            mstore(0x00, result)
        }
    }

    function updateFlagWithOnlyOwner() public onlyOwner {
        flag = true;
    }

    function updateFlagWithOnlyRoles(uint256 roles) public onlyRoles(roles) {
        flag = true;
    }

    function updateFlagWithOnlyOwnerOrRoles(uint256 roles) public onlyOwnerOrRoles(roles) {
        flag = true;
    }

    function updateFlagWithOnlyRolesOrOwner(uint256 roles) public onlyRolesOrOwner(roles) {
        flag = true;
    }

    function _brutalizedAddress(address value) private view returns (address result) {
        assembly {
            // Some acrobatics to make the brutalized bits psuedorandomly
            // different with every call.
            mstore(0x00, or(calldataload(0), mload(0x40)))
            mstore(0x20, or(timestamp(), mload(0x00)))
            result := or(shl(160, keccak256(0x00, 0x40)), value)
            mstore(0x40, add(0x20, mload(0x40)))
            mstore(0x00, result)
        }
    }

    function _checkedBool(bool value) private pure returns (bool result) {
        result = value;
        bool resultIsOneOrZero;
        assembly {
            // We wanna check if the result is either 1 or 0,
            // to make sure we practice good assembly politeness.
            resultIsOneOrZero := lt(result, 2)
        }
        if (!resultIsOneOrZero) result = !result;
    }
}
