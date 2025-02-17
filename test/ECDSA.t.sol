// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {ECDSA} from "../src/utils/ECDSA.sol";
import {LibString} from "../src/utils/LibString.sol";

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

    function testTryRecoverWithV0SignatureWithShortEIP2098FormatAsCalldata() public {
        bytes memory signature =
            hex"5d99b6f7f6d1f73d1a26497f2b1c89b24c0993913f86e9a2d02cd69887d9c94f3c880358579d811b21dd1b7fd9bb01c1d81d10e69f0384e675c32b39643be892";
        assertTrue(this.tryRecover(TEST_MESSAGE, signature) == V0_SIGNER);
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

    function testTryRecoverWithV1SignatureWithShortEIP2098FormatAsCalldata() public {
        bytes memory signature =
            hex"331fe75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feffc8e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e0";
        assertTrue(this.tryRecover(TEST_MESSAGE, signature) == V1_SIGNER);
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

    function testRecoverWithV0SignatureWithShortEIP2098FormatAsCalldata() public {
        bytes memory signature =
            hex"5d99b6f7f6d1f73d1a26497f2b1c89b24c0993913f86e9a2d02cd69887d9c94f3c880358579d811b21dd1b7fd9bb01c1d81d10e69f0384e675c32b39643be892";
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

    function testRecoverWithV1SignatureWithShortEIP2098FormatAsCalldata() public {
        bytes memory signature =
            hex"331fe75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feffc8e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e0";
        this.recover(TEST_MESSAGE, signature);
    }

    struct _CheckSignatureTestTemps {
        bytes argsSignature;
        bytes encodedCalldataArgs;
        address signer;
        bool expected;
        bool[2] success;
        bytes[2] result;
        bytes4 s;
        address recovered;
    }

    function _checkSignature(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool expected
    ) internal {
        _CheckSignatureTestTemps memory t;
        t.signer = signer;
        t.expected = expected;

        t.argsSignature = "(bytes32,uint8,bytes32,bytes32)";
        t.encodedCalldataArgs = abi.encode(digest, v, r, s);
        _checkSignature(t);

        if (v == 27 || v == 28) {
            bytes32 vs = bytes32((v == 28 ? 1 << 255 : 0) | uint256(s));
            t.argsSignature = "(bytes32,bytes32,bytes32)";
            t.encodedCalldataArgs = abi.encode(digest, r, vs);
            _checkSignature(t);
        }

        if (_random() & 1 == 0) {
            t.argsSignature = "(bytes32,bytes)";
            t.encodedCalldataArgs = abi.encode(digest, abi.encodePacked(r, s, v));
            _checkSignature(t);
        }
    }

    function _checkSignature(_CheckSignatureTestTemps memory t) internal {
        t.s = bytes4(keccak256(abi.encodePacked("tryRecover", t.argsSignature)));
        (t.success[0], t.result[0]) =
            address(this).call(abi.encodePacked(t.s, t.encodedCalldataArgs));
        t.recovered = t.success[0] ? abi.decode(t.result[0], (address)) : address(0);
        assertEq(t.recovered == t.signer, t.expected);

        t.s = bytes4(keccak256(abi.encodePacked("tryRecoverBrutalized", t.argsSignature)));
        (t.success[1], t.result[1]) =
            address(this).call(abi.encodePacked(t.s, t.encodedCalldataArgs));
        t.recovered = t.success[1] ? abi.decode(t.result[1], (address)) : address(0);
        assertEq(t.recovered == t.signer, t.expected);

        t.s = bytes4(keccak256(abi.encodePacked("recover", t.argsSignature)));
        (t.success[0], t.result[0]) =
            address(this).call(abi.encodePacked(t.s, t.encodedCalldataArgs));

        t.s = bytes4(keccak256(abi.encodePacked("recoverBrutalized", t.argsSignature)));
        (t.success[1], t.result[1]) =
            address(this).call(abi.encodePacked(t.s, t.encodedCalldataArgs));

        assertEq(t.success[0], t.success[1]);
        assertEq(t.result[0], t.result[1]);

        if (t.success[0]) {
            t.recovered = abi.decode(t.result[0], (address));
            assertEq(t.recovered == t.signer, t.expected);
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
        assertEq(
            TEST_MESSAGE.toEthSignedMessageHash(),
            bytes32(0x7d768af957ef8cbf6219a37e743d5546d911dae3e46449d8a5810522db2ef65e)
        );
    }

    function testBytesToEthSignedMessageHashShort() public {
        bytes memory message = hex"61626364";
        assertEq(
            message.toEthSignedMessageHash(),
            bytes32(0xefd0b51a9c4e5f3449f4eeacb195bf48659fbc00d2f4001bf4c088ba0779fb33)
        );
    }

    function testBytesToEthSignedMessageHashEmpty() public {
        bytes memory message = hex"";
        assertEq(
            message.toEthSignedMessageHash(),
            bytes32(0x5f35dce98ba4fba25530a026ed80b2cecdaa31091ba4958b99b52ea1d068adad)
        );
    }

    function testBytesToEthSignedMessageHashLong() public {
        bytes memory message =
            hex"4142434445464748494a4b4c4d4e4f505152535455565758595a6162636465666768696a6b6c6d6e6f707172737475767778797a3031323334353637383921402324255e262a28292d3d5b5d7b7d";
        assertEq(
            message.toEthSignedMessageHash(),
            bytes32(0xa46dbedd405cff161b6e80c17c8567597621d9f4c087204201097cb34448e71b)
        );
    }

    function testBytesToEthSignedMessageHash() public {
        _testBytesToEthSignedMessageHash(999999);
        _testBytesToEthSignedMessageHash(135790);
        _testBytesToEthSignedMessageHash(99999);
        _testBytesToEthSignedMessageHash(88888);
        _testBytesToEthSignedMessageHash(3210);
        _testBytesToEthSignedMessageHash(111);
        _testBytesToEthSignedMessageHash(22);
        _testBytesToEthSignedMessageHash(1);
        _testBytesToEthSignedMessageHash(0);
    }

    function testBytesToEthSignedMessageHashExceedsMaxLengthReverts() public {
        vm.expectRevert();
        this._testBytesToEthSignedMessageHash(999999 + 1);
    }

    function _testBytesToEthSignedMessageHash(uint256 n) public brutalizeMemory {
        bytes memory message;
        /// @solidity memory-safe-assembly
        assembly {
            message := mload(0x40)
            mstore(message, n)
            mstore(0x40, add(add(message, 0x20), n))
        }
        assertEq(
            message.toEthSignedMessageHash(),
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n", LibString.toString(n), message)
            )
        );
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, message)
        }
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

    function tryRecoverBrutalized(bytes32 hash, bytes calldata signature)
        external
        brutalizeMemory
        returns (address result)
    {
        result = ECDSA.tryRecoverCalldata(hash, signature);
        assertEq(ECDSA.tryRecover(hash, signature), result);
    }

    function tryRecoverBrutalized(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        external
        view
        brutalizeMemory
        returns (address)
    {
        return ECDSA.tryRecover(hash, v, r, s);
    }

    function tryRecoverBrutalized(bytes32 hash, bytes32 r, bytes32 vs)
        external
        view
        brutalizeMemory
        returns (address)
    {
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

    function recoverBrutalized(bytes32 hash, bytes calldata signature)
        external
        brutalizeMemory
        returns (address result)
    {
        result = ECDSA.recoverCalldata(hash, signature);
        assertEq(ECDSA.recover(hash, signature), result);
    }

    function recoverBrutalized(bytes32 hash, bytes32 r, bytes32 vs)
        external
        view
        brutalizeMemory
        returns (address)
    {
        return ECDSA.recover(hash, r, vs);
    }

    function recoverBrutalized(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        external
        view
        brutalizeMemory
        returns (address)
    {
        return ECDSA.recover(hash, v, r, s);
    }

    function testCanonicalHashWithRegularSignature() public brutalizeMemory {
        bytes memory signature =
            hex"8688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe2652815db01c2c84b0ec746e1b74d97475c599b3d3419fa7181b4e01de62c02b721aea1b";
        assertEq(ECDSA.canonicalHash(signature), keccak256(signature));
        bytes memory signature_malleable =
            hex"8688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe265281a24fe3d37b4f138b91e48b268b8a3a6506db9b47083084edbdf3fbcca4c426571c";
        assertEq(ECDSA.canonicalHash(signature_malleable), keccak256(signature));
    }

    function testCanonicalHashWith64bytesSignature() public brutalizeMemory {
        bytes memory signature =
            hex"8688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe2652815db01c2c84b0ec746e1b74d97475c599b3d3419fa7181b4e01de62c02b721aea1b";
        bytes memory shortSignature =
            hex"8688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe2652815db01c2c84b0ec746e1b74d97475c599b3d3419fa7181b4e01de62c02b721aea";

        assertEq(ECDSA.canonicalHash(shortSignature), keccak256(signature));
    }

    function testCanonicalHashCalldataWithRegularSignature() public {
        bytes memory signature =
            hex"8688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe2652815db01c2c84b0ec746e1b74d97475c599b3d3419fa7181b4e01de62c02b721aea1b";
        assertEq(this.canonicalHashCalldata(signature), keccak256(signature));
        assertEq(this.canonicalHashCalldataBrutalizeMemory(signature), keccak256(signature));

        bytes memory signature_malleable =
            hex"8688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe265281a24fe3d37b4f138b91e48b268b8a3a6506db9b47083084edbdf3fbcca4c426571c";

        assertEq(this.canonicalHashCalldata(signature_malleable), keccak256(signature));
        assertEq(
            this.canonicalHashCalldataBrutalizeMemory(signature_malleable), keccak256(signature)
        );
    }

    function testCanonicalHashCalldataWith64bytesSignature() public {
        bytes memory signature =
            hex"8688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe2652815db01c2c84b0ec746e1b74d97475c599b3d3419fa7181b4e01de62c02b721aea1b";
        bytes memory shortSignature =
            hex"8688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe2652815db01c2c84b0ec746e1b74d97475c599b3d3419fa7181b4e01de62c02b721aea";

        assertEq(this.canonicalHashCalldata(shortSignature), keccak256(signature));
        assertEq(this.canonicalHashCalldataBrutalizeMemory(shortSignature), keccak256(signature));
        signature =
            hex"8688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe2652815db01c2c84b0ec746e1b74d97475c599b3d3419fa7181b4e01de62c02b721aea1c";
        shortSignature =
            hex"8688e590483917863a35ef230c0f839be8418aa4ee765228eddfcea7fe265281ddb01c2c84b0ec746e1b74d97475c599b3d3419fa7181b4e01de62c02b721aea";

        assertEq(this.canonicalHashCalldata(shortSignature), keccak256(signature));
        assertEq(this.canonicalHashCalldataBrutalizeMemory(shortSignature), keccak256(signature));
    }

    function testCanonicalHash(bytes32 digest) public {
        bytes memory signature;
        bytes32 cHash;
        address signer;
        {
            uint256 privateKey;
            (signer, privateKey) = _randomSigner();
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
            v = _brutalizedUint8(v);
            signature = abi.encodePacked(r, s, v);
            cHash = ECDSA.canonicalHash(signature);
            assertEq(keccak256(signature), cHash);
            assertEq(ECDSA.canonicalHash(r, _vs(v, s)), cHash);

            if (_randomChance(2)) {
                s = bytes32(uint256(ECDSA.N) - uint256(s));
                v = v ^ 7;
            }

            if (_randomChance(8)) {
                assertEq(ECDSA.canonicalHash(v, r, s), cHash);
                assertEq(ECDSA.canonicalHash(abi.encodePacked(r, s, v)), cHash);
                assertEq(ECDSA.canonicalHash(_shortSignature(abi.encodePacked(r, s, v))), cHash);
                _checkMemory();
            }

            if (_randomChance(2)) {
                bytes memory shortSignature = _shortSignature(signature);
                assertEq(ECDSA.canonicalHash(shortSignature), cHash);
                if (_randomChance(8)) {
                    assertEq(this.canonicalHashCalldataBrutalizeMemory(shortSignature), cHash);
                }
            }

            if (_randomChance(4)) {
                uint8 corruptedV = _brutalizedUint8(uint8(_random()));
                assertEq(
                    ECDSA.canonicalHash(abi.encodePacked(r, s, corruptedV)),
                    ECDSA.canonicalHash(corruptedV, r, s)
                );
                if (corruptedV == 27 || corruptedV == 28) {
                    assertEq(
                        ECDSA.canonicalHash(abi.encodePacked(r, s, corruptedV)),
                        ECDSA.canonicalHash(r, _vs(corruptedV, s))
                    );
                }
                _checkMemory();
            }
        }

        bytes memory corruptedSignature = _corruptedSignature(signature);
        bytes32 corruptedCHash = ECDSA.canonicalHash(corruptedSignature);
        if (_randomChance(8)) {
            assertEq(this.canonicalHashCalldata(corruptedSignature), corruptedCHash);
            if (_randomChance(2)) {
                assertEq(
                    this.canonicalHashCalldataBrutalizeMemory(corruptedSignature), corruptedCHash
                );
            }
        }

        if (ECDSA.tryRecover(digest, corruptedSignature) == signer) {
            assertEq(corruptedCHash, cHash);
        } else {
            assertNotEq(corruptedCHash, cHash);
            if (_randomChance(2)) {
                bytes memory corruptedSignature2 = _corruptedSignature(signature);
                if (ECDSA.tryRecover(digest, corruptedSignature2) != signer) {
                    if (keccak256(corruptedSignature) != keccak256(corruptedSignature2)) {
                        assertNotEq(corruptedCHash, ECDSA.canonicalHash(corruptedSignature2));
                    }
                }
            }
        }
    }

    function _shortSignature(bytes memory signature) internal pure returns (bytes memory) {
        require(signature.length == 65, "Wrong length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        /// @solidity memory-safe-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := and(0xff, mload(add(signature, 0x41)))
        }
        return abi.encodePacked(r, _vs(v, s));
    }

    function _vs(uint8 v, bytes32 s) internal pure returns (bytes32 vs) {
        uint256 n = uint256(ECDSA.N);
        /// @solidity memory-safe-assembly
        assembly {
            v := and(0xff, v)
            if lt(shr(1, n), s) {
                v := xor(v, 7)
                s := sub(n, s)
            }
            vs := or(s, shl(255, eq(v, 28)))
        }
    }

    function _corruptedSignature(bytes memory signature) internal returns (bytes memory result) {
        if (_randomChance(2)) {
            result = abi.encodePacked(signature, uint8(_random()), _random());
        } else {
            result = abi.encodePacked(_shortSignature(signature), uint8(_random()), _random());
        }
        unchecked {
            uint256 corruptedLength = _random() % (result.length + 1);
            /// @solidity memory-safe-assembly
            assembly {
                mstore(result, corruptedLength)
            }
            if (corruptedLength == 0 && _randomChance(2)) {
                /// @solidity memory-safe-assembly
                assembly {
                    result := 0x60
                }
            }
        }
    }

    function canonicalHashCalldata(bytes calldata signature) external pure returns (bytes32) {
        return ECDSA.canonicalHashCalldata(signature);
    }

    function canonicalHashCalldataBrutalizeMemory(bytes calldata signature)
        external
        view
        brutalizeMemory
        returns (bytes32)
    {
        return ECDSA.canonicalHashCalldata(signature);
    }

    function testEmptyCalldataHelpers() public {
        assertFalse(ECDSA.tryRecover(bytes32(0), ECDSA.emptySignature()) == address(1));
    }

    function testMalleabilityTrick(uint256 s) public {
        unchecked {
            uint256 n = uint256(ECDSA.N);
            uint256 halfN = n >> 1;
            uint256 halfNPlus1 = halfN + 1;

            uint256 expected = s;
            if (expected > halfN) {
                expected = n - expected;
            }

            uint256 computed = s;
            if (!(computed < halfNPlus1)) {
                computed = (halfNPlus1 + halfNPlus1) - (computed + 1);
            }
            assertEq(computed, expected);
        }
    }

    function testMalleabilityTrick() public {
        unchecked {
            uint256 s = (uint256(ECDSA.N) >> 1) - 5;
            for (uint256 i; i < 10; ++i) {
                testMalleabilityTrick(s + i);
            }
        }
    }
}
