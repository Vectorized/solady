// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {LibClone} from "../src/utils/LibClone.sol";
import {Clone} from "../src/utils/Clone.sol";
import {SafeTransferLib} from "../src/utils/SafeTransferLib.sol";

contract LibCloneTest is TestPlus, Clone {
    error CustomError(uint256 currentValue);

    event ReceiveETH(uint256 amount);

    uint256 public value;

    mapping(bytes32 => bool) saltIsUsed;

    function setUp() public {
        // Mini test to check if `_this()` returns a word with brutalized upper 96 bits.
        address t = _this();
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(shr(160, t)) { revert(0, 0) }
        }
        value += 1;
    }

    function setValue(uint256 value_) public {
        value = value_;
    }

    function revertWithError() public view {
        revert CustomError(value);
    }

    function getCalldataHash() public pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let extraLength := shr(0xf0, calldataload(sub(calldatasize(), 2)))
            if iszero(lt(extraLength, 2)) {
                let offset := sub(calldatasize(), extraLength)
                let m := mload(0x40)
                calldatacopy(m, offset, sub(extraLength, 2))
                result := keccak256(m, sub(extraLength, 2))
            }
        }
    }

    function _canReceiveETHCorectly(address clone, uint256 deposit) internal {
        deposit = deposit % 1 ether;

        vm.deal(address(this), deposit * 2);

        vm.expectEmit(true, true, true, true);
        emit ReceiveETH(deposit);
        SafeTransferLib.safeTransferETH(clone, deposit);
        assertEq(clone.balance, deposit);

        vm.expectEmit(true, true, true, true);
        emit ReceiveETH(deposit);
        payable(clone).transfer(deposit);
        assertEq(clone.balance, deposit * 2);
    }

    function _shouldBehaveLikeClone(address clone, uint256 value_) internal {
        assertTrue(clone != address(0));

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
        address clone = LibClone.clone(_this());
        _shouldBehaveLikeClone(clone, value_);
    }

    function testClone() public {
        testClone(1);
    }

    function testCloneDeterministic(uint256 value_, bytes32 salt) public {
        if (saltIsUsed[salt]) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            LibClone.cloneDeterministic(_this(), salt);
            return;
        }

        address clone = LibClone.cloneDeterministic(_this(), salt);
        saltIsUsed[salt] = true;

        _shouldBehaveLikeClone(clone, value_);

        address predicted = LibClone.predictDeterministicAddress(_this(), salt, _this());
        assertEq(clone, predicted);
    }

    function testCloneDeterministicRevertsIfAddressAlreadyUsed() public {
        testCloneDeterministic(1, keccak256("a"));
        testCloneDeterministic(1, keccak256("a"));
    }

    function testCloneDeterministic() public {
        testCloneDeterministic(1, keccak256("b"));
    }

    function getArgBytes(uint256 argOffset, uint256 length) public pure returns (bytes memory) {
        return _getArgBytes(argOffset, length);
    }

    function getArgAddress(uint256 argOffset) public pure returns (address) {
        return _getArgAddress(argOffset);
    }

    function getArgUint256(uint256 argOffset) public pure returns (uint256) {
        return _getArgUint256(argOffset);
    }

    function getArgUint256Array(uint256 argOffset, uint256 length)
        public
        pure
        returns (uint256[] memory)
    {
        return _getArgUint256Array(argOffset, length);
    }

    function getArgUint64(uint256 argOffset) public pure returns (uint64) {
        return _getArgUint64(argOffset);
    }

    function getArgUint8(uint256 argOffset) public pure returns (uint8) {
        return _getArgUint8(argOffset);
    }

    function testCloneWithImmutableArgs(
        uint256 value_,
        address argAddress,
        uint256 argUint256,
        uint256[] memory argUint256Array,
        uint64 argUint64,
        uint8 argUint8
    ) public brutalizeMemory {
        bytes memory data =
            abi.encodePacked(argAddress, argUint256, argUint256Array, argUint64, argUint8);
        LibCloneTest clone = LibCloneTest(LibClone.clone(_this(), data));
        _shouldBehaveLikeClone(address(clone), value_);

        // For avoiding stack too deep. Also, no risk of overflow.
        unchecked {
            uint256 argOffset;
            assertEq(clone.getArgAddress(argOffset), argAddress);
            argOffset += 20;
            assertEq(clone.getArgUint256(argOffset), argUint256);
            argOffset += 32;
            assertEq(clone.getArgUint256Array(argOffset, argUint256Array.length), argUint256Array);
            argOffset += 32 * argUint256Array.length;
            assertEq(clone.getArgUint64(argOffset), argUint64);
            argOffset += 8;
            assertEq(clone.getArgUint8(argOffset), argUint8);
        }
    }

    function testCloneWithImmutableArgs() public {
        uint256[] memory argUint256Array = new uint256[](2);
        argUint256Array[0] = 111;
        argUint256Array[1] = 222;
        testCloneWithImmutableArgs(1, address(uint160(0xB00Ba5)), 8, argUint256Array, 7, 6);
    }

    function testCloneDeteministicWithImmutableArgs(
        address argAddress,
        uint256 argUint256,
        uint256[] memory argUint256Array,
        bytes memory argBytes,
        uint64 argUint64,
        uint8 argUint8,
        uint256 deposit
    ) public brutalizeMemory {
        bytes memory data;
        bytes32 salt;

        // For avoiding stack too deep.
        unchecked {
            // Recycle for the salt.
            salt = bytes32(argUint256 + 123);

            data = abi.encodePacked(
                argUint256,
                argAddress,
                argUint256,
                argUint256Array,
                argBytes,
                argUint64,
                argUint8,
                argUint256
            );

            bytes32 saltKey = keccak256(abi.encode(data, salt));
            if (saltIsUsed[saltKey]) {
                vm.expectRevert(LibClone.DeploymentFailed.selector);
                LibCloneTest(LibClone.cloneDeterministic(_this(), data, salt));
                return;
            }
            saltIsUsed[saltKey] = true;
        }

        bytes32 dataHashBefore = keccak256(data);

        LibCloneTest clone = LibCloneTest(LibClone.cloneDeterministic(_this(), data, salt));
        // Check that memory management is done properly.
        assertEq(keccak256(data), dataHashBefore);

        _shouldBehaveLikeClone(address(clone), argUint256);
        _canReceiveETHCorectly(address(clone), deposit);

        // For avoiding stack too deep. Also, no risk of overflow.
        unchecked {
            uint256 argOffset;
            assertEq(clone.getArgUint256(argOffset), argUint256);
            argOffset += (256 / 8);
            assertEq(clone.getArgAddress(argOffset), argAddress);
            argOffset += (160 / 8);
            assertEq(clone.getArgUint256(argOffset), argUint256);
            argOffset += (256 / 8);
            assertEq(clone.getArgUint256Array(argOffset, argUint256Array.length), argUint256Array);
            argOffset += (256 / 8) * argUint256Array.length;
            assertEq(clone.getArgBytes(argOffset, argBytes.length), argBytes);
            argOffset += (8 / 8) * argBytes.length;
            assertEq(clone.getArgUint64(argOffset), argUint64);
            argOffset += (64 / 8);
            assertEq(clone.getArgUint8(argOffset), argUint8);
            argOffset += (8 / 8);
            assertEq(clone.getArgUint256(argOffset), argUint256);
        }

        {
            address predicted = LibClone.predictDeterministicAddress(_this(), data, salt, _this());
            assertEq(address(clone), predicted);
        }

        // Check that memory management is done properly.
        assertEq(keccak256(data), dataHashBefore);

        assertEq(clone.getCalldataHash(), dataHashBefore);
    }

    function testCloneDeteministicWithImmutableArgs() public {
        uint256[] memory argUint256Array = new uint256[](2);
        argUint256Array[0] = uint256(keccak256("zero"));
        argUint256Array[1] = uint256(keccak256("one"));
        bytes memory argBytes = bytes("Teehee");
        testCloneDeteministicWithImmutableArgs(
            address(uint160(uint256(keccak256("argAddress")))),
            uint256(keccak256("argUint256")),
            argUint256Array,
            argBytes,
            uint64(uint256(keccak256("argUint64"))),
            uint8(uint256(keccak256("argUint8"))),
            uint256(keccak256("deposit"))
        );
    }

    function _this() internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(shl(160, add(timestamp(), 123456789)), address())
        }
    }
}
