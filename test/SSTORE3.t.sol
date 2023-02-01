// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {SSTORE3} from "../src/utils/SSTORE3.sol";

contract SSTORE3Test is TestPlus {
    function testWriteReadDeterministic() public {
        bytes memory testBytes = abi.encode("this is a test");

        address pointer = SSTORE3.writeDeterministic(testBytes);

        assertEq(SSTORE3.read(pointer), testBytes);
    }

    function testWriteReadFullStartBoundDeterministic() public {
        assertEq(SSTORE3.read(SSTORE3.writeDeterministic(hex"11223344"), 0), hex"11223344");
    }

    function testWriteReadCustomStartBoundDeterministic() public {
        assertEq(SSTORE3.read(SSTORE3.writeDeterministic(hex"11223344"), 1), hex"223344");
    }

    function testWriteReadFullBoundedReadDeterministic() public {
        bytes memory testBytes = abi.encode("this is a test");

        assertEq(
            SSTORE3.read(SSTORE3.writeDeterministic(testBytes), 0, testBytes.length), testBytes
        );
    }

    function testWriteReadCustomBoundsDeterministic() public {
        assertEq(SSTORE3.read(SSTORE3.writeDeterministic(hex"11223344"), 1, 3), hex"2233");
    }

    function testWriteReadEmptyBoundDeterministic() public {
        SSTORE3.read(SSTORE3.writeDeterministic(hex"11223344"), 3, 3);
    }

    function testReadInvalidPointerRevertsDeterministic() public {
        vm.expectRevert(SSTORE3.InvalidPointer.selector);
        SSTORE3.read(address(1));
    }

    function testReadInvalidPointerCustomStartBoundRevertsDeterministic() public {
        vm.expectRevert(SSTORE3.InvalidPointer.selector);
        SSTORE3.read(address(1), 1);
    }

    function testReadInvalidPointerCustomBoundsRevertsDeterministic() public {
        vm.expectRevert(SSTORE3.InvalidPointer.selector);
        SSTORE3.read(address(1), 2, 4);
    }

    function testWriteReadOutOfStartBoundRevertsDeterministic() public {
        address pointer = SSTORE3.writeDeterministic(hex"11223344");
        vm.expectRevert(SSTORE3.ReadOutOfBounds.selector);
        SSTORE3.read(pointer, 41000);
    }

    function testWriteReadEmptyOutOfBoundsRevertsDeterministic() public {
        address pointer = SSTORE3.writeDeterministic(hex"11223344");
        vm.expectRevert(SSTORE3.ReadOutOfBounds.selector);
        SSTORE3.read(pointer, 42000, 42000);
    }

    function testWriteReadOutOfBoundsRevertsDeterministic() public {
        address pointer = SSTORE3.writeDeterministic(hex"11223344");
        vm.expectRevert(SSTORE3.ReadOutOfBounds.selector);
        SSTORE3.read(pointer, 41000, 42000);
    }

    function testWriteReadDeterministic(bytes calldata testBytes) public brutalizeMemory {
        _roundUpFreeMemoryPointer();
        bytes memory readResult = SSTORE3.read(SSTORE3.writeDeterministic(testBytes));
        _checkMemory(readResult);
        assertEq(readResult, testBytes);
    }

    function testWriteReadCustomStartBoundDeterministic(
        bytes calldata testBytes,
        uint256 startIndex
    ) public brutalizeMemory {
        if (testBytes.length == 0) return;

        startIndex = _bound(startIndex, 0, testBytes.length);

        _roundUpFreeMemoryPointer();
        bytes memory readResult = SSTORE3.read(SSTORE3.writeDeterministic(testBytes), startIndex);
        _checkMemory(readResult);
        assertEq(readResult, bytes(testBytes[startIndex:]));
    }

    function testWriteReadCustomBoundsDeterministic(
        bytes calldata testBytes,
        uint256 startIndex,
        uint256 endIndex
    ) public brutalizeMemory {
        if (testBytes.length == 0) return;

        endIndex = _bound(endIndex, 0, testBytes.length);
        startIndex = _bound(startIndex, 0, testBytes.length);

        if (startIndex > endIndex) return;

        _roundUpFreeMemoryPointer();
        bytes memory readResult =
            SSTORE3.read(SSTORE3.writeDeterministic(testBytes), startIndex, endIndex);
        _checkMemory(readResult);
        assertEq(readResult, bytes(testBytes[startIndex:endIndex]));
    }

    function testReadInvalidPointerRevertDeterministic(address pointer) public brutalizeMemory {
        if (pointer.code.length > 0) return;
        vm.expectRevert(SSTORE3.InvalidPointer.selector);
        SSTORE3.read(pointer);
    }

    function testReadInvalidPointerCustomStartBoundRevertsDeterministic(
        address pointer,
        uint256 startIndex
    ) public brutalizeMemory {
        if (pointer.code.length > 0) return;
        vm.expectRevert(SSTORE3.InvalidPointer.selector);
        SSTORE3.read(pointer, startIndex);
    }

    function testReadInvalidPointerCustomBoundsRevertsDeterministic(
        address pointer,
        uint256 startIndex,
        uint256 endIndex
    ) public brutalizeMemory {
        if (pointer.code.length > 0) return;
        vm.expectRevert(SSTORE3.InvalidPointer.selector);
        SSTORE3.read(pointer, startIndex, endIndex);
    }

    function testWriteReadCustomStartBoundOutOfRangeRevertsDeterministic(
        bytes calldata testBytes,
        uint256 startIndex
    ) public brutalizeMemory {
        startIndex = _bound(startIndex, testBytes.length + 1, type(uint256).max);
        address pointer = SSTORE3.writeDeterministic(testBytes);
        vm.expectRevert(SSTORE3.ReadOutOfBounds.selector);
        SSTORE3.read(pointer, startIndex);
    }

    function testWriteReadCustomBoundsOutOfRangeRevertsDeterministic(
        bytes calldata testBytes,
        uint256 startIndex,
        uint256 endIndex
    ) public brutalizeMemory {
        endIndex = _bound(endIndex, testBytes.length + 1, type(uint256).max);
        address pointer = SSTORE3.writeDeterministic(testBytes);
        vm.expectRevert(SSTORE3.ReadOutOfBounds.selector);
        SSTORE3.read(pointer, startIndex, endIndex);
    }

    function testWriteReadDeriveDeterministic() public {
        bytes memory testBytes = abi.encode("this is a test");

        address derived =
            SSTORE3.deriveDeterministicStorageAddress(testBytes, bytes32(0), address(this));
        address pointer = SSTORE3.writeDeterministic(testBytes);
        assertEq(derived, pointer);

        assertEq(SSTORE3.read(pointer), testBytes);
    }

    function testWriteReadDeriveArbitrarySaltDeterministic(bytes32 salt) public {
        bytes memory testBytes = abi.encode("this is a test");

        address derived = SSTORE3.deriveDeterministicStorageAddress(testBytes, salt, address(this));
        address pointer = SSTORE3.writeDeterministic(testBytes, salt);
        assertEq(derived, pointer);

        assertEq(SSTORE3.read(pointer), testBytes);
    }

    function testWriteReadDeriveDeterministic(bytes memory data, bytes32 salt) public {
        uint256 freeMemPtr;
        assembly {
            freeMemPtr := mload(0x40)
        }
        // deriving address should not modify either free memory pointer or zero pointer
        address derived = SSTORE3.deriveDeterministicStorageAddress(data, salt, address(this));
        uint256 newFreeMemPtr;
        uint256 newZeroPointer;
        assembly {
            newFreeMemPtr := mload(0x40)
            newZeroPointer := mload(0x60)
        }
        assertEq(freeMemPtr, newFreeMemPtr);
        assertEq(0, newZeroPointer);
        address pointer = SSTORE3.writeDeterministic(data, salt);
        assembly {
            newFreeMemPtr := mload(0x40)
            newZeroPointer := mload(0x60)
        }
        assertEq(freeMemPtr, newFreeMemPtr);
        assertEq(0, newZeroPointer);
        assertEq(derived, pointer);

        assertEq(SSTORE3.read(pointer), data);
    }

    function testDeterministicDeploysDeterministic() public {
        bytes memory testBytes = abi.encode("this is a test");

        // same data with different salts should produce different addresses
        address first = this.externalWrite(testBytes, bytes32(0));
        address second = this.externalWrite(testBytes, bytes32(uint256(1)));
        assertFalse(first == second);
        // trying to re-deploy same data with same salt should revert
        vm.expectRevert(SSTORE3.DeploymentFailed.selector);
        this.externalWrite(testBytes, bytes32(0));
    }

    ///@dev external function allows for vm.expectRevert to work with library methods
    function externalWrite(bytes memory data, bytes32 salt) external returns (address) {
        return SSTORE3.writeDeterministic(data, salt);
    }

    /**
     * @dev original SSTORE3 tests
     */

    function testWriteRead() public {
        bytes memory testBytes = abi.encode("this is a test");

        address pointer = SSTORE3.write(testBytes);

        assertEq(SSTORE3.read(pointer), testBytes);
    }

    function testWriteReadFullStartBound() public {
        assertEq(SSTORE3.read(SSTORE3.write(hex"11223344"), 0), hex"11223344");
    }

    function testWriteReadCustomStartBound() public {
        assertEq(SSTORE3.read(SSTORE3.write(hex"11223344"), 1), hex"223344");
    }

    function testWriteReadFullBoundedRead() public {
        bytes memory testBytes = abi.encode("this is a test");

        assertEq(SSTORE3.read(SSTORE3.write(testBytes), 0, testBytes.length), testBytes);
    }

    function testWriteReadCustomBounds() public {
        assertEq(SSTORE3.read(SSTORE3.write(hex"11223344"), 1, 3), hex"2233");
    }

    function testWriteReadEmptyBound() public {
        SSTORE3.read(SSTORE3.write(hex"11223344"), 3, 3);
    }

    function testReadInvalidPointerReverts() public {
        vm.expectRevert(SSTORE3.InvalidPointer.selector);
        SSTORE3.read(address(1));
    }

    function testReadInvalidPointerCustomStartBoundReverts() public {
        vm.expectRevert(SSTORE3.InvalidPointer.selector);
        SSTORE3.read(address(1), 1);
    }

    function testReadInvalidPointerCustomBoundsReverts() public {
        vm.expectRevert(SSTORE3.InvalidPointer.selector);
        SSTORE3.read(address(1), 2, 4);
    }

    function testWriteReadOutOfStartBoundReverts() public {
        address pointer = SSTORE3.write(hex"11223344");
        vm.expectRevert(SSTORE3.ReadOutOfBounds.selector);
        SSTORE3.read(pointer, 41000);
    }

    function testWriteReadEmptyOutOfBoundsReverts() public {
        address pointer = SSTORE3.write(hex"11223344");
        vm.expectRevert(SSTORE3.ReadOutOfBounds.selector);
        SSTORE3.read(pointer, 42000, 42000);
    }

    function testWriteReadOutOfBoundsReverts() public {
        address pointer = SSTORE3.write(hex"11223344");
        vm.expectRevert(SSTORE3.ReadOutOfBounds.selector);
        SSTORE3.read(pointer, 41000, 42000);
    }

    function testWriteRead(bytes calldata testBytes) public brutalizeMemory {
        _roundUpFreeMemoryPointer();
        bytes memory readResult = SSTORE3.read(SSTORE3.write(testBytes));
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
        bytes memory readResult = SSTORE3.read(SSTORE3.write(testBytes), startIndex);
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
        bytes memory readResult = SSTORE3.read(SSTORE3.write(testBytes), startIndex, endIndex);
        _checkMemory(readResult);
        assertEq(readResult, bytes(testBytes[startIndex:endIndex]));
    }

    function testReadInvalidPointerRevert(address pointer) public brutalizeMemory {
        if (pointer.code.length > 0) return;
        vm.expectRevert(SSTORE3.InvalidPointer.selector);
        SSTORE3.read(pointer);
    }

    function testReadInvalidPointerCustomStartBoundReverts(address pointer, uint256 startIndex)
        public
        brutalizeMemory
    {
        if (pointer.code.length > 0) return;
        vm.expectRevert(SSTORE3.InvalidPointer.selector);
        SSTORE3.read(pointer, startIndex);
    }

    function testReadInvalidPointerCustomBoundsReverts(
        address pointer,
        uint256 startIndex,
        uint256 endIndex
    ) public brutalizeMemory {
        if (pointer.code.length > 0) return;
        vm.expectRevert(SSTORE3.InvalidPointer.selector);
        SSTORE3.read(pointer, startIndex, endIndex);
    }

    function testWriteReadCustomStartBoundOutOfRangeReverts(
        bytes calldata testBytes,
        uint256 startIndex
    ) public brutalizeMemory {
        startIndex = _bound(startIndex, testBytes.length + 1, type(uint256).max);
        address pointer = SSTORE3.write(testBytes);
        vm.expectRevert(SSTORE3.ReadOutOfBounds.selector);
        SSTORE3.read(pointer, startIndex);
    }

    function testWriteReadCustomBoundsOutOfRangeReverts(
        bytes calldata testBytes,
        uint256 startIndex,
        uint256 endIndex
    ) public brutalizeMemory {
        endIndex = _bound(endIndex, testBytes.length + 1, type(uint256).max);
        address pointer = SSTORE3.write(testBytes);
        vm.expectRevert(SSTORE3.ReadOutOfBounds.selector);
        SSTORE3.read(pointer, startIndex, endIndex);
    }
}
