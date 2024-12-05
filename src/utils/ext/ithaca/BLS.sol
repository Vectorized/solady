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

    /// @dev A representation of a point on the G2 curve of BLS12-381.
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
            pop(staticcall(gas(), 4, point0, 0x80, result, 0x80))
            pop(staticcall(gas(), 4, point1, 0x80, add(result, 0x80), 0x80))
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
            let t := mload(add(point, 0x80))
            mstore(add(point, 0x80), scalar)
            if iszero(
                and(
                    eq(returndatasize(), 0x80),
                    staticcall(gas(), BLS12_G1MUL, point, 0xa0, result, 0x80)
                )
            ) {
                mstore(0x00, 0x82e1cf54) // `G1MulFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(add(point, 0x80), t)
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
            let d := sub(scalars, points)
            for { let i := 0 } iszero(eq(i, k)) { i := add(i, 1) } {
                points := add(points, 0x20)
                let o := add(result, mul(0xa0, i))
                pop(staticcall(gas(), 4, mload(points), 0x80, o, 0x80))
                mstore(add(o, 0x80), mload(add(points, d)))
            }
            if iszero(
                and(
                    and(eq(k, mload(scalars)), eq(returndatasize(), 0x80)),
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
            pop(staticcall(gas(), 4, point0, 0x100, result, 0x100))
            pop(staticcall(gas(), 4, point1, 0x100, add(result, 0x100), 0x100))
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
            let t := mload(add(point, 0x100))
            mstore(add(point, 0x100), scalar)
            if iszero(
                and(
                    eq(returndatasize(), 0x100),
                    staticcall(gas(), BLS12_G2MUL, point, 0x120, result, 0x100)
                )
            ) {
                mstore(0x00, 0x82e1cf54) // `G1MulFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(add(point, 0x100), t)
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
            let d := sub(scalars, points)
            for { let i := 0 } iszero(eq(i, k)) { i := add(i, 1) } {
                points := add(points, 0x20)
                let o := add(result, mul(0x120, i))
                pop(staticcall(gas(), 4, mload(points), 0x100, o, 0x100))
                mstore(add(o, 0x100), mload(add(d, points)))
            }
            if iszero(
                and(
                    and(eq(k, mload(scalars)), eq(returndatasize(), 0x100)),
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
            let m := mload(0x40)
            let d := sub(g2Points, g1Points)
            for { let i := 0 } iszero(eq(i, k)) { i := add(i, 1) } {
                g1Points := add(g1Points, 0x20)
                let o := add(m, mul(0x180, i))
                pop(staticcall(gas(), 4, mload(g1Points), 0x80, o, 0x80))
                pop(staticcall(gas(), 4, mload(add(d, g1Points)), 0x100, add(o, 0x80), 0x100))
            }
            if iszero(
                and(
                    and(eq(k, mload(g2Points)), eq(returndatasize(), 0x20)),
                    staticcall(gas(), BLS12_PAIRING_CHECK, m, mul(0x180, k), 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0xe3dc5425) // `G2MSMFailed()`.
                revert(0x1c, 0x04)
            }
            result := mload(0x00)
        }
    }

    function mapFpToG1(Fp memory element) internal view returns (G1Point memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(
                and(
                    eq(returndatasize(), 0x80),
                    staticcall(gas(), BLS12_MAP_FP_TO_G1, element, 0x40, result, 0x80)
                )
            ) {
                mstore(0x00, 0x24a289fc) // `MapFpToG1Failed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    function mapFp2ToG2(Fp2 memory element) internal view returns (G2Point memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(
                and(
                    eq(returndatasize(), 0x100),
                    staticcall(gas(), BLS12_MAP_FP2_TO_G2, element, 0x80, result, 0x100)
                )
            ) {
                mstore(0x00, 0x89083b91) // `MapFp2ToG2Failed()`.
                revert(0x1c, 0x04)
            }
        }
    }
}
