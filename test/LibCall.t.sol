// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibCall} from "../src/utils/LibCall.sol";

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
}
