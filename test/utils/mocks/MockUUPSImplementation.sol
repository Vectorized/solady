// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {UUPSUpgradeable} from "../../../src/utils/UUPSUpgradeable.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockUUPSImplementation is UUPSUpgradeable, Brutalizer {
    uint256 public value;

    address public owner;

    /// @dev Storage layout version hash for upgrade compatibility checks.
    bytes32 private constant _STORAGE_LAYOUT_VERSION =
        0x7b86195f14c03aa21c7b6881091a51da39658e244432de468f62f9387ca79dba;
    // keccak256("solady.mock.uups.v1")

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

    /// @dev Returns the storage layout version for compatibility verification.
    function STORAGE_LAYOUT_VERSION() external pure returns (bytes32) {
        return _STORAGE_LAYOUT_VERSION;
    }

    /// @dev Checks storage layout compatibility by comparing version hashes.
    function _checkStorageLayout(address newImpl) internal view override {
        bytes32 expected = _STORAGE_LAYOUT_VERSION;

        /// @solidity memory-safe-assembly
        assembly {
            // Skip check if `newImpl` has no code to preserve standard UUPS errors.
            if extcodesize(newImpl) {
                mstore(0x00, 0xa19f05fc) // `STORAGE_LAYOUT_VERSION()`
                if iszero(staticcall(gas(), newImpl, 0x1c, 0x04, 0x00, 0x20)) {
                    mstore(0x00, 0xc2fbd48f) // `StorageLayoutMismatch()`
                    revert(0x1c, 0x04)
                }
                if iszero(eq(mload(0x00), expected)) {
                    mstore(0x00, 0xc2fbd48f) // `StorageLayoutMismatch()`
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    function revertWithError() public view {
        revert CustomError(owner);
    }

    function setValue(uint256 val_) public {
        value = val_;
    }

    function upgradeToAndCall(address newImplementation, bytes calldata data)
        public
        payable
        override
    {
        super.upgradeToAndCall(_brutalized(newImplementation), data);
    }
}
