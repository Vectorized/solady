// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {LibClone} from "../src/utils/LibClone.sol";

contract LibCloneTest is Test {
    error CustomError(uint256 currentValue);

    uint256 public value;

    mapping(bytes32 => bool) saltIsUsed;

    function setUp() public {
        value += 1;
    }

    function setValue(uint256 value_) public {
        value = value_;
    }

    function revertWithError() public view {
        revert CustomError(value);
    }

    function _shouldBehaveLikeClone(address clone, uint256 value_) internal {
        uint256 thisValue = this.value();
        if (thisValue == value_) {
            value_ ^= 1;
        }
        LibCloneTest(clone).setValue(value_);
        assertEq(value_, LibCloneTest(clone).value());
        assertEq(thisValue, this.value());
        vm.expectRevert(abi.encodeWithSelector(CustomError.selector, value_));
        LibCloneTest(clone).revertWithError();
    }

    function testClone(uint256 value_) public {
        address clone = LibClone.clone(address(this));
        _shouldBehaveLikeClone(clone, value_);
    }

    function testClone() public {
        testClone(1);
    }

    function testCloneDeterministic(uint256 value_, bytes32 salt) public {
        if (saltIsUsed[salt]) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
        }
        address clone = LibClone.cloneDeterministic(address(this), salt);
        saltIsUsed[salt] = true;

        _shouldBehaveLikeClone(clone, value_);
        assertTrue(clone != address(0));

        address predicted = LibClone.predictDeterministicAddress(address(this), salt, address(this));
        assertEq(clone, predicted);
    }

    function testCloneDeterministicRevertsIfAddressAlreadyUsed() public {
        testCloneDeterministic(1, keccak256("a"));
        testCloneDeterministic(1, keccak256("a"));
    }

    function testCloneDeterministic() public {
        testCloneDeterministic(1, keccak256("b"));
    }
}
