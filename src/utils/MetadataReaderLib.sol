// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for reading contract metadata.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MetadataReaderLib.sol)
library MetadataReaderLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                METADATA READING OPERATIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function readName(address target) internal view returns (string memory) {
        return _string(target, bytes32(~uint256(0x06fdde03)));
    }

    function readSymbol(address target) internal view returns (string memory) {
        return _string(target, bytes32(~uint256(0x95d89b41)));
    }

    function readString(address target, bytes memory data) internal view returns (string memory) {
        return _string(target, _ptr(data));
    }

    function readDecimals(address target) internal view returns (uint8) {
        return uint8(_uint(target, bytes32(~uint256(0x313ce567))));
    }
    
    function readUint(address target, bytes memory data) internal view returns (uint256) {
        return _uint(target, _ptr(data));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Attempts to read and return a string at `target`.
    function _string(address target, bytes32 ptr) private view returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            if byte(0, ptr) {
                mstore(0x04, not(ptr))
                mstore(0x00, 4)
                ptr := 0
            }
            function min(x_, y_) -> _z {
                _z := xor(x_, mul(lt(y_, x_), xor(y_, x_)))
            }
            let m := mload(0x40)
            for {} staticcall(gas(), target, add(ptr, 0x20), mload(ptr), 0x00, 0x00) {} {
                let e := 0xffffff
                let l := min(returndatasize(), e)
                returndatacopy(m, 0, l)
                if iszero(lt(l, 0x40)) {
                    let o := min(mload(m), e)
                    if iszero(gt(add(o, 0x20), l)) {
                        let z := add(0x20, min(mload(add(m, o)), e))
                        if iszero(gt(add(o, z), l)) {
                            returndatacopy(m, o, z)
                            mstore(add(m, z), 0)
                            mstore(0x40, add(0x20, add(m, z)))
                            result := m
                            break
                        }
                    }
                }
                let i := 0
                mstore8(add(m, l), 0)
                for {} byte(0, mload(add(i, m))) { i := add(i, 1) } {}
                mstore(m, i)
                let j := add(0x20, m)
                returndatacopy(j, 0, i)
                mstore(add(j, i), 0)
                mstore(0x40, add(0x20, add(j, i)))
                result := m
                break
            }
        }
    }

    /// @dev Attempts to read and return a unsigned integer at `target`.
    function _uint(address target, bytes32 ptr) private view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            if byte(0, ptr) {
                mstore(0x04, not(ptr))
                mstore(0x00, 4)
                ptr := 0
            }
            result := mul(
                mload(0x20),
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), target, add(ptr, 0x20), mload(ptr), 0x20, 0x20)
                )
            )
        }
    }

    /// @dev Casts the `data` into a pointer.
    function _ptr(bytes memory data) private pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := data
        }
    }
}
