// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {UUPSUpgradeable} from "../../../src/utils/UUPSUpgradeable.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockUUPSImplementation is UUPSUpgradeable {
    uint256 public value;

    address owner;

    error Unauthorized();

    error CustomError(address owner_);

    function initialize(address owner_) public {
        owner = owner_;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function revertWithError() public view {
        revert CustomError(owner);
    }

    function setValue(uint256 val_) public {
        value = val_;
    }

    function upgradeTo(address newImplemenation) public payable override {
        super.upgradeTo(_brutalized(newImplemenation));
    }

    function _brutalized(address a) private pure returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(a, shl(160, 0x0123456789abcdeffedcba98))
        }
    }
}
