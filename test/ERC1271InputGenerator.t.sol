// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {MockERC6551} from "./utils/mocks/MockERC6551.sol";
import {ERC1271InputGenerator} from "../src/accounts/ERC1271InputGenerator.sol";
import {LibERC6551} from "../src/accounts/LibERC6551.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";

contract ERC1271InputGeneratorTest is SoladyTest {
    address internal _erc6551;

    address internal _erc721;

    // By right, this should be a proper domain separator, but I'm lazy.
    bytes32 internal constant _DOMAIN_SEP_B =
        0xa1a044077d7677adbbfa892ded5390979b33993e0e2a457e3f974bbcda53821b;

    bytes32 internal constant _ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function setUp() public {
        vm.etch(LibERC6551.REGISTRY, LibERC6551.REGISTRY_BYTECODE);
        _erc6551 = address(new MockERC6551());
        _erc721 = address(new MockERC721());
        MockERC721(_erc721).mint(address(this), 1);
    }

    function _getERC1271Input(
        address account,
        bytes32 hash,
        bytes32 parentTypehash,
        bytes32 child,
        address accountFactory,
        bytes memory factoryCalldata
    ) internal returns (bytes32 result) {
        bytes memory c =
            abi.encode(account, hash, parentTypehash, child, accountFactory, factoryCalldata);
        c = abi.encodePacked(type(ERC1271InputGenerator).creationCode, c);
        /// @solidity memory-safe-assembly
        assembly {
            let deployed := create(0, add(c, 0x20), mload(c))
            mstore(0x00, 0x00)
            extcodecopy(deployed, 0x00, 0x20, 0x20)
            result := mload(0x00)
        }
    }

    function testERC1271Input(bytes32 parentTypehash, bytes32 child) public {
        if (_random() % 16 == 0) child = bytes32(0);

        address account;
        if (_random() % 2 == 0) {
            account = LibERC6551.account(_erc6551, bytes32(0), block.chainid, address(_erc721), 1);
        } else {
            account =
                LibERC6551.createAccount(_erc6551, bytes32(0), block.chainid, address(_erc721), 1);
        }

        bytes memory factoryCalldata = abi.encodeWithSignature(
            "createAccount(address,bytes32,uint256,address,uint256)",
            _erc6551,
            bytes32(0),
            block.chainid,
            address(_erc721),
            1
        );

        bytes32 computed = _getERC1271Input(
            account,
            _toChildHash(child),
            parentTypehash,
            child,
            LibERC6551.REGISTRY,
            factoryCalldata
        );
        bytes32 expected;
        if (child == bytes32(0)) {
            expected = _toERC1271HashPersonalSign(parentTypehash, account, _toChildHash(child));
        } else {
            expected = _toERC1271Hash(parentTypehash, account, child);
        }
        assertEq(computed, expected);
    }

    function _toERC1271HashPersonalSign(bytes32 parentTypehash, address account, bytes32 childHash)
        internal
        view
        returns (bytes32)
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("Milady"),
                keccak256("1"),
                block.chainid,
                address(account)
            )
        );
        bytes32 parentStructHash = keccak256(abi.encode(parentTypehash, childHash));
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, parentStructHash));
    }

    function _toERC1271Hash(bytes32 parentTypehash, address account, bytes32 child)
        internal
        view
        returns (bytes32)
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("Milady"),
                keccak256("1"),
                block.chainid,
                address(account)
            )
        );
        bytes32 parentStructHash = keccak256(abi.encode(parentTypehash, _toChildHash(child), child));
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, parentStructHash));
    }

    function _toChildHash(bytes32 child) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"1901", _DOMAIN_SEP_B, child));
    }
}
