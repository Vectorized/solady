// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./utils/SoladyTest.sol";
import {LibTransient} from "../src/utils/LibTransient.sol";

contract LibTransientTest is SoladyTest {
    using LibTransient for *;

    function testSetAndGetBytesTransient() public {
        _testSetAndGetBytesTransient("123");
        _testSetAndGetBytesTransient("12345678901234567890123456789012345678901234567890");
        _testSetAndGetBytesTransient("123");
    }

    function _testSetAndGetBytesTransient(bytes memory data) internal {
        LibTransient.TBytes storage p = LibTransient.tBytes(uint256(0));
        p.set(data);
        assertEq(p.length(), data.length);
        assertEq(p.get(), data);
    }

    function testSetAndGetBytesTransientCalldata(
        uint256 tSlot,
        bytes calldata data0,
        bytes calldata data1
    ) public {
        unchecked {
            LibTransient.TBytes storage p0 = LibTransient.tBytes(tSlot);
            LibTransient.TBytes storage p1 = LibTransient.tBytes(tSlot + 1);
            if (_randomChance(2)) {
                p0.setCalldata(data0);
                p1.setCalldata(data1);
            } else {
                p0.set(data0);
                p1.set(data1);
            }
            assertEq(p0.get(), data0);
            assertEq(p1.get(), data1);
            if (_randomChance(2)) {
                p0.setCalldata(data1);
                p1.setCalldata(data0);
            } else {
                p0.set(data1);
                p1.set(data0);
            }
            assertEq(p0.get(), data1);
            assertEq(p1.get(), data0);
        }
    }

    function testSetAndGetBytesTransient(uint256 tSlot, bytes memory data) public {
        LibTransient.TBytes storage p = LibTransient.tBytes(tSlot);
        if (_randomChance(8)) data = _randomBytes();
        p.set(data);
        assertEq(p.length(), data.length);
        if (_randomChance(8)) {
            _misalignFreeMemoryPointer();
            _brutalizeMemory();
        }
        bytes memory retrieved = p.get();
        _checkMemory(retrieved);
        assertEq(retrieved, data);
        p.clear();
        assertEq(p.length(), 0);
        assertEq(p.get(), "");
    }

    function testSetAndGetBytesTransientCalldata(uint256 tSlot, bytes calldata data) public {
        LibTransient.TBytes storage p = LibTransient.tBytes(tSlot);
        p.set(data);
        assertEq(p.length(), data.length);
        assertEq(p.get(), data);
        p.clear();
        assertEq(p.length(), 0);
        assertEq(p.get(), "");
    }

    function testSetAndGetUint256Transient(uint256 tSlot, uint256 value) public {
        LibTransient.TUint256 storage p = LibTransient.tUint256(tSlot);
        p.set(value);
        assertEq(p.get(), value);
        p.clear();
        assertEq(p.get(), 0);
    }

    function testSetAndGetAddressTransient(uint256 tSlot, address value) public {
        LibTransient.TAddress storage p = LibTransient.tAddress(tSlot);
        p.set(_brutalized(value));
        assertEq(p.get(), value);
        p.clear();
        assertEq(p.get(), address(0));
    }

    function testSetAndGetBytes32Transient(uint256 tSlot, bytes32 value) public {
        LibTransient.TBytes32 storage p = LibTransient.tBytes32(tSlot);
        p.set(value);
        assertEq(p.get(), value);
        p.clear();
        assertEq(p.get(), bytes32(0));
    }

    function testSetAndGetBoolTransient(uint256 tSlot, bool value) public {
        LibTransient.TBool storage p = LibTransient.tBool(tSlot);
        p.set(_brutalized(value));
        assertEq(p.get(), value);
        p.clear();
        assertEq(p.get(), false);
    }

    function testUint256IncDecTransient() public {
        uint256 tSlot;
        LibTransient.TUint256 storage p = LibTransient.tUint256(tSlot);
        p.set(10);
        assertEq(this.tUintInc(tSlot), 11);
        assertEq(p.get(), 11);
        assertEq(this.tUintInc(tSlot, 20), 31);
        assertEq(p.get(), 31);
        p.set(2 ** 256 - 2);
        assertEq(this.tUintInc(tSlot), 2 ** 256 - 1);
        assertEq(p.get(), 2 ** 256 - 1);
        vm.expectRevert();
        this.tUintInc(tSlot);
        vm.expectRevert();
        this.tUintInc(tSlot, 10);
        assertEq(this.tUintDec(tSlot), 2 ** 256 - 2);
        assertEq(p.get(), 2 ** 256 - 2);
        p.set(10);
        assertEq(this.tUintDec(tSlot, 5), 5);
        assertEq(p.get(), 5);
        assertEq(this.tUintDec(tSlot, 5), 0);
        assertEq(p.get(), 0);
        vm.expectRevert();
        this.tUintDec(tSlot);
        vm.expectRevert();
        this.tUintDec(tSlot, 5);
        p.set(10);
        assertEq(this.tUintIncSigned(tSlot, 1), 11);
        assertEq(p.get(), 11);
        assertEq(this.tUintIncSigned(tSlot, -1), 10);
        assertEq(p.get(), 10);
        assertEq(this.tUintDecSigned(tSlot, 1), 9);
        assertEq(p.get(), 9);
        assertEq(this.tUintDecSigned(tSlot, -1), 10);
        assertEq(p.get(), 10);
    }

    function tUintIncSigned(uint256 tSlot, int256 delta) public returns (uint256) {
        return LibTransient.tUint256(tSlot).incSigned(delta);
    }

    function tUintDecSigned(uint256 tSlot, int256 delta) public returns (uint256) {
        return LibTransient.tUint256(tSlot).decSigned(delta);
    }

    function tUintInc(uint256 tSlot, uint256 delta) public returns (uint256) {
        return LibTransient.tUint256(tSlot).inc(delta);
    }

    function tUintDec(uint256 tSlot, uint256 delta) public returns (uint256) {
        return LibTransient.tUint256(tSlot).dec(delta);
    }

    function tUintInc(uint256 tSlot) public returns (uint256) {
        return LibTransient.tUint256(tSlot).inc();
    }

    function tUintDec(uint256 tSlot) public returns (uint256) {
        return LibTransient.tUint256(tSlot).dec();
    }

    function testInt256IncDecTransient() public {}

    function tIntInc(uint256 tSlot, int256 delta) public returns (int256) {
        return LibTransient.tInt256(tSlot).inc(delta);
    }

    function tIntDec(uint256 tSlot, int256 delta) public returns (int256) {
        return LibTransient.tInt256(tSlot).dec(delta);
    }

    function tIntInc(uint256 tSlot) public returns (int256) {
        return LibTransient.tInt256(tSlot).inc();
    }

    function tIntDec(uint256 tSlot) public returns (int256) {
        return LibTransient.tInt256(tSlot).dec();
    }
}
