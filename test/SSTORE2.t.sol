// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {SSTORE2} from "../src/utils/SSTORE2.sol";
import {LibString} from "../src/utils/LibString.sol";

contract SSTORE2Test is SoladyTest {
    uint256 internal constant _DATA_MAX_LENGTH = 0xfffe;

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

    function testReadRevertsOnZeroCodeAddress(address pointer, uint256 c) public {
        while (pointer.code.length != 0) pointer = _randomNonZeroAddress();
        uint256 m = 1;
        if (c & (m <<= 1) == 0) {
            vm.expectRevert();
            SSTORE2.read(pointer);
            return;
        }
        if (c & (m <<= 1) == 0) {
            vm.expectRevert();
            SSTORE2.read(pointer, _random());
            return;
        }
        if (c & (m <<= 1) == 0) {
            vm.expectRevert();
            SSTORE2.read(pointer, _random(), _random());
            return;
        }
        pointer = SSTORE2.write("");
        assertEq(SSTORE2.read(pointer), "");
        assertEq(SSTORE2.read(pointer, _random()), "");
        assertEq(SSTORE2.read(pointer, _random(), _random()), "");
    }

    function testWriteRead(bytes32, uint256 r) public {
        bytes memory data = _truncateBytes(_randomBytes(), _DATA_MAX_LENGTH);

        uint256 startIndex = _bound(_random(), 0, data.length + 2);
        uint256 endIndex = _bound(_random(), 0, data.length + 2);

        if (r & 0x1 == 0) _misalignFreeMemoryPointer();

        address pointer = SSTORE2.write(data);

        if (r & 0x70 == 0) assertEq(pointer.code, abi.encodePacked(hex"00", data));

        if (r & 0x100 == 0) _misalignFreeMemoryPointer();
        if (r & 0x3000 == 0) _brutalizeMemory();

        bytes memory readResult = SSTORE2.read(pointer, startIndex, endIndex);
        _checkMemory(readResult);
        assertEq(readResult, bytes(LibString.slice(string(data), startIndex, endIndex)));

        if (r & 0x10000 == 0) _misalignFreeMemoryPointer();
        if (r & 0x300000 == 0) _brutalizeMemory();

        if (r & 0x1000000 == 0) {
            readResult = SSTORE2.read(pointer, startIndex);
            _checkMemory(readResult);
            assertEq(readResult, bytes(LibString.slice(string(data), startIndex)));
        }

        readResult = SSTORE2.read(pointer);
        _checkMemory(readResult);
        assertEq(readResult, data);
    }

    function testWriteWithTooBigDataReverts() public {
        bytes memory data = new bytes(_DATA_MAX_LENGTH);
        address pointer = this.write(data);
        assertEq(SSTORE2.read(pointer), data);
        vm.expectRevert();
        pointer = this.write(new bytes(_DATA_MAX_LENGTH + 1));
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
        address predicted = SSTORE2.predictDeterministicAddress(salt, _brutalized(address(this)));
        address pointer = SSTORE2.writeDeterministic(data, salt);
        assertEq(pointer, predicted);
        assertEq(SSTORE2.read(predicted), data);
        uint256 r = _random();
        if (r & 0xf == 0) {
            if (r & 0x10 == 0) data = _truncateBytes(_randomBytes(), 0xfffe);
            vm.expectRevert(SSTORE2.DeploymentFailed.selector);
            this.testWriteReadDeterministic(data, salt);
        }
    }

    function testWriteReadCounterfactual(bytes calldata data, bytes32 salt, address deployer)
        public
    {
        while (deployer.code.length != 0) deployer = _randomHashedAddress();
        address predicted = SSTORE2.predictCounterfactualAddress(data, salt, deployer);

        vm.prank(deployer);
        address pointer = SSTORE2.writeCounterfactual(data, salt);
        assertEq(SSTORE2.read(pointer), data);
        assertEq(pointer, predicted);

        assertEq(SSTORE2.write(data).code, pointer.code);

        uint256 r = _random();
        if (r & 0xf == 0) {
            vm.expectRevert(SSTORE2.DeploymentFailed.selector);
            this.testWriteReadCounterfactual(data, salt, deployer);
        }
    }

    function testReadSlicing() public {
        bytes memory data = "1234567890123456789012345678901234567890123456789012345678901234";
        address pointer = SSTORE2.write(data);
        assertEq(SSTORE2.read(pointer), data);
        assertEq(SSTORE2.read(pointer, 32), "34567890123456789012345678901234");
        assertEq(SSTORE2.read(pointer, 0, 64), data);
        assertEq(SSTORE2.read(pointer, 0, 65), data);
        assertEq(SSTORE2.read(pointer, 0, 32), "12345678901234567890123456789012");
        assertEq(SSTORE2.read(pointer, 1, 32), "2345678901234567890123456789012");
    }

    function _randomBytes() internal returns (bytes memory result) {
        uint256 r = _random();
        uint256 n = r & 0xffff;
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(0x00, r)
            let t := keccak256(0x00, 0x20)
            if gt(byte(0, r), 16) { n := and(r, 0x7f) }
            codecopy(add(result, 0x20), byte(0, t), codesize())
            codecopy(add(result, n), byte(1, t), codesize())
            mstore(0x40, add(n, add(0x40, result)))
            mstore(result, n)
            if iszero(byte(3, t)) { result := 0x60 }
        }
    }

    function _truncateBytes(bytes memory b, uint256 n)
        internal
        pure
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if gt(mload(b), n) { mstore(b, n) }
            result := b
        }
    }
}
