// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {MockEIP712} from "./utils/mocks/MockEIP712.sol";
import {MockEIP712Dynamic} from "./utils/mocks/MockEIP712Dynamic.sol";
import {LibClone} from "../src/utils/LibClone.sol";

contract EIP712Test is SoladyTest {
    MockEIP712 mock;
    MockEIP712 mockClone;
    MockEIP712Dynamic mockDynamic;
    MockEIP712Dynamic mockDynamicClone;

    function setUp() public {
        mock = new MockEIP712();
        mockClone = MockEIP712(LibClone.clone(address(mock)));
        mockDynamic = new MockEIP712Dynamic("Milady", "1");
        mockDynamicClone = MockEIP712Dynamic(LibClone.clone(address(mockDynamic)));
    }

    function testHashTypedData() public {
        _testHashTypedDataOnClone(mock);
    }

    function testHashTypedDataOnClone() public {
        _testHashTypedDataOnClone(mockClone);
    }

    function testHashTypedDataOnDynamic() public {
        _testHashTypedDataOnClone(MockEIP712(address(mockDynamic)));
    }

    function testHashTypedDataOnCloneDynamic() public {
        _testHashTypedDataOnClone(MockEIP712(address(mockDynamicClone)));
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

    function testHashTypedDataOnDynamicWithChaindIdChange() public {
        _testHashTypedDataOnClone(MockEIP712(address(mockDynamic)));
        vm.chainId(32123);
        _testHashTypedDataOnClone(MockEIP712(address(mockDynamic)));
    }

    function testHashTypedDataOnCloneDynamicWithChaindIdChange() public {
        _testHashTypedDataOnClone(MockEIP712(address(mockDynamicClone)));
        vm.chainId(32123);
        _testHashTypedDataOnClone(MockEIP712(address(mockDynamicClone)));
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

    function testDomainSeparatorOnDynamicWithChainIdChange() public {
        _testDomainSeparator(MockEIP712(address(mockDynamic)));
        vm.chainId(32123);
        _testDomainSeparator(MockEIP712(address(mockDynamic)));
        mockDynamic.setDomainNameAndVersion("Remilio", "2");
        _testDomainSeparator(MockEIP712(address(mockDynamic)), "Remilio", "2");
    }

    function testDomainSeparatorOnCloneDynamicWithChainIdChange() public {
        mockDynamicClone.setDomainNameAndVersion("Milady", "1");
        _testDomainSeparator(MockEIP712(address(mockDynamicClone)));
        vm.chainId(32123);
        _testDomainSeparator(MockEIP712(address(mockDynamicClone)));
        mockDynamicClone.setDomainNameAndVersion("Remilio", "2");
        _testDomainSeparator(MockEIP712(address(mockDynamicClone)), "Remilio", "2");
    }

    function _testDomainSeparator(MockEIP712 mockToTest, bytes memory name, bytes memory version)
        internal
    {
        bytes32 expectedDomainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(name),
                keccak256(version),
                block.chainid,
                address(mockToTest)
            )
        );

        assertEq(mockToTest.DOMAIN_SEPARATOR(), expectedDomainSeparator);
    }

    function _testDomainSeparator(MockEIP712 mockToTest) internal {
        _testDomainSeparator(mockToTest, "Milady", "1");
    }

    function testEIP5267() public {
        _testEIP5267(mock);
        _testEIP5267(mockClone);
        vm.chainId(32123);
        _testEIP5267(mock);
        _testEIP5267(mockClone);
    }

    struct _testEIP5267Variables {
        bytes1 fields;
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
        bytes32 salt;
        uint256[] extensions;
    }

    function _testEIP5267(MockEIP712 mockToTest) public {
        _testEIP5267Variables memory t;
        (t.fields, t.name, t.version, t.chainId, t.verifyingContract, t.salt, t.extensions) =
            mockToTest.eip712Domain();

        assertEq(t.fields, hex"0f");
        assertEq(t.name, "Milady");
        assertEq(t.version, "1");
        assertEq(t.chainId, block.chainid);
        assertEq(t.verifyingContract, address(mockToTest));
        assertEq(t.salt, bytes32(0));
        assertEq(t.extensions, new uint256[](0));
    }
}
