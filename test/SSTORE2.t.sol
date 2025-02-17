// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {SSTORE2} from "../src/utils/SSTORE2.sol";
import {LibString} from "../src/utils/LibString.sol";
import {FixedPointMathLib} from "../src/utils/FixedPointMathLib.sol";

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

    function testReadRevertsOnZeroCodeAddress(address pointer) public {
        while (pointer.code.length != 0) pointer = _randomNonZeroAddress();
        _maybeBrutalizeMemory();
        if (_randomChance(2)) {
            vm.expectRevert();
            _mustCompute(this.read(pointer));
            return;
        }
        if (_randomChance(2)) {
            vm.expectRevert();
            _mustCompute(this.read(pointer, _random()));
            return;
        }
        if (_randomChance(2)) {
            vm.expectRevert();
            _mustCompute(this.read(pointer, _random(), _random()));
            return;
        }
        pointer = SSTORE2.write("");
        assertEq(this.read(pointer), "");
        assertEq(this.read(pointer, _random()), "");
        assertEq(this.read(pointer, _random(), _random()), "");
    }

    function read(address pointer) public view returns (bytes memory) {
        return SSTORE2.read(pointer);
    }

    function read(address pointer, uint256 start) public view returns (bytes memory) {
        return SSTORE2.read(pointer, start);
    }

    function read(address pointer, uint256 start, uint256 end) public view returns (bytes memory) {
        return SSTORE2.read(pointer, start, end);
    }

    function _mustCompute(bytes memory s) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if eq(keccak256(s, 0x80), 123) { sstore(keccak256(0x00, 0x21), 1) }
        }
    }

    function testWriteRead(uint256 startIndex, uint256 endIndex) public {
        bytes memory data = _truncateBytes(_randomBytes(), _DATA_MAX_LENGTH);

        if (_randomChance(2)) {
            startIndex = _bound(_random(), 0, data.length + 2);
            endIndex = _bound(_random(), 0, data.length + 2);
        }

        _maybeBrutalizeMemory();

        address pointer = SSTORE2.write(data);

        if (_randomChance(2)) assertEq(pointer.code, abi.encodePacked(hex"00", data));

        _maybeBrutalizeMemory();

        bytes memory readResult = SSTORE2.read(pointer, startIndex, endIndex);
        _checkMemory(readResult);
        assertEq(readResult, bytes(LibString.slice(string(data), startIndex, endIndex)));

        _maybeBrutalizeMemory();

        if (_randomChance(2)) {
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
        if (_randomChance(32)) {
            if (_randomChance(2)) data = _truncateBytes(_randomBytes(), 0xfffe);
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

        if (_randomChance(32)) {
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

    function _maybeBrutalizeMemory() internal {
        if (_randomChance(2)) _misalignFreeMemoryPointer();
        if (_randomChance(16)) _brutalizeMemory();
    }
}
