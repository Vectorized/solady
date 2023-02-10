// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {MockEIP712} from "./utils/mocks/MockEIP712.sol";
import {LibClone} from "../src/utils/LibClone.sol";

contract EIP712Test is TestPlus {
    MockEIP712 mock;
    MockEIP712 mockClone;

    function setUp() public {
        mock = new MockEIP712();
        mockClone = MockEIP712(LibClone.clone(address(mock)));
    }

    function testHashTypedData() public {
        _testHashTypedDataOnClone(mock);
    }

    function testHashTypedDataOnClone() public {
        _testHashTypedDataOnClone(mockClone);
    }

    function testHashTypedDataWithChaindIdChange() public {
        _testHashTypedDataOnClone(mock);
        vm.chainId(32123);
        _testHashTypedDataOnClone(mock);
    }

    function testHashTypedDataOnCloneWithChaindIdChange() public {
        _testHashTypedDataOnClone(mockClone);
        vm.chainId(32123);
        _testHashTypedDataOnClone(mockClone);
    }

    function _testHashTypedDataOnClone(MockEIP712 mockToTest) internal {
        (address signer, uint256 privateKey) = _randomSigner();

        (address to,) = _randomSigner();

        string memory message = "Hello Milady!";

        bytes32 structHash =
            keccak256(abi.encode("Message(address to,string message)", to, message));
        bytes32 expectedDigest =
            keccak256(abi.encodePacked("\x19\x01", mockToTest.DOMAIN_SEPARATOR(), structHash));

        assertEq(mockToTest.hashTypedData(structHash), expectedDigest);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, expectedDigest);

        address recoveredAddress = ecrecover(expectedDigest, v, r, s);

        assertEq(recoveredAddress, signer);
    }

    function testDomainSeparator() public {
        _testDomainSeparator(mock);
    }

    function testDomainSeparatorOnClone() public {
        _testDomainSeparator(mockClone);
    }

    function testDomainSeparatorWithChainIdChange() public {
        _testDomainSeparator(mock);
        vm.chainId(32123);
        _testDomainSeparator(mock);
    }

    function testDomainSeparatorOnCloneWithChainIdChange() public {
        _testDomainSeparator(mockClone);
        vm.chainId(32123);
        _testDomainSeparator(mockClone);
    }

    function _testDomainSeparator(MockEIP712 mockToTest) internal {
        bytes32 expectedDomainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("Milady"),
                keccak256("1"),
                block.chainid,
                address(mockToTest)
            )
        );

        assertEq(mockToTest.DOMAIN_SEPARATOR(), expectedDomainSeparator);
    }
}
