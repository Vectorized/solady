// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./../../utils/SoladyTest.sol";
import {SignatureCheckerLib} from "../../../src/utils/ext/zksync/SignatureCheckerLib.sol";
import {ECDSA} from "../../../src/utils/ECDSA.sol";
import {MockERC1271Wallet} from "./../../utils/mocks/MockERC1271Wallet.sol";
import {MockERC1271Malicious} from "./../../utils/mocks/MockERC1271Malicious.sol";

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
        address signer = address(mockERC1271Wallet);
        bytes32 hash = TEST_SIGNED_MESSAGE_HASH;
        bytes memory signature = SIGNATURE;
        _checkSignature(true, signer, hash, signature, true);
        _checkSignature(false, signer, hash, signature, true);
        vm.etch(signer, "");
        _checkSignature(false, signer, hash, signature, false);
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

    function testSignatureCheckerPassthrough(bytes calldata signature) public {
        bytes32 hash = keccak256(signature);
        mockERC1271Wallet.setUseSignaturePassthrough(true);
        if (_randomChance(8)) {
            _misalignFreeMemoryPointer();
            _brutalizeMemory();
        }
        address signer = address(mockERC1271Wallet);
        assertEq(SignatureCheckerLib.isValidSignatureNowCalldata(signer, hash, signature), true);
        assertEq(SignatureCheckerLib.isValidSignatureNow(signer, hash, signature), true);

        hash = bytes32(uint256(hash) ^ 1);
        assertEq(SignatureCheckerLib.isValidSignatureNowCalldata(signer, hash, signature), false);
        assertEq(SignatureCheckerLib.isValidSignatureNow(signer, hash, signature), false);
    }

    function _makeShortSignature(bytes memory signature)
        internal
        pure
        returns (bytes memory result)
    {
        require(signature.length == 65);
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let r := mload(add(signature, 0x20))
            let s := mload(add(signature, 0x40))
            let v := byte(0, mload(add(signature, 0x60)))
            let vs := 0
            switch v
            case 27 { vs := shr(1, shl(1, s)) }
            case 28 { vs := or(shl(255, 1), shr(1, shl(1, s))) }
            default { invalid() }
            mstore(result, 0x40) // Length.
            mstore(add(result, 0x20), r)
            mstore(add(result, 0x40), vs)
            mstore(0x40, add(result, 0x60)) // Allocate memory.
        }
    }
}
