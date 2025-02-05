// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MockUUPSImplementation} from "./MockUUPSImplementation.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockCallContextChecker is MockUUPSImplementation {
    uint256 public x;

    function checkOnlyProxy() public view returns (bool) {
        _checkOnlyProxy();
        return true;
    }

    function checkNotDelegated() public view returns (bool) {
        _checkNotDelegated();
        return true;
    }

    function checkOnlyEIP7702Authority() public view returns (bool) {
        _checkOnlyEIP7702Authority();
        return true;
    }

    function setX(uint256 newX) public {
        x = newX;
    }
}
