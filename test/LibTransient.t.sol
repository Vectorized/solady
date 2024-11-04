// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./utils/SoladyTest.sol";
import {LibTransient} from "../src/utils/LibTransient.sol";

contract LibTransientTest is SoladyTest {
    using LibTransient for *;

    function testSetAndGetBytesTransient() public {
        vm.chainId(2);
        _testSetAndGetBytesTransient("123");
        _testSetAndGetBytesTransient("12345678901234567890123456789012345678901234567890");
        _testSetAndGetBytesTransient("123");
    }

    function _testSetAndGetBytesTransient(bytes memory data) internal {
        LibTransient.TBytes storage p = LibTransient.tBytes(uint256(0));
        p.setCompat(data);
        assertEq(p.lengthCompat(), data.length);
        assertEq(p.getCompat(), data);
    }

    function testSetAndGetBytesTransientCalldata(
        uint256 tSlot,
        bytes calldata data0,
        bytes calldata data1
    ) public {
        vm.chainId(_randomUniform() & 3);
        unchecked {
            LibTransient.TBytes storage p0 = LibTransient.tBytes(tSlot);
            LibTransient.TBytes storage p1 = LibTransient.tBytes(tSlot + 1);
            if (_randomChance(2)) {
                p0.setCalldataCompat(data0);
                p1.setCalldataCompat(data1);
            } else {
                p0.setCompat(data0);
                p1.setCompat(data1);
            }
            assertEq(p0.getCompat(), data0);
            assertEq(p1.getCompat(), data1);
            if (_randomChance(2)) {
                p0.setCalldataCompat(data1);
                p1.setCalldataCompat(data0);
            } else {
                p0.setCompat(data1);
                p1.setCompat(data0);
            }
            assertEq(p0.getCompat(), data1);
            assertEq(p1.getCompat(), data0);
            p0.clearCompat();
            assertEq(p0.lengthCompat(), 0);
            assertEq(p0.getCompat(), "");
            assertEq(p1.getCompat(), data0);
            p1.clearCompat();
            assertEq(p1.lengthCompat(), 0);
            assertEq(p1.getCompat(), "");
            assertEq(p0.lengthCompat(), 0);
            assertEq(p0.getCompat(), "");
        }
    }

    function testSetAndGetBytesTransient(uint256 tSlot, bytes memory data) public {
        vm.chainId(_randomUniform() & 3);
        LibTransient.TBytes storage p = LibTransient.tBytes(tSlot);
        if (_randomChance(8)) data = _randomBytes();
        p.setCompat(data);
        assertEq(p.lengthCompat(), data.length);
        if (_randomChance(8)) {
            _misalignFreeMemoryPointer();
            _brutalizeMemory();
        }
        bytes memory retrieved = p.getCompat();
        _checkMemory(retrieved);
        assertEq(retrieved, data);
        p.clearCompat();
        assertEq(p.lengthCompat(), 0);
        assertEq(p.getCompat(), "");
    }

    function testSetAndGetBytesTransientCalldata(uint256 tSlot, bytes calldata data) public {
        vm.chainId(_randomUniform() & 3);
        LibTransient.TBytes storage p = LibTransient.tBytes(tSlot);
        p.setCompat(data);
        assertEq(p.lengthCompat(), data.length);
        assertEq(p.getCompat(), data);
        p.clearCompat();
        assertEq(p.lengthCompat(), 0);
        assertEq(p.getCompat(), "");
    }

    function testSetAndGetUint256Transient(uint256 tSlot, uint256 value) public {
        vm.chainId(_randomUniform() & 3);
        LibTransient.TUint256 storage p = LibTransient.tUint256(tSlot);
        p.setCompat(value);
        assertEq(p.getCompat(), value);
        p.clearCompat();
        assertEq(p.getCompat(), 0);
    }

    function testSetAndGetInt256Transient(uint256 tSlot, int256 value) public {
        vm.chainId(_randomUniform() & 3);
        LibTransient.TInt256 storage p = LibTransient.tInt256(tSlot);
        p.setCompat(value);
        assertEq(p.getCompat(), value);
        p.clearCompat();
        assertEq(p.getCompat(), 0);
    }

    function testSetAndGetAddressTransient(uint256 tSlot, address value) public {
        vm.chainId(_randomUniform() & 3);
        LibTransient.TAddress storage p = LibTransient.tAddress(tSlot);
        p.setCompat(_brutalized(value));
        assertEq(p.getCompat(), value);
        p.clearCompat();
        assertEq(p.getCompat(), address(0));
    }

    function testSetAndGetBytes32Transient(uint256 tSlot, bytes32 value) public {
        vm.chainId(_randomUniform() & 3);
        LibTransient.TBytes32 storage p = LibTransient.tBytes32(tSlot);
        p.setCompat(value);
        assertEq(p.getCompat(), value);
        p.clearCompat();
        assertEq(p.getCompat(), bytes32(0));
    }

    function testSetAndGetBoolTransient(uint256 tSlot, bool value) public {
        vm.chainId(_randomUniform() & 3);
        LibTransient.TBool storage p = LibTransient.tBool(tSlot);
        p.setCompat(_brutalized(value));
        assertEq(p.getCompat(), value);
        p.clearCompat();
        assertEq(p.getCompat(), false);
    }

    function testUint256IncDecTransient() public {
        for (uint256 c; c < 3; ++c) {
            vm.chainId(c);
            uint256 tSlot;
            LibTransient.TUint256 storage p = LibTransient.tUint256(tSlot);
            p.setCompat(10);
            assertEq(this.tUintIncCompat(tSlot), 11);
            assertEq(p.getCompat(), 11);
            assertEq(this.tUintIncCompat(tSlot, 20), 31);
            assertEq(p.getCompat(), 31);
            p.setCompat(2 ** 256 - 2);
            assertEq(this.tUintIncCompat(tSlot), 2 ** 256 - 1);
            assertEq(p.getCompat(), 2 ** 256 - 1);
            vm.expectRevert();
            this.tUintIncCompat(tSlot);
            vm.expectRevert();
            this.tUintIncCompat(tSlot, 10);
            assertEq(this.tUintDecCompat(tSlot), 2 ** 256 - 2);
            assertEq(p.getCompat(), 2 ** 256 - 2);
            p.setCompat(10);
            assertEq(this.tUintDecCompat(tSlot, 5), 5);
            assertEq(p.getCompat(), 5);
            assertEq(this.tUintDecCompat(tSlot, 5), 0);
            assertEq(p.getCompat(), 0);
            vm.expectRevert();
            this.tUintDecCompat(tSlot);
            vm.expectRevert();
            this.tUintDecCompat(tSlot, 5);
            p.setCompat(10);
            assertEq(this.tUintIncSignedCompat(tSlot, 1), 11);
            assertEq(p.getCompat(), 11);
            assertEq(this.tUintIncSignedCompat(tSlot, -1), 10);
            assertEq(p.getCompat(), 10);
            assertEq(this.tUintDecSignedCompat(tSlot, 1), 9);
            assertEq(p.getCompat(), 9);
            assertEq(this.tUintDecSignedCompat(tSlot, -1), 10);
            assertEq(p.getCompat(), 10);
        }
    }

    function tUintIncSignedCompat(uint256 tSlot, int256 delta) public returns (uint256) {
        return LibTransient.tUint256(tSlot).incSignedCompat(delta);
    }

    function tUintDecSignedCompat(uint256 tSlot, int256 delta) public returns (uint256) {
        return LibTransient.tUint256(tSlot).decSignedCompat(delta);
    }

    function tUintIncCompat(uint256 tSlot, uint256 delta) public returns (uint256) {
        return LibTransient.tUint256(tSlot).incCompat(delta);
    }

    function tUintDecCompat(uint256 tSlot, uint256 delta) public returns (uint256) {
        return LibTransient.tUint256(tSlot).decCompat(delta);
    }

    function tUintIncCompat(uint256 tSlot) public returns (uint256) {
        return LibTransient.tUint256(tSlot).incCompat();
    }

    function tUintDecCompat(uint256 tSlot) public returns (uint256) {
        return LibTransient.tUint256(tSlot).decCompat();
    }

    function tIntIncCompat(uint256 tSlot, int256 delta) public returns (int256) {
        return LibTransient.tInt256(tSlot).incCompat(delta);
    }

    function tIntDecCompat(uint256 tSlot, int256 delta) public returns (int256) {
        return LibTransient.tInt256(tSlot).decCompat(delta);
    }

    function tIntIncCompat(uint256 tSlot) public returns (int256) {
        return LibTransient.tInt256(tSlot).incCompat();
    }

    function tIntDecCompat(uint256 tSlot) public returns (int256) {
        return LibTransient.tInt256(tSlot).decCompat();
    }

    function testSetBytesTransientRevertsIfLengthTooBig(uint256 n) public {
        n = _bound(n, 0x100000000, type(uint256).max);
        vm.chainId(_randomUniform() & 3);
        vm.expectRevert();
        this.setBytesTransientWithLengthTooBig(n);
    }

    function testSetBytesTransientRevertsIfLengthTooBigCalldata(uint256 n) public {
        n = _bound(n, 0x100000000, type(uint256).max);
        vm.chainId(_randomUniform() & 3);
        vm.expectRevert();
        this.setBytesTransientWithLengthTooBigCalldata(n);
    }

    function setBytesTransientWithLengthTooBig(uint256 n) public {
        bytes memory data;
        /// @solidity memory-safe-assembly
        assembly {
            data := mload(0x40)
            mstore(data, n)
            mstore(0x40, add(data, 0x20))
        }
        LibTransient.tBytes(uint256(0)).setCompat(data);
    }

    function setBytesTransientWithLengthTooBigCalldata(uint256 n) public {
        bytes calldata data;
        /// @solidity memory-safe-assembly
        assembly {
            data.offset := 0
            data.length := n
        }
        LibTransient.tBytes(uint256(0)).setCalldataCompat(data);
    }
}
