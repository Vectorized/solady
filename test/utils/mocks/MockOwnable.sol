// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from "../../../src/auth/Ownable.sol";

contract MockOwnable is Ownable {
    bool public flag;

    constructor() payable {
        _initializeOwner(msg.sender);

        // Perform the tests on the helper functions.

        address brutalizedAddress = _brutalizedAddress(address(0));
        bool brutalizedAddressIsBrutalized;
        /// @solidity memory-safe-assembly
        assembly {
            brutalizedAddressIsBrutalized := gt(shr(160, brutalizedAddress), 0)
        }

        if (!brutalizedAddressIsBrutalized) {
            revert("Setup failed");
        }
    }

    function initializeOwnerDirect(address newOwner) public payable {
        _initializeOwner(_brutalizedAddress(newOwner));
    }

    function setOwnerDirect(address newOwner) public payable {
        _setOwner(_brutalizedAddress(newOwner));
    }

    function completeOwnershipHandover(address pendingOwner) public payable virtual override {
        super.completeOwnershipHandover(_brutalizedAddress(pendingOwner));
    }

    function transferOwnership(address newOwner) public payable virtual override {
        super.transferOwnership(_brutalizedAddress(newOwner));
    }

    function ownershipHandoverExpiresAt(address pendingOwner)
        public
        view
        virtual
        override
        returns (uint256 result)
    {
        result = super.ownershipHandoverExpiresAt(_brutalizedAddress(pendingOwner));
    }

    function ownershipHandoverValidFor() public view virtual override returns (uint64 result) {
        result = super.ownershipHandoverValidFor();
        /// @solidity memory-safe-assembly
        assembly {
            // Some acrobatics to make the brutalized bits psuedorandomly
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

    function _brutalizedAddress(address value) private view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Some acrobatics to make the brutalized bits psuedorandomly
            // different with every call.
            mstore(0x00, or(calldataload(0), mload(0x40)))
            mstore(0x20, or(caller(), mload(0x00)))
            result := or(shl(160, keccak256(0x00, 0x40)), value)
            mstore(0x40, add(0x20, mload(0x40)))
            mstore(0x00, result)
        }
    }
}
