// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for interacting with ERC6551 accounts.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/LibERC7579.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/main/contracts/account/utils/draft-ERC7579Utils.sol)
library LibERC7579 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Call struct for the `execute` function.
    /// In other places, this struct may be called "Call".
    /// You can use assembly to reinterpret cast it.
    struct Execution {
        address target;
        uint256 value;
        bytes data;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    DECODING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Decodes a single call execution.
    /// Reverts if `executionData` is not correctly encoded.
    function decodeSingle(bytes calldata executionData)
        internal
        pure
        returns (address target, uint256 value, bytes calldata data)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(gt(executionData.length, 0x33)) { invalid() }
            target := shr(96, calldataload(executionData.offset))
            value := calldataload(add(executionData.offset, 0x14))
            data.offset := add(executionData.offset, 0x34)
            data.length := sub(executionData.length, 0x34)
        }
    }

    /// @dev Decodes a single call execution without bounds checks.
    function decodeSingleUnchecked(bytes calldata executionData)
        internal
        pure
        returns (address target, uint256 value, bytes calldata data)
    {
        /// @solidity memory-safe-assembly
        assembly {
            target := shr(96, calldataload(executionData.offset))
            value := calldataload(add(executionData.offset, 0x14))
            data.offset := add(executionData.offset, 0x34)
            data.length := sub(executionData.length, 0x34)
        }
    }

    /// @dev Decodes a single delegate execution.
    /// Reverts if `executionData` is not correctly encoded.
    function decodeDelegate(bytes calldata executionData)
        internal
        pure
        returns (address target, bytes calldata data)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(gt(executionData.length, 0x13)) { invalid() }
            target := shr(96, calldataload(executionData.offset))
            data.offset := add(executionData.offset, 0x14)
            data.length := sub(executionData.length, 0x14)
        }
    }

    /// @dev Decodes a single delegate execution without bounds checks.
    function decodeDelegateUnchecked(bytes calldata executionData)
        internal
        pure
        returns (address target, bytes calldata data)
    {
        /// @solidity memory-safe-assembly
        assembly {
            target := shr(96, calldataload(executionData.offset))
            data.offset := add(executionData.offset, 0x14)
            data.length := sub(executionData.length, 0x14)
        }
    }

    /// @dev Decodes a batch.
    /// Reverts if `executionData` is not correctly encoded.
    function decodeBatch(bytes calldata executionData)
        internal
        pure
        returns (bytes32[] calldata pointers)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let u := calldataload(executionData.offset)
            if or(shr(64, u), gt(0x20, executionData.length)) { invalid() }
            pointers.offset := add(add(executionData.offset, u), 0x20)
            pointers.length := calldataload(add(executionData.offset, u))
            if pointers.length {
                let e := sub(add(executionData.offset, executionData.length), 0x20)
                // Perform bounds checks on the decoded `pointers`.
                // Does an out-of-gas revert.
                for { let i := pointers.length } 1 {} {
                    let p := calldataload(add(pointers.offset, shl(5, sub(i, 1))))
                    let c := add(pointers.offset, p)
                    let q := calldataload(add(c, 0x40))
                    let o := add(c, q)
                    // forgefmt: disable-next-item
                    i := sub(i, iszero(or(shr(64, or(calldataload(o), or(p, q))),
                        or(gt(add(c, 0x40), e), gt(add(o, calldataload(o)), e)))))
                    if iszero(i) { break }
                }
            }
        }
    }

    /// @dev Decodes a batch without bounds checks.
    /// This function can be used in `execute`, if the validation phase has already
    /// decoded the `executionData` with checks via `decodeBatch`.
    function decodeBatchUnchecked(bytes calldata executionData)
        internal
        pure
        returns (bytes32[] calldata pointers)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let o := add(executionData.offset, calldataload(executionData.offset))
            pointers.offset := add(o, 0x20)
            pointers.length := calldataload(o)
        }
    }

    /// @dev Decodes a batch and optional `opData`.
    /// Reverts if `executionData` is not correctly encoded.
    function decodeBatchAndOpData(bytes calldata executionData)
        internal
        pure
        returns (bytes32[] calldata pointers, bytes calldata opData)
    {
        opData = emptyCalldataBytes();
        pointers = decodeBatch(executionData);
        if (hasOpData(executionData)) {
            /// @solidity memory-safe-assembly
            assembly {
                let e := sub(add(executionData.offset, executionData.length), 0x20)
                let p := calldataload(add(0x20, executionData.offset))
                let q := add(executionData.offset, p)
                opData.offset := add(q, 0x20)
                opData.length := calldataload(q)
                if or(shr(64, or(opData.length, p)), gt(add(q, opData.length), e)) { invalid() }
            }
        }
    }

    /// @dev Decodes a batch without bounds checks.
    /// This function can be used in `execute`, if the validation phase has already
    /// decoded the `executionData` with checks via `decodeBatchAndOpData`.
    function decodeBatchAndOpDataUnchecked(bytes calldata executionData)
        internal
        pure
        returns (bytes32[] calldata pointers, bytes calldata opData)
    {
        opData = emptyCalldataBytes();
        pointers = decodeBatchUnchecked(executionData);
        if (hasOpData(executionData)) {
            /// @solidity memory-safe-assembly
            assembly {
                let q := add(executionData.offset, calldataload(add(0x20, executionData.offset)))
                opData.offset := add(q, 0x20)
                opData.length := calldataload(q)
            }
        }
    }

    /// @dev Returns whether the `executionData` has optional `opData`.
    function hasOpData(bytes calldata executionData) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result :=
                iszero(or(lt(executionData.length, 0x40), lt(calldataload(executionData.offset), 0x40)))
        }
    }

    /// @dev Returns the `i`th execution at `pointers`.
    function getExecution(bytes32[] calldata pointers, uint256 i)
        internal
        pure
        returns (address target, uint256 value, bytes calldata data)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(i, pointers.length)) { invalid() }
            let c := add(pointers.offset, calldataload(add(pointers.offset, shl(5, i))))
            target := calldataload(c)
            value := calldataload(add(c, 0x20))
            let o := add(c, calldataload(add(c, 0x40)))
            data.offset := add(o, 0x20)
            data.length := calldataload(o)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          HELPERS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Helper function to return empty calldata bytes.
    function emptyCalldataBytes() internal pure returns (bytes calldata result) {
        /// @solidity memory-safe-assembly
        assembly {
            result.offset := 0
            result.length := 0
        }
    }
}
