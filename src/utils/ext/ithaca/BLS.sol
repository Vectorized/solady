// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice BLS wrapper.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/BLS.sol)
/// @author Ithaca (https://github.com/ithacaxyz/odyssey-examples/blob/main/chapter1/contracts/src/libraries/BLS.sol)
///
/// @dev Precompile addresses come from the BLS addresses submodule in AlphaNet, see
/// See: (https://github.com/paradigmxyz/alphanet/blob/main/crates/precompile/src/addresses.rs)
///
/// Note:
/// - This implementation uses `mcopy`, since any chain that is edgy enough to
///   implement the BLS precompiles will definitely have implemented cancun.
/// - For efficiency, we use the legacy `staticcall` to call the precompiles.
///   For the intended use case in an entry points that requires gas-introspection,
///   which requires legacy bytecode, this won't be a blocker.
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

    /// @dev For multi-scalar multiplication (MSM) on the BLS12-381 G1 curve.
    address internal constant BLS12_G1MSM = 0x000000000000000000000000000000000000000C;

    /// @dev For addition of two points on the BLS12-381 G2 curve.
    address internal constant BLS12_G2ADD = 0x000000000000000000000000000000000000000d;

    /// @dev For multi-scalar multiplication (MSM) on the BLS12-381 G2 curve.
    address internal constant BLS12_G2MSM = 0x000000000000000000000000000000000000000E;

    /// @dev For performing a pairing check on the BLS12-381 curve.
    address internal constant BLS12_PAIRING_CHECK = 0x000000000000000000000000000000000000000F;

    /// @dev For mapping a Fp to a point on the BLS12-381 G1 curve.
    address internal constant BLS12_MAP_FP_TO_G1 = 0x0000000000000000000000000000000000000010;

    /// @dev For mapping a Fp2 to a point on the BLS12-381 G2 curve.
    address internal constant BLS12_MAP_FP2_TO_G2 = 0x0000000000000000000000000000000000000011;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // A custom error for each precompile helps us in debugging which precompile has failed.

    /// @dev The G1Add operation failed.
    error G1AddFailed();

    /// @dev The G1MSM operation failed.
    error G1MSMFailed();

    /// @dev The G2Add operation failed.
    error G2AddFailed();

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

    /// @dev Adds two G1 points. Returns a new G1 point.
    function add(G1Point memory point0, G1Point memory point1)
        internal
        view
        returns (G1Point memory result)
    {
        assembly ("memory-safe") {
            mcopy(result, point0, 0x80)
            mcopy(add(result, 0x80), point1, 0x80)
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

    /// @dev Multi-scalar multiplication of G1 points with scalars. Returns a new G1 point.
    function msm(G1Point[] memory points, bytes32[] memory scalars)
        internal
        view
        returns (G1Point memory result)
    {
        assembly ("memory-safe") {
            let k := mload(points)
            let d := sub(scalars, points)
            for { let i := 0 } iszero(eq(i, k)) { i := add(i, 1) } {
                points := add(points, 0x20)
                let o := add(result, mul(0xa0, i))
                mcopy(o, mload(points), 0x80)
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

    /// @dev Adds two G2 points. Returns a new G2 point.
    function add(G2Point memory point0, G2Point memory point1)
        internal
        view
        returns (G2Point memory result)
    {
        assembly ("memory-safe") {
            mcopy(result, point0, 0x100)
            mcopy(add(result, 0x100), point1, 0x100)
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

    /// @dev Multi-scalar multiplication of G2 points with scalars. Returns a new G2 point.
    function msm(G2Point[] memory points, bytes32[] memory scalars)
        internal
        view
        returns (G2Point memory result)
    {
        assembly ("memory-safe") {
            let k := mload(points)
            let d := sub(scalars, points)
            for { let i := 0 } iszero(eq(i, k)) { i := add(i, 1) } {
                points := add(points, 0x20)
                let o := add(result, mul(0x120, i))
                mcopy(o, mload(points), 0x100)
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

    /// @dev Checks the pairing of G1 points with G2 points. Returns whether the pairing is valid.
    function pairing(G1Point[] memory g1Points, G2Point[] memory g2Points)
        internal
        view
        returns (bool result)
    {
        assembly ("memory-safe") {
            let k := mload(g1Points)
            let m := mload(0x40)
            let d := sub(g2Points, g1Points)
            for { let i := 0 } iszero(eq(i, k)) { i := add(i, 1) } {
                g1Points := add(g1Points, 0x20)
                let o := add(m, mul(0x180, i))
                mcopy(o, mload(g1Points), 0x80)
                mcopy(add(o, 0x80), mload(add(d, g1Points)), 0x100)
            }
            if iszero(
                and(
                    and(eq(k, mload(g2Points)), eq(returndatasize(), 0x20)),
                    staticcall(gas(), BLS12_PAIRING_CHECK, m, mul(0x180, k), 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x4df45e2f) // `PairingFailed()`.
                revert(0x1c, 0x04)
            }
            result := mload(0x00)
        }
    }

    /// @dev Maps a Fp element to a G1 point.
    function toG1(Fp memory element) internal view returns (G1Point memory result) {
        assembly ("memory-safe") {
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

    /// @dev Maps a Fp2 element to a G2 point.
    function toG2(Fp2 memory element) internal view returns (G2Point memory result) {
        assembly ("memory-safe") {
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

    /// @dev Computes a point in G2 from a message.
    function hashToG2(bytes memory message) internal view returns (G2Point memory result) {
        assembly ("memory-safe") {
            function dstPrime(o_, i_) -> _o {
                mstore8(o_, i_) // 1.
                mstore(add(o_, 0x01), "BLS_SIG_BLS12381G2_XMD:SHA-256_S") // 32.
                mstore(add(o_, 0x21), "SWU_RO_NUL_\x2b") // 12.
                _o := add(0x2d, o_)
            }

            function sha2(data_, n_) -> _h {
                if iszero(
                    and(eq(returndatasize(), 0x20), staticcall(gas(), 2, data_, n_, 0x00, 0x20))
                ) { revert(calldatasize(), 0x00) }
                _h := mload(0x00)
            }

            function modfield(s_, b_) {
                mcopy(add(s_, 0x60), b_, 0x40)
                if iszero(
                    and(eq(returndatasize(), 0x40), staticcall(gas(), 5, s_, 0x100, b_, 0x40))
                ) { revert(calldatasize(), 0x00) }
            }

            function mapToG2(s_, r_) {
                if iszero(
                    and(
                        eq(returndatasize(), 0x100),
                        staticcall(gas(), BLS12_MAP_FP2_TO_G2, s_, 0x80, r_, 0x100)
                    )
                ) {
                    mstore(0x00, 0x89083b91) // `MapFp2ToG2Failed()`.
                    revert(0x1c, 0x04)
                }
            }

            let b := mload(0x40)
            let s := add(b, 0x100)
            calldatacopy(s, calldatasize(), 0x40)
            mcopy(add(0x40, s), add(0x20, message), mload(message))
            let o := add(add(0x40, s), mload(message))
            mstore(o, shl(240, 256))
            let b0 := sha2(s, sub(dstPrime(add(0x02, o), 0), s))
            mstore(0x20, b0)
            mstore(s, b0)
            mstore(b, sha2(s, sub(dstPrime(add(0x20, s), 1), s)))
            let j := b
            for { let i := 2 } 1 {} {
                mstore(s, xor(b0, mload(j)))
                j := add(j, 0x20)
                mstore(j, sha2(s, sub(dstPrime(add(0x20, s), i), s)))
                i := add(i, 1)
                if eq(i, 9) { break }
            }

            mstore(add(s, 0x00), 0x40)
            mstore(add(s, 0x20), 0x20)
            mstore(add(s, 0x40), 0x40)
            mstore(add(s, 0xa0), 1)
            mstore(add(s, 0xc0), 0x000000000000000000000000000000001a0111ea397fe69a4b1ba7b6434bacd7)
            mstore(add(s, 0xe0), 0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab)
            modfield(s, add(b, 0x00))
            modfield(s, add(b, 0x40))
            modfield(s, add(b, 0x80))
            modfield(s, add(b, 0xc0))

            mapToG2(b, result)
            mapToG2(add(0x80, b), add(0x100, result))

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
}
