// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./../../utils/SoladyTest.sol";
import {BLS} from "../../../src/utils/ext/ithaca/BLS.sol";

contract BLSTest is SoladyTest {
    function G1_GENERATOR() internal pure returns (BLS.G1Point memory) {
        return BLS.G1Point(
            _u(31827880280837800241567138048534752271),
            _u(88385725958748408079899006800036250932223001591707578097800747617502997169851),
            _u(11568204302792691131076548377920244452),
            _u(114417265404584670498511149331300188430316142484413708742216858159411894806497)
        );
    }

    function NEGATED_G1_GENERATOR() internal pure returns (BLS.G1Point memory) {
        return BLS.G1Point(
            _u(31827880280837800241567138048534752271),
            _u(88385725958748408079899006800036250932223001591707578097800747617502997169851),
            _u(22997279242622214937712647648895181298),
            _u(46816884707101390882112958134453447585552332943769894357249934112654335001290)
        );
    }

    function _u(uint256 x) internal pure returns (bytes32) {
        return bytes32(x);
    }

    function testSignAndVerify() public {
        // Obtain the private key as a random scalar.
        bytes32 privateKey = bytes32(_randomUniform());

        // Public key is the generator point multiplied by the private key.
        BLS.G1Point memory publicKey = BLS.mul(G1_GENERATOR(), privateKey);

        // Compute the message point by mapping message's keccak256 hash to a point in G2.
        bytes memory message = "hello world";
        BLS.G2Point memory messagePoint = BLS.toG2(BLS.Fp2(0, 0, 0, keccak256(message)));

        // Obtain the signature by multiplying the message point by the private key.
        BLS.G2Point memory signature = BLS.mul(messagePoint, privateKey);

        // Invoke the pairing check to verify the signature.
        BLS.G1Point[] memory g1Points = new BLS.G1Point[](2);
        g1Points[0] = NEGATED_G1_GENERATOR();
        g1Points[1] = publicKey;

        BLS.G2Point[] memory g2Points = new BLS.G2Point[](2);
        g2Points[0] = signature;
        g2Points[1] = messagePoint;

        assertTrue(BLS.pairing(g1Points, g2Points));
    }

    function testSignAndVerifyAggregated() public {
        // private keys
        bytes32 sk1 = bytes32(_randomUniform());
        bytes32 sk2 = bytes32(_randomUniform());

        // public keys
        BLS.G1Point memory pk1 = BLS.mul(G1_GENERATOR(), sk1);
        BLS.G1Point memory pk2 = BLS.mul(G1_GENERATOR(), sk2);

        // Compute the message point by mapping message's keccak256 hash to a point in G2.
        bytes memory message = "hello world";
        BLS.G2Point memory messagePoint = BLS.toG2(BLS.Fp2(0, 0, 0, keccak256(message)));

        // signatures
        BLS.G2Point memory sig1 = BLS.mul(messagePoint, sk1);
        BLS.G2Point memory sig2 = BLS.mul(messagePoint, sk2);

        // aggregated signature
        BLS.G2Point memory sig = BLS.add(sig1, sig2);

        // Invoke the pairing check to verify the signature.
        BLS.G1Point[] memory g1Points = new BLS.G1Point[](3);
        g1Points[0] = NEGATED_G1_GENERATOR();
        g1Points[1] = pk1;
        g1Points[2] = pk2;

        BLS.G2Point[] memory g2Points = new BLS.G2Point[](3);
        g2Points[0] = sig;
        g2Points[1] = messagePoint;
        g2Points[2] = messagePoint;

        assertTrue(BLS.pairing(g1Points, g2Points));
    }

    function testHashToCurveG2() public {
        testHashToCurveG2("hehe");
    }

    function testHashToCurveG2(bytes memory message) public {
        bytes memory expected = abi.encode(this.hashToCurveG2Original(message));
        bytes memory computed = abi.encode(this.hashToCurveG2OptimizedBrutalized(message));
        assertEq(computed, expected);
    }

    function hashToCurveG2Optimized(bytes memory message)
        public
        view
        returns (BLS.G2Point memory result)
    {
        result = BLS.hashToG2(message);
    }

    function hashToCurveG2OptimizedBrutalized(bytes memory message)
        public
        view
        returns (BLS.G2Point memory result)
    {
        _misalignFreeMemoryPointer();
        _brutalizeMemory();
        result = BLS.hashToG2(message);
        _checkMemory();
    }

    /// @notice Computes a point in G2 from a message
    /// @dev Uses the eip-2537 precompiles
    /// @param message Arbitrarylength byte string to be hashed
    /// @return A point in G2
    function hashToCurveG2Original(bytes memory message) public view returns (BLS.G2Point memory) {
        // 1. u = hash_to_field(msg, 2)
        BLS.Fp2[2] memory u =
            _hashToFieldFp2(message, bytes("BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_"));
        // 2. Q0 = map_to_curve(u[0])
        BLS.G2Point memory q0 = BLS.toG2(u[0]);
        // 3. Q1 = map_to_curve(u[1])
        BLS.G2Point memory q1 = BLS.toG2(u[1]);
        // 4. R = Q0 + Q1
        return BLS.add(q0, q1);
    }

    /// @notice Computes a field point from a message
    /// @dev Follows https://datatracker.ietf.org/doc/html/rfc9380#section-5.2
    /// @param message Arbitrarylength byte string to be hashed
    /// @param dst The domain separation tag
    /// @return Two field points
    function _hashToFieldFp2(bytes memory message, bytes memory dst)
        private
        view
        returns (BLS.Fp2[2] memory)
    {
        // 1. len_in_bytes = count * m * L
        // so always 2 * 2 * 64 = 256
        uint16 lenInBytes = 256;
        // 2. uniform_bytes = expand_message(msg, DST, len_in_bytes)
        bytes32[] memory pseudoRandomBytes = _expandMsgXmd(message, dst, lenInBytes);
        BLS.Fp2[2] memory u;
        // No loop here saves 800 gas hardcoding offset an additional 300
        // 3. for i in (0, ..., count - 1):
        // 4.   for j in (0, ..., m - 1):
        // 5.     elm_offset = L * (j + i * m)
        // 6.     tv = substr(uniform_bytes, elm_offset, HTF_L)
        // uint8 HTF_L = 64;
        // bytes memory tv = new bytes(64);
        // 7.     e_j = OS2IP(tv) mod p
        // 8.   u_i = (e_0, ..., e_(m - 1))
        // tv = bytes.concat(pseudo_random_bytes[0], pseudo_random_bytes[1]);
        BLS.Fp memory t;
        t = _modfield(pseudoRandomBytes[0], pseudoRandomBytes[1]);
        u[0].c0_a = t.a;
        u[0].c0_b = t.b;
        t = _modfield(pseudoRandomBytes[2], pseudoRandomBytes[3]);
        u[0].c1_a = t.a;
        u[0].c1_b = t.b;
        t = _modfield(pseudoRandomBytes[4], pseudoRandomBytes[5]);
        u[1].c0_a = t.a;
        u[1].c0_b = t.b;
        t = _modfield(pseudoRandomBytes[6], pseudoRandomBytes[7]);
        u[1].c1_a = t.a;
        u[1].c1_b = t.b;
        // 9. return (u_0, ..., u_(count - 1))
        return u;
    }

    /// @notice Computes a field point from a message
    /// @dev Follows https://datatracker.ietf.org/doc/html/rfc9380#section-5.3
    /// @dev bytes32[] because len_in_bytes is always a multiple of 32 in our case even 128
    /// @param message Arbitrarylength byte string to be hashed
    /// @param dst The domain separation tag of at most 255 bytes
    /// @param lenInBytes The length of the requested output in bytes
    /// @return A field point
    function _expandMsgXmd(bytes memory message, bytes memory dst, uint16 lenInBytes)
        private
        pure
        returns (bytes32[] memory)
    {
        // 1.  ell = ceil(len_in_bytes / b_in_bytes)
        // b_in_bytes seems to be 32 for sha256
        // ceil the division
        uint256 ell = (lenInBytes - 1) / 32 + 1;

        // 2.  ABORT if ell > 255 or len_in_bytes > 65535 or len(DST) > 255
        require(ell <= 255, "len_in_bytes too large for sha256");
        // Not really needed because of parameter type
        // require(lenInBytes <= 65535, "len_in_bytes too large");
        // no length normalizing via hashing
        require(dst.length <= 255, "dst too long");

        bytes memory dstPrime = bytes.concat(dst, bytes1(uint8(dst.length)));

        // 4.  Z_pad = I2OSP(0, s_in_bytes)
        // this should be sha256 blocksize so 64 bytes
        bytes memory zPad = new bytes(64);

        // 5.  l_i_b_str = I2OSP(len_in_bytes, 2)
        // length in byte string?
        bytes2 libStr = bytes2(lenInBytes);

        // 6.  msg_prime = Z_pad || msg || l_i_b_str || I2OSP(0, 1) || DST_prime
        bytes memory msgPrime = bytes.concat(zPad, message, libStr, hex"00", dstPrime);

        // 7.  b_0 = H(msg_prime)
        bytes32 b_0 = sha256(msgPrime);

        bytes32[] memory b = new bytes32[](ell);

        // 8.  b_1 = H(b_0 || I2OSP(1, 1) || DST_prime)
        b[0] = sha256(bytes.concat(b_0, hex"01", dstPrime));

        // 9.  for i in (2, ..., ell):
        for (uint8 i = 2; i <= ell; i++) {
            // 10.    b_i = H(strxor(b_0, b_(i - 1)) || I2OSP(i, 1) || DST_prime)
            bytes memory tmp = abi.encodePacked(b_0 ^ b[i - 2], i, dstPrime);
            b[i - 1] = sha256(tmp);
        }
        // 11. uniform_bytes = b_1 || ... || b_ell
        // 12. return substr(uniform_bytes, 0, len_in_bytes)
        // Here we don't need the uniform_bytes because b is already properly formed
        return b;
    }

    // passing two bytes32 instead of bytes memory saves approx 700 gas per call
    // Computes the mod against the bls12-381 field modulus
    function _modfield(bytes32 _b1, bytes32 _b2) private view returns (BLS.Fp memory r) {
        (bool success, bytes memory output) = address(0x5).staticcall(
            abi.encode(
                // arg[0] = base.length
                0x40,
                // arg[1] = exp.length
                0x20,
                // arg[2] = mod.length
                0x40,
                // arg[3] = base.bits
                // places the first 32 bytes of _b1 and the last 32 bytes of _b2
                _b1,
                _b2,
                // arg[4] = exp
                // exponent always 1
                1,
                // arg[5] = mod
                // this field_modulus as hex 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559787
                // we add the 0 prefix so that the result will be exactly 64 bytes
                // saves 300 gas per call instead of sending it along every time
                // places the first 32 bytes and the last 32 bytes of the field modulus
                0x000000000000000000000000000000001a0111ea397fe69a4b1ba7b6434bacd7,
                0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
            )
        );
        require(success, "MODEXP failed");
        return abi.decode(output, (BLS.Fp));
    }
}
