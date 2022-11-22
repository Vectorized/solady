// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {SignatureCheckerLib} from "../src/utils/SignatureCheckerLib.sol";
import {MockERC1271Wallet} from "./utils/mocks/MockERC1271Wallet.sol";
import {MockERC1271Malicious} from "./utils/mocks/MockERC1271Malicious.sol";

contract SignatureCheckerLibTest is Test {
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
        _checkSignature(address(mockERC1271Wallet), TEST_SIGNED_MESSAGE_HASH, SIGNATURE, true);
    }

    function testSignatureCheckerOnWalletWithInvalidSigner() public {
        _checkSignature(address(this), TEST_SIGNED_MESSAGE_HASH, SIGNATURE, false);
    }

    function testSignatureCheckerOnWalletWithZeroAddressSigner() public {
        _checkSignature(address(0), TEST_SIGNED_MESSAGE_HASH, SIGNATURE, false);
    }

    function testSignatureCheckerOnWalletWithWrongSignedMessageHash() public {
        _checkSignature(address(mockERC1271Wallet), WRONG_SIGNED_MESSAGE_HASH, SIGNATURE, false);
    }

    function testSignatureCheckerOnWalletWithInvalidSignature() public {
        _checkSignature(
            address(mockERC1271Wallet), TEST_SIGNED_MESSAGE_HASH, INVALID_SIGNATURE, false
        );
    }

    function testSignatureCheckerOnMaliciousWallet() public {
        _checkSignature(address(mockERC1271Malicious), WRONG_SIGNED_MESSAGE_HASH, SIGNATURE, false);
    }

    function _checkSignature(
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
            mstore(add(m, 0x04), signer)
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

        assertEq(SignatureCheckerLib.isValidSignatureNow(signer, hash, r, vs), expectedResult);
        assertEq(SignatureCheckerLib.isValidSignatureNow(signer, hash, v, r, s), expectedResult);
    }

    function isValidSignatureNow(address signer, bytes32 hash, bytes calldata signature)
        external
        view
        returns (bool)
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

        return SignatureCheckerLib.isValidSignatureNow(signer, hash, signature);
    }
}
