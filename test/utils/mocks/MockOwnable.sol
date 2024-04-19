// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from "../../../src/auth/Ownable.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockOwnable is Ownable, Brutalizer {
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
    }

    function initializeOwnerDirect(address newOwner) public payable {
        _initializeOwner(_brutalized(newOwner));
    }

    function setOwnerDirect(address newOwner) public payable {
        _setOwner(_brutalized(newOwner));
    }

    function completeOwnershipHandover(address pendingOwner) public payable virtual override {
        super.completeOwnershipHandover(_brutalized(pendingOwner));
    }

    function transferOwnership(address newOwner) public payable virtual override {
        super.transferOwnership(_brutalized(newOwner));
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
}

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockOwnableBytecodeSizer is Ownable {
    constructor() payable {
        initialize();
    }

    function initialize() public payable {
        _initializeOwner(msg.sender);
    }
}
