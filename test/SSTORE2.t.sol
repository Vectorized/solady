// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {SSTORE2} from "../src/utils/SSTORE2.sol";

contract SSTORE2Test is TestPlus {
    function testWriteRead() public {
        bytes memory testBytes = abi.encode("this is a test");

        address pointer = SSTORE2.write(testBytes);

        assertEq(SSTORE2.read(pointer), testBytes);
    }

    function testWriteReadFullStartBound() public {
        assertEq(SSTORE2.read(SSTORE2.write(hex"11223344"), 0), hex"11223344");
    }

    function testWriteReadCustomStartBound() public {
        assertEq(SSTORE2.read(SSTORE2.write(hex"11223344"), 1), hex"223344");
    }

    function testWriteReadFullBoundedRead() public {
        bytes memory testBytes = abi.encode("this is a test");

        assertEq(SSTORE2.read(SSTORE2.write(testBytes), 0, testBytes.length), testBytes);
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

    function testWriteRead(bytes calldata testBytes) public brutalizeMemory {
        _roundUpFreeMemoryPointer();
        bytes memory readResult = SSTORE2.read(SSTORE2.write(testBytes));
        _checkMemory(readResult);
        assertEq(readResult, testBytes);
    }

    function testWriteReadCustomStartBound(bytes calldata testBytes, uint256 startIndex)
        public
        brutalizeMemory
    {
        if (testBytes.length == 0) return;

        startIndex = _bound(startIndex, 0, testBytes.length);

        _roundUpFreeMemoryPointer();
        bytes memory readResult = SSTORE2.read(SSTORE2.write(testBytes), startIndex);
        _checkMemory(readResult);
        assertEq(readResult, bytes(testBytes[startIndex:]));
    }

    function testWriteReadCustomBounds(
        bytes calldata testBytes,
        uint256 startIndex,
        uint256 endIndex
    ) public brutalizeMemory {
        if (testBytes.length == 0) return;

        endIndex = _bound(endIndex, 0, testBytes.length);
        startIndex = _bound(startIndex, 0, testBytes.length);

        if (startIndex > endIndex) return;

        _roundUpFreeMemoryPointer();
        bytes memory readResult = SSTORE2.read(SSTORE2.write(testBytes), startIndex, endIndex);
        _checkMemory(readResult);
        assertEq(readResult, bytes(testBytes[startIndex:endIndex]));
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

    function testWriteReadCustomStartBoundOutOfRangeReverts(
        bytes calldata testBytes,
        uint256 startIndex
    ) public brutalizeMemory {
        startIndex = _bound(startIndex, testBytes.length + 1, type(uint256).max);
        address pointer = SSTORE2.write(testBytes);
        vm.expectRevert(SSTORE2.ReadOutOfBounds.selector);
        SSTORE2.read(pointer, startIndex);
    }

    function testWriteReadCustomBoundsOutOfRangeReverts(
        bytes calldata testBytes,
        uint256 startIndex,
        uint256 endIndex
    ) public brutalizeMemory {
        endIndex = _bound(endIndex, testBytes.length + 1, type(uint256).max);
        address pointer = SSTORE2.write(testBytes);
        vm.expectRevert(SSTORE2.ReadOutOfBounds.selector);
        SSTORE2.read(pointer, startIndex, endIndex);
    }

    function testWriteReadDeterministic(bytes calldata testBytes) public brutalizeMemory {
        bytes32 salt = bytes32(_random());
        address deployer = address(this);
        if (_random() % 8 == 0) {
            (, deployer) = _randomSigner();
        }
        vm.prank(deployer);
        address deterministicPointer = SSTORE2.writeDeterministic(testBytes, salt);
        assertEq(SSTORE2.read(deterministicPointer), testBytes);
        assertEq(
            SSTORE2.predictDeterministicAddress(testBytes, salt, deployer), deterministicPointer
        );

        address pointer = SSTORE2.write(testBytes);
        assertEq(pointer.code, deterministicPointer.code);
    }
}
