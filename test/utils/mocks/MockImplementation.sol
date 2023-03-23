// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MockImplementation {
    error Fail();

    uint256 public x;

    function fails() external pure {
        revert Fail();
    }

    function succeeds(uint256 a) external pure returns (uint256) {
        return a;
    }

    function setX(uint256 value) external {
        x = value;
    }
}
