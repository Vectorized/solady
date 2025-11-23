// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {UUPSUpgradeable} from "../../../src/utils/UUPSUpgradeable.sol";

contract MockUUPSWithDifferentLayout is UUPSUpgradeable {
    bool public extraVar; // Breaks layout compatibility
    uint256 public value;
    address public owner;

    /// @dev Intentionally different version to trigger mismatch.
    bytes32 private constant _STORAGE_LAYOUT_VERSION =
        0xbe1c9475ae85c040745b734fec444fcbc3d6e069d8e0b5027394bd8b0a614f94;
    // keccak256("solady.mock.uups.incompatible.v1")

    function _authorizeUpgrade(address) internal view override {
        require(msg.sender == address(this), "unauthorized");
    }

    /// @dev Returns incompatible version hash to test mismatch detection.
    function STORAGE_LAYOUT_VERSION() external pure returns (bytes32) {
        return _STORAGE_LAYOUT_VERSION;
    }

    /// @dev No-op override to skip layout check (for negative testing).
    function _checkStorageLayout(address) internal pure override {}
}
