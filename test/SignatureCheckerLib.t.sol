// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {SignatureCheckerLib} from "../src/utils/SignatureCheckerLib.sol";
import {ECDSA} from "../src/utils/ECDSA.sol";
import {MockERC1271Wallet} from "./utils/mocks/MockERC1271Wallet.sol";
import {MockERC1271Malicious} from "./utils/mocks/MockERC1271Malicious.sol";
import {LibClone} from "../src/utils/LibClone.sol";

contract SignatureCheckerLibTest is SoladyTest {
    bytes32 constant TEST_MESSAGE =
        0x7dbaf558b0a1a5dc7a67202117ab143c1d8605a983e4a743bc06fcc03162dc0d;

    bytes32 constant WRONG_MESSAGE =
        0x2d0828dd7c97cff316356da3c16c68ba2316886a0e05ebafb8291939310d51a3;

    address constant SIGNER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    address constant OTHER = address(uint160(1));

    bytes32 constant TEST_SIGNED_MESSAGE_HASH =
        0x7d768af957ef8cbf6219a37e743d5546d911dae3e46449d8a5810522db2ef65e;

    bytes32 constant WRONG_SIGNED_MESSAGE_HASH =
        0x8cd3e659093d21364c6330514aff328218aa29c2693c5b0e96602df075561952;

    bytes constant SIGNATURE =
        hex"8688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe2652815db01c2c84b0ec746e1b74d97475c599b3d3419fa7181b4e01de62c02b721aea1b";

    bytes constant INVALID_SIGNATURE =
        hex"7688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe2652815db01c2c84b0ec746e1b74d97475c599b3d3419fa7181b4e01de62c02b721aea1b";

    MockERC1271Wallet mockERC1271Wallet;

    MockERC1271Malicious mockERC1271Malicious;

    function setUp() public {
        mockERC1271Wallet = new MockERC1271Wallet(SIGNER);
        mockERC1271Malicious = new MockERC1271Malicious();
    }

    function testSignatureCheckerOnEOAWithMatchingSignerAndSignature() public {
        _checkSignature(SIGNER, TEST_SIGNED_MESSAGE_HASH, SIGNATURE, true);
    }

    function testSignatureCheckerOnEOAWithInvalidSigner() public {
        _checkSignature(OTHER, TEST_SIGNED_MESSAGE_HASH, SIGNATURE, false);
    }

    function testSignatureCheckerOnEOAWithWrongSignedMessageHash() public {
        _checkSignature(SIGNER, WRONG_SIGNED_MESSAGE_HASH, SIGNATURE, false);
    }

    function testSignatureCheckerOnEOAWithInvalidSignature() public {
        _checkSignature(SIGNER, TEST_SIGNED_MESSAGE_HASH, INVALID_SIGNATURE, false);
    }

    function testSignatureCheckerOnWalletWithMatchingSignerAndSignature() public {
        _checkSignatureBothModes(
            address(mockERC1271Wallet), TEST_SIGNED_MESSAGE_HASH, SIGNATURE, true
        );
    }

    function testSignatureCheckerOnWalletWithInvalidSigner() public {
        _checkSignatureBothModes(address(this), TEST_SIGNED_MESSAGE_HASH, SIGNATURE, false);
    }

    function testSignatureCheckerOnWalletWithZeroAddressSigner() public {
        _checkSignatureBothModes(address(0), TEST_SIGNED_MESSAGE_HASH, SIGNATURE, false);
    }

    function testSignatureCheckerOnWalletWithWrongSignedMessageHash() public {
        _checkSignatureBothModes(
            address(mockERC1271Wallet), WRONG_SIGNED_MESSAGE_HASH, SIGNATURE, false
        );
    }

    function testSignatureCheckerOnWalletWithInvalidSignature() public {
        _checkSignatureBothModes(
            address(mockERC1271Wallet), TEST_SIGNED_MESSAGE_HASH, INVALID_SIGNATURE, false
        );
    }

    function testSignatureCheckerOnMaliciousWallet() public {
        _checkSignatureBothModes(
            address(mockERC1271Malicious), WRONG_SIGNED_MESSAGE_HASH, SIGNATURE, false
        );
    }

    function testSignatureChecker(bytes32 digest) public {
        (address signer, uint256 privateKey) = _randomSigner();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        _checkSignature(signer, digest, abi.encodePacked(r, s, v), true);

        if (_randomChance(8)) {
            assertEq(
                this.isValidSignatureNowCalldata(signer, digest, abi.encodePacked(r, s, v)), true
            );
            assertEq(
                SignatureCheckerLib.isValidSignatureNow(signer, digest, abi.encodePacked(r, s, v)),
                true
            );
            assertEq(
                SignatureCheckerLib.isValidSignatureNow(
                    signer, digest, abi.encodePacked(r, s, v + 1)
                ),
                false
            );
            assertEq(
                SignatureCheckerLib.isValidSignatureNow(
                    signer, digest, abi.encodePacked(r, s, v - 1)
                ),
                false
            );
            assertEq(SignatureCheckerLib.isValidSignatureNow(signer, digest, v, r, s), true);
        }

        if (_randomChance(8)) {
            bytes32 vs;
            /// @solidity memory-safe-assembly
            assembly {
                vs := or(shl(255, sub(v, 27)), s)
            }
            assertEq(SignatureCheckerLib.isValidSignatureNow(signer, digest, r, vs), true);
            assertEq(
                SignatureCheckerLib.isValidSignatureNow(signer, digest, abi.encode(r, vs)), true
            );
            assertEq(this.isValidSignatureNowCalldata(signer, digest, abi.encode(r, vs)), true);
        }

        if (_randomChance(8)) {
            bytes32 vsc; // Corrupted `vs`.
            /// @solidity memory-safe-assembly
            assembly {
                vsc := or(shl(255, xor(1, sub(v, 27))), s)
            }
            assertEq(SignatureCheckerLib.isValidSignatureNow(signer, digest, r, vsc), false);
            assertEq(
                SignatureCheckerLib.isValidSignatureNow(signer, digest, abi.encode(r, vsc)), false
            );
            assertEq(this.isValidSignatureNowCalldata(signer, digest, abi.encode(r, vsc)), false);
        }

        if (_randomChance(8) && r != bytes32(0) && s != bytes32(0)) {
            bytes32 rc = bytes32(uint256(r) - (_random() & 1)); // Corrupted `r`.
            bytes32 sc = bytes32(uint256(s) - (_random() & 1)); // Corrupted `s`.
            bool anyCorrupted = rc != r || sc != s;
            _checkSignature(signer, digest, abi.encodePacked(rc, sc, v), !anyCorrupted);
        }

        if (_randomChance(8)) {
            uint8 vc = uint8(_random()); // Corrupted `v`.
            while (vc == 28 || vc == 27) vc = uint8(_random());
            assertEq(SignatureCheckerLib.isValidSignatureNow(signer, digest, vc, r, s), false);
            assertEq(
                SignatureCheckerLib.isValidSignatureNow(signer, digest, abi.encodePacked(r, s, vc)),
                false
            );
            assertEq(
                this.isValidSignatureNowCalldata(signer, digest, abi.encodePacked(r, s, vc)), false
            );
        }
    }

    function _checkSignatureBothModes(
        address signer,
        bytes32 hash,
        bytes memory signature,
        bool expectedResult
    ) internal {
        _checkSignature(false, signer, hash, signature, expectedResult);
        _checkSignature(true, signer, hash, signature, expectedResult);
    }

    function _checkSignature(
        address signer,
        bytes32 hash,
        bytes memory signature,
        bool expectedResult
    ) internal {
        _checkSignature(false, signer, hash, signature, expectedResult);
    }

    function _checkSignature(
        bool onlyERC1271,
        address signer,
        bytes32 hash,
        bytes memory signature,
        bool expectedResult
    ) internal {
        bool callResult;
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)

            // `bytes4(keccak256("isValidSignatureNow(address,bytes32,bytes)"))`.
            mstore(m, shl(224, 0x6ccea652))
            if onlyERC1271 {
                // `bytes4(keccak256("isValidERC1271SignatureNow(address,bytes32,bytes)"))`.
                mstore(m, shl(224, 0x3ae5d83c))
            }
            // We'll still clean the upper 96 bits of signer,
            // so that it will pass the implicit calldata check added by Solidity.
            mstore(add(m, 0x04), shr(96, shl(96, signer)))
            mstore(add(m, 0x24), hash)
            mstore(add(m, 0x44), 0x60) // Offset of signature in calldata.
            mstore(add(m, 0x64), mload(signature))
            mstore(add(m, 0x84), mload(add(signature, 0x20)))
            mstore(add(m, 0xa4), mload(add(signature, 0x40)))
            mstore(add(m, 0xc4), mload(add(signature, 0x60)))
            // Brutalize the bytes following the 8-bit `v`. All ones will do.
            mstore(add(m, 0xc5), not(0))

            // We have to do the call in assembly to ensure that Solidity does not
            // clean up the brutalized bits.
            callResult :=
                and(
                    and(
                        // Whether the returndata is equal to 1.
                        eq(mload(0x00), 1),
                        // Whether the returndata is exactly 0x20 bytes (1 word) long .
                        eq(returndatasize(), 0x20)
                    ),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        address(), // The current contract's address.
                        m, // Offset of calldata in memory.
                        0xe4, // Length of calldata in memory.
                        0x00, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
        }
        assertEq(callResult, expectedResult);

        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32 vs;
        /// @solidity memory-safe-assembly
        assembly {
            // Contaminate the upper 96 bits.
            signer := or(shl(160, 1), signer)
            // Extract `r`, `s`, `v`.
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
            // Pack `vs`.
            vs := or(shl(255, sub(v, 27)), s)

            // Brutalize the memory. Just all ones will do.
            let m := mload(0x40)
            for { let i := 0 } lt(i, 30) { i := add(i, 1) } { mstore(add(m, shl(5, i)), not(0)) }
        }

        if (onlyERC1271) {
            assertEq(
                SignatureCheckerLib.isValidERC1271SignatureNow(signer, hash, r, vs), expectedResult
            );
            assertEq(
                SignatureCheckerLib.isValidERC1271SignatureNow(signer, hash, v, r, s),
                expectedResult
            );
        } else {
            assertEq(SignatureCheckerLib.isValidSignatureNow(signer, hash, r, vs), expectedResult);
            assertEq(SignatureCheckerLib.isValidSignatureNow(signer, hash, v, r, s), expectedResult);
        }
    }

    function isValidSignatureNow(address signer, bytes32 hash, bytes calldata signature)
        external
        returns (bool result)
    {
        bool signatureIsBrutalized;
        /// @solidity memory-safe-assembly
        assembly {
            // Contaminate the upper 96 bits.
            signer := or(shl(160, 1), signer)
            // Ensure that the bytes right after the signature is brutalized.
            signatureIsBrutalized := calldataload(add(signature.offset, signature.length))
        }
        if (!signatureIsBrutalized) revert("Signature is not brutalized.");

        result = SignatureCheckerLib.isValidSignatureNowCalldata(signer, hash, signature);
        assertEq(SignatureCheckerLib.isValidSignatureNow(signer, hash, signature), result);
    }

    function isValidERC1271SignatureNow(address signer, bytes32 hash, bytes calldata signature)
        external
        returns (bool result)
    {
        bool signatureIsBrutalized;
        /// @solidity memory-safe-assembly
        assembly {
            // Contaminate the upper 96 bits.
            signer := or(shl(160, 1), signer)
            // Ensure that the bytes right after the signature is brutalized.
            signatureIsBrutalized := calldataload(add(signature.offset, signature.length))
        }
        if (!signatureIsBrutalized) revert("Signature is not brutalized.");

        result = SignatureCheckerLib.isValidERC1271SignatureNowCalldata(signer, hash, signature);
        assertEq(SignatureCheckerLib.isValidERC1271SignatureNow(signer, hash, signature), result);
    }

    function isValidSignatureNowCalldata(address signer, bytes32 hash, bytes calldata signature)
        external
        view
        returns (bool result)
    {
        result = SignatureCheckerLib.isValidSignatureNowCalldata(signer, hash, signature);
    }

    function isValidERC1271SignatureNowCalldata(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) external view returns (bool result) {
        result = SignatureCheckerLib.isValidERC1271SignatureNowCalldata(signer, hash, signature);
    }

    function testEmptyCalldataHelpers() public {
        assertFalse(
            SignatureCheckerLib.isValidSignatureNow(
                address(1), bytes32(0), SignatureCheckerLib.emptySignature()
            )
        );
    }

    function testToEthSignedMessageHashDifferential(bytes32 hash) public {
        assertEq(
            SignatureCheckerLib.toEthSignedMessageHash(hash), ECDSA.toEthSignedMessageHash(hash)
        );
    }

    function testToEthSignedMessageHashDifferential(bytes memory s) public {
        assertEq(SignatureCheckerLib.toEthSignedMessageHash(s), ECDSA.toEthSignedMessageHash(s));
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

    bytes32 private constant _ERC6492_DETECTION_SUFFIX =
        0x6492649264926492649264926492649264926492649264926492649264926492;

    struct _ERC6492TestTemps {
        bytes initcode;
        bytes factoryCalldata;
        bytes setSignerCalldata;
        address eoa;
        bytes32 salt;
        uint256 privateKey;
        address factory;
        address smartAccount;
        bytes32 digest;
        bytes innerSignature;
        bytes signature;
        bool result;
        address revertingVerifier;
    }

    function _erc6492TestTemps() internal returns (_ERC6492TestTemps memory t) {
        t.factory = _etchNicksFactory();
        assertGt(t.factory.code.length, 0);
        (t.eoa, t.privateKey) = _randomSigner();
        t.initcode = abi.encodePacked(type(MockERC1271Wallet).creationCode, uint256(uint160(t.eoa)));
        t.salt = bytes32(_random());
        t.factoryCalldata = abi.encodePacked(t.salt, t.initcode);
        t.smartAccount =
            LibClone.predictDeterministicAddress(keccak256(t.initcode), t.salt, t.factory);
        assertEq(t.smartAccount.code.length, 0);

        t.digest = keccak256(abi.encodePacked("Hehe", _random()));
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(t.privateKey, t.digest);
            t.innerSignature = abi.encodePacked(r, s, v);
        }
        t.signature = abi.encode(t.factory, t.factoryCalldata, t.innerSignature);
        t.signature = abi.encodePacked(t.signature, _ERC6492_DETECTION_SUFFIX);
    }

    function _makeNewEOA(_ERC6492TestTemps memory t) internal {
        while (true) {
            (address newEOA, uint256 newPrivateKey) = _randomSigner();
            if (newEOA == t.eoa) continue;
            t.eoa = newEOA;
            t.privateKey = newPrivateKey;
            t.digest = keccak256(abi.encodePacked("Haha", _random()));
            {
                (uint8 v, bytes32 r, bytes32 s) = vm.sign(t.privateKey, t.digest);
                t.innerSignature = abi.encodePacked(r, s, v);
            }
            t.setSignerCalldata = abi.encodeWithSignature("setSigner(address)", t.eoa);
            t.signature = abi.encode(t.smartAccount, t.setSignerCalldata, t.innerSignature);
            t.signature = abi.encodePacked(t.signature, _ERC6492_DETECTION_SUFFIX);
            break;
        }
    }

    function testERC6492AllowSideEffectsPostDeploy() public {
        _ERC6492TestTemps memory t = _erc6492TestTemps();
        (bool success,) = t.factory.call(t.factoryCalldata);
        require(success);
        assertGt(t.smartAccount.code.length, 0);
        t.result = SignatureCheckerLib.isValidERC6492SignatureNowAllowSideEffects(
            t.smartAccount, t.digest, t.innerSignature
        );
        assertTrue(t.result);

        _makeNewEOA(t);
        t.result = SignatureCheckerLib.isValidERC6492SignatureNowAllowSideEffects(
            t.smartAccount, t.digest, t.signature
        );
        assertTrue(t.result);
        assertEq(MockERC1271Wallet(t.smartAccount).signer(), t.eoa);
    }

    function testERC6492AllowSideEffectsPreDeploy() public {
        _ERC6492TestTemps memory t = _erc6492TestTemps();
        t.result = SignatureCheckerLib.isValidERC6492SignatureNowAllowSideEffects(
            t.smartAccount, t.digest, t.innerSignature
        );
        assertFalse(t.result);
        // This should return false, as the function does NOT do ECDSA fallback.
        t.result = SignatureCheckerLib.isValidERC6492SignatureNowAllowSideEffects(
            t.eoa, t.digest, t.innerSignature
        );
        assertFalse(t.result);
        assertEq(t.smartAccount.code.length, 0);
        t.result = SignatureCheckerLib.isValidERC6492SignatureNowAllowSideEffects(
            t.smartAccount, t.digest, t.signature
        );
        assertTrue(t.result);
        assertGt(t.smartAccount.code.length, 0);
        t.result = SignatureCheckerLib.isValidERC6492SignatureNowAllowSideEffects(
            t.smartAccount, t.digest, t.signature
        );
        assertTrue(t.result);
        assertGt(t.smartAccount.code.length, 0);
        assertEq(MockERC1271Wallet(t.smartAccount).signer(), t.eoa);

        _makeNewEOA(t);
        t.result = SignatureCheckerLib.isValidERC6492SignatureNowAllowSideEffects(
            t.smartAccount, t.digest, t.signature
        );
        assertTrue(t.result);
        assertEq(MockERC1271Wallet(t.smartAccount).signer(), t.eoa);
    }

    function _etchERC6492RevertingVerifier() internal returns (address revertingVerifier) {
        _ERC6492TestTemps memory t;
        t.initcode =
            hex"6040600b3d3960403df3fe36383d373d3d6020515160208051013d3d515af160203851516084018038385101606037303452813582523838523490601c34355afa34513060e01b141634fd";
        t.factory = _etchNicksFactory();
        t.salt = 0x000000000000000000000000000000000000000068f35e1510740001fd13984a;
        (bool success,) = t.factory.call(abi.encodePacked(t.salt, t.initcode));
        revertingVerifier =
            LibClone.predictDeterministicAddress(keccak256(t.initcode), t.salt, t.factory);
        assertTrue(success);
        assertGt(revertingVerifier.code.length, 0);
        emit LogBytes32(keccak256(t.initcode));
        emit LogBytes(revertingVerifier.code);
    }

    function testEtchERC6492RevertingVerifier() public {
        _etchERC6492RevertingVerifier();
    }

    function testERC6492PostDeploy() public {
        _ERC6492TestTemps memory t = _erc6492TestTemps();
        t.revertingVerifier = _etchERC6492RevertingVerifier();
        (bool success,) = t.factory.call(t.factoryCalldata);
        require(success);

        assertGt(t.smartAccount.code.length, 0);
        t.result = SignatureCheckerLib.isValidERC6492SignatureNow(
            t.smartAccount, t.digest, t.innerSignature
        );
        assertTrue(t.result);

        address oldEOA = t.eoa;
        _makeNewEOA(t);
        t.result =
            SignatureCheckerLib.isValidERC6492SignatureNow(t.smartAccount, t.digest, t.signature);
        assertTrue(t.result);
        assertEq(MockERC1271Wallet(t.smartAccount).signer(), oldEOA);
    }

    function testERC6492PreDeploy() public {
        _ERC6492TestTemps memory t = _erc6492TestTemps();
        t.revertingVerifier = _etchERC6492RevertingVerifier();

        t.result = SignatureCheckerLib.isValidERC6492SignatureNow(
            t.smartAccount, t.digest, t.innerSignature
        );
        assertFalse(t.result);
        // This should return false, as the function does NOT do ECDSA fallback.
        t.result = SignatureCheckerLib.isValidERC6492SignatureNow(t.eoa, t.digest, t.innerSignature);
        assertFalse(t.result);
        assertEq(t.smartAccount.code.length, 0);
        t.result =
            SignatureCheckerLib.isValidERC6492SignatureNow(t.smartAccount, t.digest, t.signature);
        assertTrue(t.result);
        assertEq(t.smartAccount.code.length, 0);
        t.result =
            SignatureCheckerLib.isValidERC6492SignatureNow(t.smartAccount, t.digest, t.signature);
        assertTrue(t.result);
        assertEq(t.smartAccount.code.length, 0);

        t.result = SignatureCheckerLib.isValidERC6492SignatureNow(
            t.smartAccount, keccak256(""), t.signature
        );
        assertFalse(t.result);
        assertEq(t.smartAccount.code.length, 0);
    }

    function testERC6492WithoutRevertingVerifier() public {
        _ERC6492TestTemps memory t = _erc6492TestTemps();

        t.result = SignatureCheckerLib.isValidERC6492SignatureNow(
            t.smartAccount, t.digest, t.innerSignature
        );
        assertFalse(t.result);

        t.result = SignatureCheckerLib.isValidERC6492SignatureNow(
            t.smartAccount, t.digest, t.innerSignature
        );
        assertFalse(t.result);
        // This should return false, as the function does NOT do ECDSA fallback.
        t.result = SignatureCheckerLib.isValidERC6492SignatureNow(t.eoa, t.digest, t.innerSignature);
        assertFalse(t.result);
        assertEq(t.smartAccount.code.length, 0);
        // Without the reverting verifier, the function will simply return false.
        t.result =
            SignatureCheckerLib.isValidERC6492SignatureNow(t.smartAccount, t.digest, t.signature);
        assertFalse(t.result);
        assertEq(t.smartAccount.code.length, 0);
        t.result =
            SignatureCheckerLib.isValidERC6492SignatureNow(t.smartAccount, t.digest, t.signature);
        assertFalse(t.result);
        assertEq(t.smartAccount.code.length, 0);
    }
}
