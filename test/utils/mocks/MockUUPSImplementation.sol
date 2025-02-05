// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {UUPSUpgradeable} from "../../../src/utils/UUPSUpgradeable.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockUUPSImplementation is UUPSUpgradeable, Brutalizer {
    uint256 public value;

    address public owner;

    error Unauthorized();

    error CustomError(address owner_);

    uint256 public x;

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

    function upgradeToAndCall(address newImplementation, bytes calldata data)
        public
        payable
        override
    {
        super.upgradeToAndCall(_brutalized(newImplementation), data);
    }

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
