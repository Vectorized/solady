// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockImplementation {
    error Fail();

    mapping(uint256 => uint256) internal _values;

    function fails() external pure {
        revert Fail();
    }

    function succeeds(uint256 a) external pure returns (uint256) {
        return a;
    }

    function setValue(uint256 key, uint256 value) external payable {
        _values[key] = value;
    }

    function getValue(uint256 key) external view returns (uint256) {
        return _values[key];
    }
}
