// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {SignatureCheckerLib} from "../src/utils/SignatureCheckerLib.sol";
import {ERC6551Proxy} from "../src/accounts/ERC6551Proxy.sol";
import {EIP712} from "../src/utils/EIP712.sol";
import {ERC6551, MockERC6551, MockERC6551V2} from "./utils/mocks/MockERC6551.sol";
import {MockERC6551Registry} from "./utils/mocks/MockERC6551Registry.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";
import {MockERC1155} from "./utils/mocks/MockERC1155.sol";
import {LibZip} from "../src/utils/LibZip.sol";
import {LibClone} from "../src/utils/LibClone.sol";
import {LibString} from "../src/utils/LibString.sol";

contract ERC1271Test is SoladyTest {
    MockERC6551Registry internal _registry;

    address internal _erc6551;

    address internal _erc6551V2;

    address internal _erc721;

    address internal _proxy;

    // By right, this should be the keccak256 of some long-ass string:
    // (e.g. `keccak256("Parent(bytes32 childHash,Mail child)Mail(Person from,Person to,string contents)Person(string name,address wallet)")`).
    // But I'm lazy and will use something randomish here.
    bytes32 internal constant _PARENT_TYPEHASH =
        0xd61db970ec8a2edc5f9fd31d876abe01b785909acb16dcd4baaf3b434b4c439b;

    // By right, this should be a proper domain separator, but I'm lazy.
    bytes32 internal constant _DOMAIN_SEP_B =
        0xa1a044077d7677adbbfa892ded5390979b33993e0e2a457e3f974bbcda53821b;

    bytes32 internal constant _ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    struct _TestTemps {
        address owner;
        uint256 chainId;
        uint256 tokenId;
        bytes32 salt;
        MockERC6551 account;
        address signer;
        uint256 privateKey;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function setUp() public {
        _registry = new MockERC6551Registry();
        _erc6551 = address(new MockERC6551());
        _erc721 = address(new MockERC721());
        _proxy = address(new ERC6551Proxy(_erc6551));
        _erc6551V2 = address(new MockERC6551V2());
    }

    function _etchNicksFactory() internal returns (address nicksFactory) {
        nicksFactory = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
        if (nicksFactory.code.length != 0) {
            vm.etch(
                nicksFactory,
                hex"7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3"
            );
        }
    }

    function _etchBasefeeContract(bytes32 salt, bytes memory initcode) internal {
        (bool success,) = _etchNicksFactory().call(abi.encodePacked(salt, initcode));
        assertTrue(success);
    }

    function _etchBasefeeContract() internal {
        bytes memory initcode = hex"65483d52593df33d526006601af3";
        emit LogBytes32(keccak256(initcode));
        bytes32 salt = 0x00000000000000000000000000000000000000003c6f8b80e9be740191d2e48f;
        _etchBasefeeContract(salt, initcode);
    }

    function testBasefeeBytecodeContract() public {
        address deployment = 0x000000000000378eDCD5B5B0A24f5342d8C10485;
        vm.fee(11);
        assertEq(_basefee(deployment), 0);
        assertEq(deployment.code.length, 0);
        _etchBasefeeContract();
        assertEq(deployment.code.length, 6);
        assertEq(_basefee(deployment), 11);
        vm.fee(12);
        assertEq(_basefee(deployment), 12);
    }

    function _basefee(address deployment) internal view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x00)
            pop(staticcall(0xffff, deployment, codesize(), 0x00, 0x00, 0x20))
            result := mload(0x00)
        }
    }

    function _testTempsMint(address owner) internal returns (uint256 tokenId) {
        while (true) {
            tokenId = _random() % 8 == 0 ? _random() % 32 : _random();
            (bool success,) =
                _erc721.call(abi.encodeWithSignature("mint(address,uint256)", owner, tokenId));
            if (success) return tokenId;
        }
    }

    function _testTemps() internal returns (_TestTemps memory t) {
        t.owner = _randomNonZeroAddress();
        t.tokenId = _testTempsMint(t.owner);
        t.chainId = block.chainid;
        t.salt = bytes32(_random());
        address account = _registry.createAccount(_proxy, t.salt, t.chainId, _erc721, t.tokenId);
        t.account = MockERC6551(payable(account));
    }

    struct _TestIsValidSignatureTemps {
        string uppercased;
        string lowercased;
        string rest;
        string banned;
    }

    function testIsValidSignature(uint256 x) public {
        vm.txGasPrice(10);
        if (_random() % 8 == 0) {
            _testIsValidSignature(abi.encodePacked(uint8(x)), false);
        }
        if (_random() % 32 == 0) {
            _etchBasefeeContract();
        }
        _TestIsValidSignatureTemps memory t;
        t.uppercased = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        t.lowercased = "abcdefghijklmnopqrstuvwxyz";
        t.rest = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_";
        t.banned = "\x00 ,)";
        if (_random() % 4 == 0) {
            bytes memory contentsType = abi.encodePacked(
                _randomString(t.uppercased, true), _randomString(t.rest, false), "(bytes32 stuff)"
            );
            _testIsValidSignature(contentsType, true);
        }
        if (_random() % 4 == 0) {
            bytes memory contentsType = abi.encodePacked(
                _randomString(t.uppercased, false),
                _randomString(t.banned, true),
                _randomString(t.rest, false),
                "(bytes32 stuff)"
            );
            _testIsValidSignature(contentsType, false);
        }
        if (_random() % 4 == 0) {
            bytes memory contentsType = abi.encodePacked(
                _randomString(t.lowercased, true), _randomString(t.rest, false), "(bytes32 stuff)"
            );
            _testIsValidSignature(contentsType, false);
        }
        if (_random() % 4 == 0) {
            bytes memory contentsType =
                abi.encodePacked(_randomString(t.uppercased, true), _randomString(t.rest, false));
            _testIsValidSignature(contentsType, false);
        }
        if (_random() % 16 == 0) {
            _testIsValidSignatureWontOutOfGas();
        }
    }

    function _randomString(string memory byteChoices, bool nonEmpty)
        internal
        returns (string memory result)
    {
        uint256 randomness = _random();
        uint256 resultLength = _bound(_random(), nonEmpty ? 1 : 0, _random() % 32 != 0 ? 4 : 128);
        /// @solidity memory-safe-assembly
        assembly {
            if mload(byteChoices) {
                result := mload(0x40)
                mstore(0x00, randomness)
                mstore(0x40, and(add(add(result, 0x40), resultLength), not(31)))
                mstore(result, resultLength)

                // forgefmt: disable-next-item
                for { let i := 0 } lt(i, resultLength) { i := add(i, 1) } {
                    mstore(0x20, gas())
                    mstore8(
                        add(add(result, 0x20), i), 
                        mload(add(add(byteChoices, 1), mod(keccak256(0x00, 0x40), mload(byteChoices))))
                    )
                }
            }
        }
    }

    function testIsValidSignature() public {
        vm.txGasPrice(10);

        _testIsValidSignature("Contents(bytes32 stuff)", true);
        _testIsValidSignature("ABC(bytes32 stuff)", true);
        _testIsValidSignature("C(bytes32 stuff)", true);

        _testIsValidSignature("(bytes32 stuff)", false);
        _testIsValidSignature("contents(bytes32 stuff)", false);

        _testIsValidSignature("ABC,(bytes32 stuff)", false);
        _testIsValidSignature("ABC (bytes32 stuff)", false);
        _testIsValidSignature("ABC)(bytes32 stuff)", false);
        _testIsValidSignature("ABC\x00(bytes32 stuff)", false);

        _testIsValidSignature("X(", true);
        _testIsValidSignature("X)", false);
        _testIsValidSignature("X(bytes32 stuff)", true);
        _testIsValidSignature("TheQuickBrownFoxJumpsOverTheLazyDog(bytes32 stuff)", true);

        _testIsValidSignature("bytes32", false);
        _testIsValidSignature("()", false);
    }

    function _testIsValidSignature(bytes memory contentsType, bool success) internal {
        bytes32 contents = keccak256(abi.encode(_random(), contentsType));

        _TestTemps memory t = _testTemps();
        (t.signer, t.privateKey) = _randomSigner();
        (t.v, t.r, t.s) =
            vm.sign(t.privateKey, _toERC1271Hash(address(t.account), contents, contentsType));

        vm.prank(t.owner);
        MockERC721(_erc721).safeTransferFrom(t.owner, t.signer, t.tokenId);

        bytes memory signature = abi.encodePacked(
            t.r, t.s, t.v, _DOMAIN_SEP_B, contents, contentsType, uint16(contentsType.length)
        );
        if (_random() % 4 == 0) signature = _erc6492Wrap(signature);
        // Success returns `0x1626ba7e`.
        assertEq(
            t.account.isValidSignature(_toContentsHash(contents), signature),
            success ? bytes4(0x1626ba7e) : bytes4(0xffffffff)
        );
    }

    function _testIsValidSignatureWontOutOfGas() internal {
        _TestTemps memory t = _testTemps();
        assertEq(
            t.account.isValidSignature(keccak256("hehe"), bytes(_randomString("abc", false))),
            bytes4(0xffffffff)
        );
    }

    function _erc6492Wrap(bytes memory signature) internal returns (bytes memory) {
        return abi.encodePacked(
            abi.encode(_randomNonZeroAddress(), bytes(_randomString("12345", false)), signature),
            bytes32(0x6492649264926492649264926492649264926492649264926492649264926492)
        );
    }

    struct _AccountDomainStruct {
        bytes1 fields;
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
        bytes32 salt;
        uint256[] extensions;
    }

    function _accountDomainStructFields(address account) internal view returns (bytes memory) {
        _AccountDomainStruct memory t;
        (t.fields, t.name, t.version, t.chainId, t.verifyingContract, t.salt, t.extensions) =
            EIP712(account).eip712Domain();

        return abi.encode(
            t.fields,
            keccak256(bytes(t.name)),
            keccak256(bytes(t.version)),
            t.chainId,
            t.verifyingContract,
            t.salt,
            keccak256(abi.encodePacked(t.extensions))
        );
    }

    function _typedDataSignTypeHash(bytes memory contentsType) internal pure returns (bytes32) {
        bytes memory ct = contentsType;
        return keccak256(
            abi.encodePacked(
                "TypedDataSign(",
                LibString.slice(string(ct), 0, LibString.indexOf(string(ct), "(", 0)),
                " contents,bytes1 fields,string name,string version,uint256 chainId,address verifyingContract,bytes32 salt,uint256[] extensions)",
                ct
            )
        );
    }

    function _toERC1271Hash(address account, bytes32 contents, bytes memory contentsType)
        internal
        view
        returns (bytes32)
    {
        bytes32 parentStructHash = keccak256(
            abi.encodePacked(
                abi.encode(_typedDataSignTypeHash(contentsType), contents),
                _accountDomainStructFields(account)
            )
        );
        return keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEP_B, parentStructHash));
    }

    function _toContentsHash(bytes32 contents) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"1901", _DOMAIN_SEP_B, contents));
    }
}
