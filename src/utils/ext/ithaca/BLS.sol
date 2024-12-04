// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice BLS wrapper.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/BLS.sol)
/// @author Ithaca (https://github.com/ithacaxyz/odyssey-examples/blob/main/chapter1/contracts/src/libraries/BLS.sol)
///
/// @dev Precompile addresses come from the BLS addresses submodule in AlphaNet, see
/// See: (https://github.com/paradigmxyz/alphanet/blob/main/crates/precompile/src/addresses.rs)
library BLS {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // We use flattened structs to make encoding more efficient.
    // All structs use Big endian encoding.
    // See: https://eips.ethereum.org/EIPS/eip-2537

    /// @dev A representation of a base field element (Fp) in the BLS12-381 curve.
    /// Due to the size of `p`,
    /// `0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab`
    /// the top 16 bytes are always zeroes.
    struct Fp {
        bytes32 a; // Upper 32 bytes.
        bytes32 b; // Lower 32 bytes.
    }

    /// @dev A representation of an extension field element (Fp2) in the BLS12-381 curve.
    struct Fp2 {
        bytes32 c0_a;
        bytes32 c0_b;
        bytes32 c1_a;
        bytes32 c1_b;
    }

    /// @dev A representation of a point on the G1 curve of BLS12-381.
    struct G1Point {
        bytes32 x_a;
        bytes32 x_b;
        bytes32 y_a;
        bytes32 y_b;
    }

    struct G2Point {
        bytes32 x_c0_a;
        bytes32 x_c0_b;
        bytes32 x_c1_a;
        bytes32 x_c1_b;
        bytes32 y_c0_a;
        bytes32 y_c0_b;
        bytes32 y_c1_a;
        bytes32 y_c1_b;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    PRECOMPILE ADDRESSES                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev For addition of two points on the BLS12-381 G1 curve,
    address internal constant BLS12_G1ADD = 0x000000000000000000000000000000000000000b;

    /// @dev For scalar multiplication of a point on the BLS12-381 G1 curve.
    address internal constant BLS12_G1MUL = 0x000000000000000000000000000000000000000C;

    /// @dev For multi-scalar multiplication (MSM) on the BLS12-381 G1 curve.
    address internal constant BLS12_G1MSM = 0x000000000000000000000000000000000000000d;

    /// @dev For addition of two points on the BLS12-381 G2 curve.
    address internal constant BLS12_G2ADD = 0x000000000000000000000000000000000000000E;

    /// @dev For scalar multiplication of a point on the BLS12-381 G2 curve,
    address internal constant BLS12_G2MUL = 0x000000000000000000000000000000000000000F;

    /// @dev For multi-scalar multiplication (MSM) on the BLS12-381 G2 curve.
    address internal constant BLS12_G2MSM = 0x0000000000000000000000000000000000000010;

    /// @dev For performing a pairing check on the BLS12-381 curve.
    address internal constant BLS12_PAIRING_CHECK = 0x0000000000000000000000000000000000000011;

    /// @dev For mapping a Fp to a point on the BLS12-381 G1 curve.
    address internal constant BLS12_MAP_FP_TO_G1 = 0x0000000000000000000000000000000000000012;

    /// @dev For mapping a Fp2 to a point on the BLS12-381 G2 curve.
    address internal constant BLS12_MAP_FP2_TO_G2 = 0x0000000000000000000000000000000000000013;

    /// @dev For modular exponentiation.
    address internal constant MOD_EXP = 0x0000000000000000000000000000000000000005;

    /// @dev For sha2-256.
    address internal constant SHA2_256 = 0x0000000000000000000000000000000000000002;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The G1Add operation failed.
    error G1AddFailed();

    /// @dev The G1Mul operation failed.
    error G1MulFailed();

    /// @dev The G1MSM operation failed.
    error G1MSMFailed();

    /// @dev The G2Add operation failed.
    error G2AddFailed();

    /// @dev The G2Mul operation failed.
    error G2MulFailed();

    /// @dev The G2MSM operation failed.
    error G2MSMFailed();

    /// @dev The pairing operation failed.
    error PairingFailed();

    /// @dev The MapFpToG1 operation failed.
    error MapFpToG1Failed();

    /// @dev The MapFpToG2 operation failed.
    error MapFp2ToG2Failed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function add(G1Point memory point0, G1Point memory point1)
        internal
        view
        returns (G1Point memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // G1 addition call expects 256 bytes as an input that is the
            // byte concatenation of two G1 points (128 bytes each).
            // Output is an encoding of a single G1 point (128 bytes).
            mstore(add(result, 0x00), mload(add(point0, 0x00)))
            mstore(add(result, 0x20), mload(add(point0, 0x20)))
            mstore(add(result, 0x40), mload(add(point0, 0x40)))
            mstore(add(result, 0x60), mload(add(point0, 0x60)))
            mstore(add(result, 0x80), mload(add(point1, 0x00)))
            mstore(add(result, 0xa0), mload(add(point1, 0x20)))
            mstore(add(result, 0xc0), mload(add(point1, 0x40)))
            mstore(add(result, 0xe0), mload(add(point1, 0x60)))
            if iszero(
                and(
                    eq(returndatasize(), 0x80),
                    staticcall(gas(), BLS12_G1ADD, result, 0x100, result, 0x80)
                )
            ) {
                mstore(0x00, 0xd6cc76eb) // `G1AddFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    function mul(G1Point memory point, bytes32 scalar)
        internal
        view
        returns (G1Point memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // G1 multiplication call expects 160 bytes as an input that is the
            // byte concatenation of encoding of a G1 point (128 bytes) and
            // encoding of a scalar value (32 bytes).
            // Output is an encoding of a single G1 point (128 bytes).
            mstore(add(result, 0x00), mload(add(point, 0x00)))
            mstore(add(result, 0x20), mload(add(point, 0x20)))
            mstore(add(result, 0x40), mload(add(point, 0x40)))
            mstore(add(result, 0x60), mload(add(point, 0x60)))
            mstore(add(result, 0x80), scalar)
            if iszero(
                and(
                    eq(returndatasize(), 0x80),
                    staticcall(gas(), BLS12_G1MUL, result, 0xa0, result, 0x80)
                )
            ) {
                mstore(0x00, 0x82e1cf54) // `G1MulFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    function msm(G1Point[] memory points, uint256[] memory scalars)
        internal
        view
        returns (G1Point memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let k := mload(points)
            if iszero(eq(k, mload(scalars))) {
                mstore(0x00, 0x5f776986) // `G1MSMFailed()`.
                revert(0x1c, 0x04)
            }
            // G1 MSM call expects `160 * k` (`k` being a positive integer) bytes as an input
            // that is the byte concatenation of `k` slices each of them being a
            // byte concatenation of encoding of a G1 point (128 bytes)
            // and encoding of a scalar value (32 bytes).
            // Output is an encoding of a single G1 point (128 bytes).
            for { let i := 0 } iszero(eq(i, k)) { i := add(i, 1) } {
                let o := add(result, mul(0xa0, i))
                let point := mload(add(add(points, 0x20), shl(5, i)))
                mstore(add(o, 0x00), mload(add(point, 0x00)))
                mstore(add(o, 0x20), mload(add(point, 0x20)))
                mstore(add(o, 0x40), mload(add(point, 0x40)))
                mstore(add(o, 0x60), mload(add(point, 0x60)))
                mstore(add(o, 0x80), mload(add(add(scalars, 0x20), shl(5, i))))
            }
            if iszero(
                and(
                    eq(returndatasize(), 0x80),
                    staticcall(gas(), BLS12_G1MSM, result, mul(0xa0, k), result, 0x80)
                )
            ) {
                mstore(0x00, 0x5f776986) // `G1MSMFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    function add(G2Point memory point0, G2Point memory point1)
        internal
        view
        returns (G2Point memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // G2 addition call expects 512 bytes as an input that is the
            // byte concatenation of two G2 points (256 bytes each).
            // Output is an encoding of a single G2 point (256 bytes).
            mstore(add(result, 0x00), mload(add(point0, 0x00)))
            mstore(add(result, 0x20), mload(add(point0, 0x20)))
            mstore(add(result, 0x40), mload(add(point0, 0x40)))
            mstore(add(result, 0x60), mload(add(point0, 0x60)))
            mstore(add(result, 0x80), mload(add(point0, 0x80)))
            mstore(add(result, 0xa0), mload(add(point0, 0xa0)))
            mstore(add(result, 0xc0), mload(add(point0, 0xc0)))
            mstore(add(result, 0xe0), mload(add(point0, 0xe0)))
            mstore(add(result, 0x00), mload(add(point1, 0x100)))
            mstore(add(result, 0x20), mload(add(point1, 0x120)))
            mstore(add(result, 0x40), mload(add(point1, 0x140)))
            mstore(add(result, 0x60), mload(add(point1, 0x160)))
            mstore(add(result, 0x80), mload(add(point1, 0x180)))
            mstore(add(result, 0xa0), mload(add(point1, 0x1a0)))
            mstore(add(result, 0xc0), mload(add(point1, 0x1c0)))
            mstore(add(result, 0xe0), mload(add(point1, 0x1e0)))
            if iszero(
                and(
                    eq(returndatasize(), 0x100),
                    staticcall(gas(), BLS12_G2ADD, result, 0x200, result, 0x100)
                )
            ) {
                mstore(0x00, 0xc55e5e33) // `G2AddFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    function mul(G2Point memory point, bytes32 scalar)
        internal
        view
        returns (G2Point memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // G2 multiplication call expects 160 bytes as an input that is the
            // byte concatenation of encoding of a G2 point (256 bytes) and
            // encoding of a scalar value (32 bytes).
            // Output is an encoding of a single G2 point (256 bytes).
            mstore(add(result, 0x00), mload(add(point, 0x00)))
            mstore(add(result, 0x20), mload(add(point, 0x20)))
            mstore(add(result, 0x40), mload(add(point, 0x40)))
            mstore(add(result, 0x60), mload(add(point, 0x60)))
            mstore(add(result, 0x80), mload(add(point, 0x80)))
            mstore(add(result, 0xa0), mload(add(point, 0xa0)))
            mstore(add(result, 0xc0), mload(add(point, 0xc0)))
            mstore(add(result, 0xe0), mload(add(point, 0xe0)))
            mstore(add(result, 0x100), scalar)
            if iszero(
                and(
                    eq(returndatasize(), 0x100),
                    staticcall(gas(), BLS12_G2MUL, result, 0x120, result, 0x100)
                )
            ) {
                mstore(0x00, 0x82e1cf54) // `G1MulFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    function msm(G2Point[] memory points, uint256[] memory scalars)
        internal
        view
        returns (G2Point memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let k := mload(points)
            if iszero(eq(k, mload(scalars))) {
                mstore(0x00, 0xe3dc5425) // `G2MSMFailed()`.
                revert(0x1c, 0x04)
            }
            // G2 MSM call expects `288 * k` (`k` being a positive integer) bytes as an input
            // that is the byte concatenation of `k` slices each of them being a
            // byte concatenation of encoding of a G2 point (256 bytes)
            // and encoding of a scalar value (32 bytes).
            // Output is an encoding of a single G2 point (256 bytes).
            for { let i := 0 } iszero(eq(i, k)) { i := add(i, 1) } {
                let o := add(result, mul(0x120, i))
                let point := mload(add(add(points, 0x20), shl(5, i)))
                mstore(add(o, 0x00), mload(add(point, 0x00)))
                mstore(add(o, 0x20), mload(add(point, 0x20)))
                mstore(add(o, 0x40), mload(add(point, 0x40)))
                mstore(add(o, 0x60), mload(add(point, 0x60)))
                mstore(add(o, 0x80), mload(add(point, 0x80)))
                mstore(add(o, 0xa0), mload(add(point, 0xa0)))
                mstore(add(o, 0xc0), mload(add(point, 0xc0)))
                mstore(add(o, 0xe0), mload(add(point, 0xe0)))
                mstore(add(o, 0x100), mload(add(add(scalars, 0x20), shl(5, i))))
            }
            if iszero(
                and(
                    eq(returndatasize(), 0x100),
                    staticcall(gas(), BLS12_G2MSM, result, mul(0x120, k), result, 0x100)
                )
            ) {
                mstore(0x00, 0xe3dc5425) // `G2MSMFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    function pairing(G1Point[] memory g1Points, G2Point[] memory g2Points)
        internal
        view
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let k := mload(g1Points)
            if iszero(eq(k, mload(g1Points))) {
                mstore(0x00, 0x4df45e2f) // `PairingFailed()`.
                revert(0x1c, 0x04)
            }
            let m := mload(0x40)
            // Pairing check call expects `384 * k` (`k` being a positive integer) bytes as input
            // that is the byte concatenation of `k` slices. Each slice has the following structure:
            // - 128 bytes of G1 point encoding
            // - 256 bytes of G2 point encoding
            for { let i := 0 } iszero(eq(i, k)) { i := add(i, 1) } {
                let o := add(m, mul(0x180, i))
                let g1Point := mload(add(add(g1Points, 0x20), shl(5, i)))
                let g2Point := mload(add(add(g2Points, 0x20), shl(5, i)))
                mstore(add(o, 0x00), mload(add(g1Point, 0x00)))
                mstore(add(o, 0x20), mload(add(g1Point, 0x20)))
                mstore(add(o, 0x40), mload(add(g1Point, 0x40)))
                mstore(add(o, 0x60), mload(add(g1Point, 0x60)))
                mstore(add(o, 0x80), mload(add(g2Point, 0x00)))
                mstore(add(o, 0xa0), mload(add(g2Point, 0x20)))
                mstore(add(o, 0xc0), mload(add(g2Point, 0x40)))
                mstore(add(o, 0xe0), mload(add(g2Point, 0x60)))
                mstore(add(o, 0x100), mload(add(g2Point, 0x80)))
                mstore(add(o, 0x120), mload(add(g2Point, 0xa0)))
                mstore(add(o, 0x140), mload(add(g2Point, 0xc0)))
                mstore(add(o, 0x160), mload(add(g2Point, 0xe0)))
            }
            if iszero(
                and(
                    eq(returndatasize(), 0x20),
                    staticcall(gas(), BLS12_PAIRING_CHECK, m, mul(0x180, k), 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0xe3dc5425) // `G2MSMFailed()`.
                revert(0x1c, 0x04)
            }
            result := mload(0x00)
        }
    }
}
