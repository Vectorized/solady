// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {ECDSA} from "../src/utils/ECDSA.sol";

contract ECDSATest is SoladyTest {
    using ECDSA for bytes32;
    using ECDSA for bytes;

    bytes32 constant TEST_MESSAGE =
        0x7dbaf558b0a1a5dc7a67202117ab143c1d8605a983e4a743bc06fcc03162dc0d;

    bytes32 constant WRONG_MESSAGE =
        0x2d0828dd7c97cff316356da3c16c68ba2316886a0e05ebafb8291939310d51a3;

    address constant SIGNER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    address constant V0_SIGNER = 0x2cc1166f6212628A0deEf2B33BEFB2187D35b86c;

    address constant V1_SIGNER = 0x1E318623aB09Fe6de3C9b8672098464Aeda9100E;

    function testTryRecoverWithInvalidShortSignatureReturnsZero() public {
        bytes memory signature = hex"1234";
        assertTrue(this.tryRecover(TEST_MESSAGE, signature) == address(0));
    }

    function testTryRecoverWithInvalidLongSignatureReturnsZero() public {
        bytes memory signature =
            hex"01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789";
        assertTrue(this.tryRecover(TEST_MESSAGE, signature) == address(0));
    }

    function testTryRecoverWithValidSignature() public {
        bytes memory signature =
            hex"8688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe2652815db01c2c84b0ec746e1b74d97475c599b3d3419fa7181b4e01de62c02b721aea1b";
        assertTrue(this.tryRecover(TEST_MESSAGE.toEthSignedMessageHash(), signature) == SIGNER);
    }

    function testTryRecoverWithWrongSigner() public {
        bytes memory signature =
            hex"8688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe2652815db01c2c84b0ec746e1b74d97475c599b3d3419fa7181b4e01de62c02b721aea1b";
        assertTrue(this.tryRecover(WRONG_MESSAGE.toEthSignedMessageHash(), signature) != SIGNER);
    }

    function testTryRecoverWithInvalidSignature() public {
        bytes memory signature =
            hex"332ce75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feff48e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e01c";
        assertTrue(this.tryRecover(TEST_MESSAGE.toEthSignedMessageHash(), signature) != SIGNER);
    }

    function testTryRecoverWithV0SignatureWithVersion00ReturnsZero() public {
        bytes memory signature =
            hex"5d99b6f7f6d1f73d1a26497f2b1c89b24c0993913f86e9a2d02cd69887d9c94f3c880358579d811b21dd1b7fd9bb01c1d81d10e69f0384e675c32b39643be89200";
        assertTrue(this.tryRecover(TEST_MESSAGE, signature) == address(0));
    }

    function testTryRecoverWithV0SignatureWithVersion27() public {
        bytes memory signature =
            hex"5d99b6f7f6d1f73d1a26497f2b1c89b24c0993913f86e9a2d02cd69887d9c94f3c880358579d811b21dd1b7fd9bb01c1d81d10e69f0384e675c32b39643be8921b";
        assertTrue(this.tryRecover(TEST_MESSAGE, signature) == V0_SIGNER);
    }

    function testTryRecoverWithV0SignatureWithWrongVersionReturnsZero() public {
        bytes memory signature =
            hex"5d99b6f7f6d1f73d1a26497f2b1c89b24c0993913f86e9a2d02cd69887d9c94f3c880358579d811b21dd1b7fd9bb01c1d81d10e69f0384e675c32b39643be89202";
        assertTrue(this.tryRecover(TEST_MESSAGE, signature) == address(0));
    }

    function testTryRecoverWithV0SignatureWithShortEIP2098Format() public {
        bytes32 r = 0x5d99b6f7f6d1f73d1a26497f2b1c89b24c0993913f86e9a2d02cd69887d9c94f;
        bytes32 vs = 0x3c880358579d811b21dd1b7fd9bb01c1d81d10e69f0384e675c32b39643be892;
        assertTrue(this.tryRecover(TEST_MESSAGE, r, vs) == V0_SIGNER);
    }

    function testTryRecoverWithV0SignatureWithShortEIP2098FormatAsCalldataReturnsZero() public {
        bytes memory signature =
            hex"5d99b6f7f6d1f73d1a26497f2b1c89b24c0993913f86e9a2d02cd69887d9c94f3c880358579d811b21dd1b7fd9bb01c1d81d10e69f0384e675c32b39643be892";
        assertTrue(this.tryRecover(TEST_MESSAGE, signature) == address(0));
    }

    function testTryRecoverWithV1SignatureWithVersion01ReturnsZero() public {
        bytes memory signature =
            hex"331fe75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feff48e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e001";
        assertTrue(this.tryRecover(TEST_MESSAGE, signature) == address(0));
    }

    function testTryRecoverWithV1SignatureWithVersion28() public {
        bytes memory signature =
            hex"331fe75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feff48e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e01c";
        assertTrue(this.tryRecover(TEST_MESSAGE, signature) == V1_SIGNER);
    }

    function testTryRecoverWithV1SignatureWithWrongVersionReturnsZero() public {
        bytes memory signature =
            hex"331fe75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feff48e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e002";
        assertTrue(this.tryRecover(TEST_MESSAGE, signature) == address(0));
    }

    function testTryRecoverWithV1SignatureWithShortEIP2098Format() public {
        bytes32 r = 0x331fe75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feff;
        bytes32 vs = 0xc8e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e0;
        assertTrue(this.tryRecover(TEST_MESSAGE, r, vs) == V1_SIGNER);
    }

    function testTryRecoverWithV1SignatureWithShortEIP2098FormatAsCalldataReturnsZero() public {
        bytes memory signature =
            hex"331fe75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feffc8e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e0";
        assertTrue(this.tryRecover(TEST_MESSAGE, signature) == address(0));
    }

    function testRecoverWithInvalidShortSignatureReturnsZero() public {
        bytes memory signature = hex"1234";
        vm.expectRevert(ECDSA.InvalidSignature.selector);
        this.recover(TEST_MESSAGE, signature);
    }

    function testRecoverWithInvalidLongSignatureReverts() public {
        bytes memory signature =
            hex"01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789";
        vm.expectRevert(ECDSA.InvalidSignature.selector);
        this.recover(TEST_MESSAGE, signature);
    }

    function testRecoverWithValidSignature() public {
        bytes memory signature =
            hex"8688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe2652815db01c2c84b0ec746e1b74d97475c599b3d3419fa7181b4e01de62c02b721aea1b";
        address recovered = this.recover(TEST_MESSAGE.toEthSignedMessageHash(), signature);
        assertTrue(recovered == SIGNER);
    }

    function testRecoverWithWrongSigner() public {
        bytes memory signature =
            hex"8688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe2652815db01c2c84b0ec746e1b74d97475c599b3d3419fa7181b4e01de62c02b721aea1b";
        assertTrue(this.recover(WRONG_MESSAGE.toEthSignedMessageHash(), signature) != SIGNER);
    }

    function testRecoverWithInvalidSignatureReverts() public {
        bytes memory signature =
            hex"332ce75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feff48e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e01c";
        vm.expectRevert(ECDSA.InvalidSignature.selector);
        this.recover(TEST_MESSAGE.toEthSignedMessageHash(), signature);
    }

    function testRecoverWithV0SignatureWithVersion00Reverts() public {
        bytes memory signature =
            hex"5d99b6f7f6d1f73d1a26497f2b1c89b24c0993913f86e9a2d02cd69887d9c94f3c880358579d811b21dd1b7fd9bb01c1d81d10e69f0384e675c32b39643be89200";
        vm.expectRevert(ECDSA.InvalidSignature.selector);
        this.recover(TEST_MESSAGE, signature);
    }

    function testRecoverWithV0SignatureWithVersion27() public {
        bytes memory signature =
            hex"5d99b6f7f6d1f73d1a26497f2b1c89b24c0993913f86e9a2d02cd69887d9c94f3c880358579d811b21dd1b7fd9bb01c1d81d10e69f0384e675c32b39643be8921b";
        assertTrue(this.recover(TEST_MESSAGE, signature) == V0_SIGNER);
    }

    function testRecoverWithV0SignatureWithWrongVersionReverts() public {
        bytes memory signature =
            hex"5d99b6f7f6d1f73d1a26497f2b1c89b24c0993913f86e9a2d02cd69887d9c94f3c880358579d811b21dd1b7fd9bb01c1d81d10e69f0384e675c32b39643be89202";
        vm.expectRevert(ECDSA.InvalidSignature.selector);
        this.recover(TEST_MESSAGE, signature);
    }

    function testRecoverWithV0SignatureWithShortEIP2098Format() public {
        bytes32 r = 0x5d99b6f7f6d1f73d1a26497f2b1c89b24c0993913f86e9a2d02cd69887d9c94f;
        bytes32 vs = 0x3c880358579d811b21dd1b7fd9bb01c1d81d10e69f0384e675c32b39643be892;
        assertTrue(this.recover(TEST_MESSAGE, r, vs) == V0_SIGNER);
    }

    function testRecoverWithV0SignatureWithShortEIP2098FormatAsCalldataReverts() public {
        bytes memory signature =
            hex"5d99b6f7f6d1f73d1a26497f2b1c89b24c0993913f86e9a2d02cd69887d9c94f3c880358579d811b21dd1b7fd9bb01c1d81d10e69f0384e675c32b39643be892";
        vm.expectRevert(ECDSA.InvalidSignature.selector);
        this.recover(TEST_MESSAGE, signature);
    }

    function testRecoverWithV1SignatureWithVersion01Reverts() public {
        bytes memory signature =
            hex"331fe75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feff48e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e001";
        vm.expectRevert(ECDSA.InvalidSignature.selector);
        this.recover(TEST_MESSAGE, signature);
    }

    function testRecoverWithV1SignatureWithVersion28() public {
        bytes memory signature =
            hex"331fe75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feff48e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e01c";
        assertTrue(this.recover(TEST_MESSAGE, signature) == V1_SIGNER);
    }

    function testRecoverWithV1SignatureWithWrongVersionReverts() public {
        bytes memory signature =
            hex"331fe75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feff48e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e002";
        vm.expectRevert(ECDSA.InvalidSignature.selector);
        this.recover(TEST_MESSAGE, signature);
    }

    function testRecoverWithV1SignatureWithShortEIP2098Format() public {
        bytes32 r = 0x331fe75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feff;
        bytes32 vs = 0xc8e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e0;
        assertTrue(this.recover(TEST_MESSAGE, r, vs) == V1_SIGNER);
    }

    function testRecoverWithV1SignatureWithShortEIP2098FormatAsCalldataReverts() public {
        bytes memory signature =
            hex"331fe75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feffc8e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e0";
        vm.expectRevert(ECDSA.InvalidSignature.selector);
        this.recover(TEST_MESSAGE, signature);
    }

    function _checkSignature(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool expectedResult
    ) internal {
        assertEq(this.tryRecover(digest, v, r, s) == signer, expectedResult);

        try this.recover(digest, v, r, s) returns (address recovered) {
            assertEq(recovered == signer, expectedResult);
        } catch {}

        if (v == 27 || v == 28) {
            bytes32 vs = bytes32((v == 28 ? 1 << 255 : 0) | uint256(s));

            assertEq(this.tryRecover(digest, r, vs) == signer, expectedResult);

            try this.recover(digest, r, vs) returns (address recovered) {
                assertEq(recovered == signer, expectedResult);
            } catch {}
        }

        if (_random() & 1 == 0) {
            bytes memory signature = abi.encodePacked(r, s, v);

            assertEq(this.tryRecover(digest, signature) == signer, expectedResult);

            try this.recover(digest, signature) returns (address recovered) {
                assertEq(recovered == signer, expectedResult);
            } catch {}
        }
    }

    function testRecoverAndTryRecover(bytes32 digest) public {
        (address signer, uint256 privateKey) = _randomSigner();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        if (_random() & 7 == 0) {
            _checkSignature(signer, digest, v, r, s, true);
        }

        uint8 vc = v ^ uint8(_random() & 0xff);
        bytes32 rc = bytes32(uint256(r) ^ _random());
        bytes32 sc = bytes32(uint256(s) ^ _random());
        bool anyCorrupted = vc != v || rc != r || sc != s;
        _checkSignature(signer, digest, vc, rc, sc, !anyCorrupted);
    }

    function testBytes32ToEthSignedMessageHash() public {
        assertTrue(
            TEST_MESSAGE.toEthSignedMessageHash()
                == bytes32(0x7d768af957ef8cbf6219a37e743d5546d911dae3e46449d8a5810522db2ef65e)
        );
    }

    function testBytesToEthSignedMessageHashShort() public {
        bytes memory message = hex"61626364";
        assertTrue(
            message.toEthSignedMessageHash()
                == bytes32(0xefd0b51a9c4e5f3449f4eeacb195bf48659fbc00d2f4001bf4c088ba0779fb33)
        );
    }

    function testBytesToEthSignedMessageHashEmpty() public {
        bytes memory message = hex"";
        assertTrue(
            message.toEthSignedMessageHash()
                == bytes32(0x5f35dce98ba4fba25530a026ed80b2cecdaa31091ba4958b99b52ea1d068adad)
        );
    }

    function testBytesToEthSignedMessageHashEmptyLong() public {
        bytes memory message =
            hex"4142434445464748494a4b4c4d4e4f505152535455565758595a6162636465666768696a6b6c6d6e6f707172737475767778797a3031323334353637383921402324255e262a28292d3d5b5d7b7d";
        assertTrue(
            message.toEthSignedMessageHash()
                == bytes32(0xa46dbedd405cff161b6e80c17c8567597621d9f4c087204201097cb34448e71b)
        );
    }

    function tryRecover(bytes32 hash, bytes calldata signature) external returns (address result) {
        result = ECDSA.tryRecoverCalldata(hash, signature);
        assertEq(ECDSA.tryRecover(hash, signature), result);
    }

    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        external
        view
        returns (address)
    {
        return ECDSA.tryRecover(hash, v, r, s);
    }

    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) external view returns (address) {
        return ECDSA.tryRecover(hash, r, vs);
    }

    function recover(bytes32 hash, bytes calldata signature) external returns (address result) {
        result = ECDSA.recoverCalldata(hash, signature);
        assertEq(ECDSA.recover(hash, signature), result);
    }

    function recover(bytes32 hash, bytes32 r, bytes32 vs) external view returns (address) {
        return ECDSA.recover(hash, r, vs);
    }

    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) external view returns (address) {
        return ECDSA.recover(hash, v, r, s);
    }

    function testEmptyCalldataHelpers() public {
        assertFalse(ECDSA.tryRecover(bytes32(0), ECDSA.emptySignature()) == address(1));
    }
}
