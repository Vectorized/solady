// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibCall} from "../src/utils/LibCall.sol";
import {LibBytes} from "../src/utils/LibBytes.sol";

contract HashSetter {
    mapping(uint256 => bytes32) public hashes;

    function setHash(uint256 key, bytes memory data) public payable returns (bytes memory) {
        hashes[key] = keccak256(data);
        return abi.encodePacked(data, keccak256(data));
    }
}

contract LibCallTest is SoladyTest {
    HashSetter hashSetter;

    function setUp() public {
        hashSetter = new HashSetter();
    }

    function testCallAndStaticCall(uint256 key, bytes memory data) public {
        vm.deal(address(this), 1 ether);
        uint256 value = _bound(_random(), 0, 1 ether);
        bytes memory result = LibCall.callContract(
            address(hashSetter), value, abi.encodeWithSignature("setHash(uint256,bytes)", key, data)
        );
        assertEq(hashSetter.hashes(key), keccak256(data));
        assertEq(abi.decode(result, (bytes)), abi.encodePacked(data, keccak256(data)));
        assertEq(
            abi.decode(
                LibCall.staticCallContract(
                    address(hashSetter), abi.encodeWithSignature("hashes(uint256)", key)
                ),
                (bytes32)
            ),
            keccak256(data)
        );
    }

    function testSetSelector(bytes memory dataWithoutSelector) public {
        bytes4 sel = bytes4(bytes32(_random()));
        bytes memory data = abi.encodePacked(bytes4(bytes32(_random())), dataWithoutSelector);
        data = this.copyAndSetSelector(sel, data);
        assertEq(data, abi.encodePacked(sel, dataWithoutSelector));
        if (_randomChance(2)) {
            uint256 n = _random() % 4;
            vm.expectRevert(LibCall.DataTooShort.selector);
            this.copyAndSetSelector(sel, LibBytes.slice(data, 0, n));
        }
    }

    function copyAndSetSelector(bytes4 sel, bytes memory data) public pure returns (bytes memory) {
        LibCall.setSelector(sel, data);
        return data;
    }
}
