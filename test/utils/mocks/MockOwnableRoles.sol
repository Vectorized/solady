// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable, OwnableRoles} from "../../../src/auth/OwnableRoles.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockOwnableRoles is OwnableRoles, Brutalizer {
    bool public flag;

    constructor() payable {
        _initializeOwner(msg.sender);

        // Perform the tests on the helper functions.

        address brutalizedAddress = _brutalized(address(0));
        bool brutalizedAddressIsBrutalized;
        /// @solidity memory-safe-assembly
        assembly {
            brutalizedAddressIsBrutalized := gt(shr(160, brutalizedAddress), 0)
        }

        if (!brutalizedAddressIsBrutalized) {
            revert("Setup failed");
        }

        bool badBool;
        /// @solidity memory-safe-assembly
        assembly {
            badBool := 2
        }

        bool checkedBadBool = _checkedBool(badBool);

        if (checkedBadBool) {
            revert("Setup failed");
        }
    }

    function initializeOwnerDirect(address newOwner) public payable {
        _initializeOwner(_brutalized(newOwner));
    }

    function setOwnerDirect(address newOwner) public payable {
        _setOwner(_brutalized(newOwner));
    }

    function setRolesDirect(address user, uint256 roles) public payable {
        _setRoles(_brutalized(user), roles);
    }

    function grantRolesDirect(address user, uint256 roles) public payable {
        _grantRoles(_brutalized(user), roles);
    }

    function removeRolesDirect(address user, uint256 roles) public payable {
        _removeRoles(_brutalized(user), roles);
    }

    function grantRoles(address user, uint256 roles) public payable virtual override {
        super.grantRoles(_brutalized(user), roles);
    }

    function revokeRoles(address user, uint256 roles) public payable virtual override {
        super.revokeRoles(_brutalized(user), roles);
    }

    function completeOwnershipHandover(address pendingOwner) public payable virtual override {
        super.completeOwnershipHandover(_brutalized(pendingOwner));
    }

    function transferOwnership(address newOwner) public payable virtual override {
        super.transferOwnership(_brutalized(newOwner));
    }

    function rolesOf(address user) public view virtual override returns (uint256 result) {
        result = super.rolesOf(_brutalized(user));
    }

    function ownershipHandoverExpiresAt(address pendingOwner)
        public
        view
        virtual
        override
        returns (uint256 result)
    {
        result = super.ownershipHandoverExpiresAt(_brutalized(pendingOwner));
    }

    function ownershipHandoverValidFor() public view returns (uint64 result) {
        result = _ownershipHandoverValidFor();
        /// @solidity memory-safe-assembly
        assembly {
            // Some acrobatics to make the brutalized bits pseudorandomly
            // different with every call.
            mstore(0x00, or(calldataload(0), mload(0x40)))
            mstore(0x20, or(caller(), mload(0x00)))
            // Just brutalize the upper unused bits of the result to see if it causes any issue.
            result := or(shl(64, keccak256(0x00, 0x40)), result)
            mstore(0x40, add(0x20, mload(0x40)))
            mstore(0x00, result)
        }
    }

    function updateFlagWithOnlyOwner() public payable onlyOwner {
        flag = true;
    }

    function updateFlagWithOnlyRoles(uint256 roles) public payable onlyRoles(roles) {
        flag = true;
    }

    function updateFlagWithOnlyOwnerOrRoles(uint256 roles) public payable onlyOwnerOrRoles(roles) {
        flag = true;
    }

    function updateFlagWithOnlyRolesOrOwner(uint256 roles) public payable onlyRolesOrOwner(roles) {
        flag = true;
    }

    function rolesFromOrdinals(uint8[] memory ordinals) public pure returns (uint256 roles) {
        roles = _rolesFromOrdinals(ordinals);
    }

    function ordinalsFromRoles(uint256 roles) public pure returns (uint8[] memory ordinals) {
        ordinals = _ordinalsFromRoles(roles);
    }

    function _checkedBool(bool value) private pure returns (bool result) {
        result = value;
        bool resultIsOneOrZero;
        /// @solidity memory-safe-assembly
        assembly {
            // We wanna check if the result is either 1 or 0,
            // to make sure we practice good assembly politeness.
            resultIsOneOrZero := lt(result, 2)
        }
        if (!resultIsOneOrZero) result = !result;
    }
}

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockOwnableRolesBytecodeSizer is OwnableRoles {
    constructor() payable {
        initialize();
    }

    function initialize() public payable {
        _initializeOwner(msg.sender);
    }
}
