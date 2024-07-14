// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {SSTORE2} from "../src/utils/SSTORE2.sol";
import {LibString} from "../src/utils/LibString.sol";

contract SSTORE2Test is SoladyTest {
    function testWriteRead() public {
        bytes memory data = "this is a test";
        assertEq(SSTORE2.read(SSTORE2.write(data)), data);
    }

    function testWriteReadFullStartBound() public {
        assertEq(SSTORE2.read(SSTORE2.write(hex"11223344"), 0), hex"11223344");
    }

    function testWriteReadCustomStartBound() public {
        assertEq(SSTORE2.read(SSTORE2.write(hex"11223344"), 1), hex"223344");
    }

    function testWriteReadFullBoundedRead() public {
        bytes memory data = "this is a test";
        assertEq(SSTORE2.read(SSTORE2.write(data), 0, data.length), data);
    }

    function testWriteReadCustomBounds() public {
        assertEq(SSTORE2.read(SSTORE2.write(hex"11223344"), 1, 3), hex"2233");
    }

    function testWriteReadEmptyBound() public {
        SSTORE2.read(SSTORE2.write(hex"11223344"), 3, 3);
    }

    function testReadInvalidPointerReverts() public {
        vm.expectRevert(SSTORE2.InvalidPointer.selector);
        SSTORE2.read(address(1));
    }

    function testReadInvalidPointerCustomStartBoundReverts() public {
        vm.expectRevert(SSTORE2.InvalidPointer.selector);
        SSTORE2.read(address(1), 1);
    }

    function testReadInvalidPointerCustomBoundsReverts() public {
        vm.expectRevert(SSTORE2.InvalidPointer.selector);
        SSTORE2.read(address(1), 2, 4);
    }

    function testWriteReadOutOfStartBoundReverts() public {
        address pointer = SSTORE2.write(hex"11223344");
        vm.expectRevert(SSTORE2.ReadOutOfBounds.selector);
        SSTORE2.read(pointer, 41000);
    }

    function testWriteReadEmptyOutOfBoundsReverts() public {
        address pointer = SSTORE2.write(hex"11223344");
        vm.expectRevert(SSTORE2.ReadOutOfBounds.selector);
        SSTORE2.read(pointer, 42000, 42000);
    }

    function testWriteReadOutOfBoundsReverts() public {
        address pointer = SSTORE2.write(hex"11223344");
        vm.expectRevert(SSTORE2.ReadOutOfBounds.selector);
        SSTORE2.read(pointer, 41000, 42000);
    }

    function testWriteRead(bytes calldata data) public brutalizeMemory {
        _misalignFreeMemoryPointer();
        bytes memory readResult = SSTORE2.read(SSTORE2.write(data));
        _checkMemory(readResult);
        assertEq(readResult, data);
    }

    function testWriteReadCustomStartBound(bytes calldata data, uint256 startIndex)
        public
        brutalizeMemory
    {
        if (data.length == 0) return;

        startIndex = _bound(startIndex, 0, data.length);

        _misalignFreeMemoryPointer();
        bytes memory readResult = SSTORE2.read(SSTORE2.write(data), startIndex);
        _checkMemory(readResult);
        assertEq(readResult, bytes(data[startIndex:]));
    }

    function testWriteReadCustomBounds(bytes calldata data, uint256 startIndex, uint256 endIndex)
        public
        brutalizeMemory
    {
        do {
            endIndex = _bound(_random(), 0, data.length);
            startIndex = _bound(_random(), 0, data.length);
        } while (startIndex > endIndex);

        _misalignFreeMemoryPointer();
        bytes memory readResult = SSTORE2.read(SSTORE2.write(data), startIndex, endIndex);
        _checkMemory(readResult);
        assertEq(readResult, bytes(data[startIndex:endIndex]));
    }

    function testWriteReadCustomBounds2(bytes32, uint256 startIndex, uint256 endIndex) public {
        bytes memory data = _dummyData(_bound(_random(), 0, 0xfffe));

        do {
            endIndex = _bound(_random(), 0, data.length);
            startIndex = _bound(_random(), 0, data.length);
        } while (startIndex > endIndex);

        _misalignFreeMemoryPointer();
        address pointer = SSTORE2.write(data);
        if (_random() & 7 == 0) assertEq(pointer.code, abi.encodePacked(hex"00", data));
        if (_random() & 1 == 0) _misalignFreeMemoryPointer();
        bytes memory readResult = SSTORE2.read(pointer, startIndex, endIndex);
        _checkMemory(readResult);
        assertEq(readResult, bytes(LibString.slice(string(data), startIndex, endIndex)));
    }

    function testReadInvalidPointerRevert(address pointer) public brutalizeMemory {
        if (pointer.code.length > 0) return;
        vm.expectRevert(SSTORE2.InvalidPointer.selector);
        SSTORE2.read(pointer);
    }

    function testReadInvalidPointerCustomStartBoundReverts(address pointer, uint256 startIndex)
        public
        brutalizeMemory
    {
        if (pointer.code.length > 0) return;
        vm.expectRevert(SSTORE2.InvalidPointer.selector);
        SSTORE2.read(pointer, startIndex);
    }

    function testReadInvalidPointerCustomBoundsReverts(
        address pointer,
        uint256 startIndex,
        uint256 endIndex
    ) public brutalizeMemory {
        if (pointer.code.length > 0) return;
        vm.expectRevert(SSTORE2.InvalidPointer.selector);
        SSTORE2.read(pointer, startIndex, endIndex);
    }

    function testWriteReadCustomStartBoundOutOfRangeReverts(bytes calldata data, uint256 startIndex)
        public
        brutalizeMemory
    {
        startIndex = _bound(startIndex, data.length + 1, type(uint256).max);
        address pointer = SSTORE2.write(data);
        vm.expectRevert(SSTORE2.ReadOutOfBounds.selector);
        SSTORE2.read(pointer, startIndex);
    }

    function testWriteReadCustomBoundsOutOfRangeReverts(
        bytes calldata data,
        uint256 startIndex,
        uint256 endIndex
    ) public brutalizeMemory {
        endIndex = _bound(endIndex, data.length + 1, type(uint256).max);
        address pointer = SSTORE2.write(data);
        vm.expectRevert(SSTORE2.ReadOutOfBounds.selector);
        SSTORE2.read(pointer, startIndex, endIndex);
    }

    function testWriteWithTooBigDataReverts() public {
        bytes memory data = _dummyData(0xfffe);
        address pointer = this.write(data);
        assertEq(SSTORE2.read(pointer), data);
        vm.expectRevert();
        pointer = this.write(_dummyData(0xffff));
    }

    function write(bytes memory data) public returns (address) {
        return SSTORE2.write(data);
    }

    function testWriteReadDeterministic() public {
        bytes32 salt = keccak256("salt");
        bytes memory data = "this is a test";
        assertEq(SSTORE2.writeDeterministic(data, salt).code, abi.encodePacked(hex"00", data));
    }

    function testWriteReadDeterministic(bytes memory data, bytes32 salt) public {
        address predicted = SSTORE2.predictDeterministicAddress(salt);
        assertEq(predicted.code.length, 0);
        address pointer = this.writeDeterministic(data, salt);
        assertEq(pointer, predicted);
        assertEq(pointer.code, abi.encodePacked(hex"00", data));
        assertEq(SSTORE2.read(predicted), data);
        if (_random() & 31 == 0) {
            vm.expectRevert();
            this.writeDeterministic(data, salt);
        }
    }

    function writeDeterministic(bytes memory data, bytes32 salt)
        public
        brutalizeMemory
        returns (address pointer)
    {
        _misalignFreeMemoryPointer();
        if (data.length == 0 && _random() & 1 == 0) {
            bytes memory empty;
            pointer = SSTORE2.writeDeterministic(empty, salt);
        } else {
            pointer = SSTORE2.writeDeterministic(data, salt);
        }
    }

    function _dummyData(uint256 n) internal returns (bytes memory result) {
        uint256 r = _random();
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(0x00, n)
            mstore(0x20, r)
            mstore(add(0x20, result), keccak256(0x00, 0x40))
            mstore(0x20, add(r, 2))
            mstore(add(add(0x20, result), n), keccak256(0x00, 0x40))
            mstore(0x20, add(r, 3))
            mstore(add(result, n), keccak256(0x00, 0x40))
            mstore(0x40, add(add(0x20, result), n))
            mstore(result, n) // Store the length of `result`.
        }
    }
}
