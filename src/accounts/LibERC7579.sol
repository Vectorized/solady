// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for handling ERC7579 mode and execution data.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/LibERC7579.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/main/contracts/account/utils/draft-ERC7579Utils.sol)
library LibERC7579 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Cannot decode `executionData`.
    error DecodingError();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A single execution.
    bytes1 internal constant CALLTYPE_SINGLE = 0x00;

    /// @dev A batch of executions.
    bytes1 internal constant CALLTYPE_BATCH = 0x01;

    /// @dev A `delegatecall` execution.
    bytes1 internal constant CALLTYPE_DELEGATECALL = 0xff;

    /// @dev Default execution type that reverts on failure.
    bytes1 internal constant EXECTYPE_DEFAULT = 0x00;

    /// @dev Execution type that does not revert on failure.
    bytes1 internal constant EXECTYPE_TRY = 0x01;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      MODE OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Encodes the fields into a mode.
    function encodeMode(bytes1 callType, bytes1 execType, bytes4 selector, bytes22 payload)
        internal
        pure
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, callType)
            mstore(0x01, execType)
            mstore(0x02, selector)
            mstore(0x06, 0)
            mstore(0x0a, payload)
            result := mload(0x00)
        }
    }

    /// @dev Returns the call type of the mode.
    function getCallType(bytes32 mode) internal pure returns (bytes1) {
        return bytes1(mode);
    }

    /// @dev Returns the call type of the mode.
    function getExecType(bytes32 mode) internal pure returns (bytes1) {
        return mode[1];
    }

    /// @dev Returns the selector of the mode.
    function getSelector(bytes32 mode) internal pure returns (bytes4) {
        return bytes4(bytes32(uint256(mode) << 16));
    }

    /// @dev Returns the payload stored in the mode.
    function getPayload(bytes32 mode) internal pure returns (bytes22) {
        return bytes22(bytes32(uint256(mode) << 80));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 EXECUTION DATA OPERATIONS                  */
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
            if iszero(gt(executionData.length, 0x33)) {
                mstore(0x00, 0xba597e7e) // `DecodingError()`.
                revert(0x1c, 0x04)
            }
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
            if iszero(gt(executionData.length, 0x13)) {
                mstore(0x00, 0xba597e7e) // `DecodingError()`.
                revert(0x1c, 0x04)
            }
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
            if or(shr(64, u), gt(0x20, executionData.length)) {
                mstore(0x00, 0xba597e7e) // `DecodingError()`.
                revert(0x1c, 0x04)
            }
            pointers.offset := add(add(executionData.offset, u), 0x20)
            pointers.length := calldataload(add(executionData.offset, u))
            if pointers.length {
                let e := sub(add(executionData.offset, executionData.length), 0x20)
                // Perform bounds checks on the decoded `pointers`.
                // Does an out-of-gas revert.
                for { let i := pointers.length } 1 {} {
                    i := sub(i, 1)
                    let p := calldataload(add(pointers.offset, shl(5, i)))
                    let c := add(pointers.offset, p)
                    let q := calldataload(add(c, 0x40))
                    let o := add(c, q)
                    // forgefmt: disable-next-item
                    if or(shr(64, or(calldataload(o), or(p, q))),
                        or(gt(add(c, 0x40), e), gt(add(o, calldataload(o)), e))) {
                        mstore(0x00, 0xba597e7e) // `DecodingError()`.
                        revert(0x1c, 0x04)
                    }
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
                if or(shr(64, or(opData.length, p)), gt(add(q, opData.length), e)) {
                    mstore(0x00, 0xba597e7e) // `DecodingError()`.
                    revert(0x1c, 0x04)
                }
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

    /// @dev Returns the `i`th execution at `pointers`, without bounds checks.
    /// The bounds check is excluded as this function is intended to be called in a bounded loop.
    function getExecution(bytes32[] calldata pointers, uint256 i)
        internal
        pure
        returns (address target, uint256 value, bytes calldata data)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let c := add(pointers.offset, calldataload(add(pointers.offset, shl(5, i))))
            target := calldataload(c)
            value := calldataload(add(c, 0x20))
            let o := add(c, calldataload(add(c, 0x40)))
            data.offset := add(o, 0x20)
            data.length := calldataload(o)
        }
    }

    /// @dev Reencodes `executionData` such that it has `opData` added to it.
    /// Like `abi.encode(abi.decode(executionData, (Call[])), opData)`.
    /// Useful for forwarding `executionData` with extra `opData`.
    /// This function does not perform any check on the validity of `executionData`.
    function reencodeBatch(bytes calldata executionData, bytes memory opData)
        internal
        pure
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := add(0x64, mload(0x40)) // Give some space for `reencodeBatchAsExecuteCalldata`.
            let s := calldataload(executionData.offset) // Offset of `calls`.
            let n := sub(executionData.length, s) // Byte length of `calls`.
            mstore(add(result, 0x20), 0x40) // Store the new offset of `calls`.
            calldatacopy(add(result, 0x60), add(executionData.offset, s), n)
            mstore(add(result, 0x40), add(0x40, n)) // Store the new offset of `opData`.
            let o := add(add(result, 0x60), n) // Start offset of `opData` destination in memory.
            let d := sub(opData, o) // Offset difference between `opData` source and `o`.
            let end := add(mload(opData), add(0x20, o)) // End of `opData` destination in memory.
            for {} 1 {} {
                mstore(o, mload(add(o, d)))
                o := add(o, 0x20)
                if iszero(lt(o, end)) { break }
            }
            mstore(result, sub(o, add(result, 0x20))) // Store the length of `result`.
            calldatacopy(end, calldatasize(), 0x40) // Zeroize the bytes after `end`.
            mstore(0x40, add(0x20, o)) // Allocate memory.
        }
    }

    /// @dev `abi.encodeWithSignature("execute(bytes32,bytes)", mode, reencodeBatch(executionData, opData))`.
    function reencodeBatchAsExecuteCalldata(
        bytes32 mode,
        bytes calldata executionData,
        bytes memory opData
    ) internal pure returns (bytes memory result) {
        result = reencodeBatch(executionData, opData);
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(result)
            result := sub(result, 0x64)
            mstore(add(result, 0x44), 0x40) // Offset of `executionData`.
            mstore(add(result, 0x24), mode)
            mstore(add(result, 0x04), 0xe9ae5c53) // `execute(bytes32,bytes)`.
            mstore(result, add(0x64, n))
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
