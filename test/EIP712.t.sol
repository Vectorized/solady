// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {MockEIP712} from "./utils/mocks/MockEIP712.sol";

contract EIP712Test is TestPlus {
    MockEIP712 mock;

    function setUp() public {
        mock = new MockEIP712();
    }

    function testHashTypedData() public {
        (address signer, uint256 privateKey) = _randomSigner();

        (address to,) = _randomSigner();

        string memory message = "Hello Milady!";

        bytes32 structHash =
            keccak256(abi.encode("Message(address to,string message)", to, message));
        bytes32 expectedDigest =
            keccak256(abi.encodePacked("\x19\x01", mock.DOMAIN_SEPARATOR(), structHash));

        assertEq(mock.hashTypedData(structHash), expectedDigest);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, expectedDigest);

        address recoveredAddress = ecrecover(expectedDigest, v, r, s);

        assertEq(recoveredAddress, signer);
    }

    function testDomainSeparator() public {
        bytes32 expectedDomainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("Milady"),
                keccak256("1"),
                block.chainid,
                address(mock)
            )
        );

        assertEq(mock.DOMAIN_SEPARATOR(), expectedDomainSeparator);
    }
}
