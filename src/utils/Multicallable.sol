// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Contract that enables a single call to call multiple methods on itself.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Multicallable.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Multicallable.sol)
/// @dev Note that combining Multicallable with msg.value can cause double-spend issues
/// (https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/)
abstract contract Multicallable {
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory) {
        assembly {
            if data.length {
                let returndata := mload(0x40) // Point `results` to start of free memory
                let results := add(returndata, 0x20) // Pointer to `results`.

                mstore(returndata, 0x20) // Store offset to `results` in returndata.
                mstore(results, data.length) // Store `data.length` into `results`.

                let currentResultPtr := add(results, 0x20) // Pointer to current result.
                let dataLengthBytes := shl(5, data.length) // `shl` 5 is equivalent to multiplying by 0x20.

                calldatacopy(currentResultPtr, data.offset, dataLengthBytes) // Copy the offsets from calldata into memory.

                // Pointer to the top of the memory (i.e. start of the free memory).
                let memPtr := add(currentResultPtr, dataLengthBytes)
                let end := memPtr

                let resultOffset := dataLengthBytes // Pointer to offset of `result` in returndata.

                // prettier-ignore
                for {} 1 {} {
                    // The offset of the current bytes in the calldata.
                    let o := add(data.offset, mload(currentResultPtr))
                    // Copy the current bytes from calldata to the memory.
                    calldatacopy(
                        memPtr,
                        add(o, 0x20), // The offset of the current bytes' bytes.
                        calldataload(o) // The length of the current bytes.
                    )
                    if iszero(delegatecall(gas(), address(), memPtr, calldataload(o), 0x00, 0x00)) {
                        // Bubble up the revert if the delegatecall reverts.
                        returndatacopy(0x00, 0x00, returndatasize())
                        revert(0x00, returndatasize())
                    }
                    // Append the current `resultOffset` into `results`.
                    mstore(currentResultPtr, resultOffset)
                    currentResultPtr := add(currentResultPtr, 0x20)
                    // Append the `returndatasize()`, and the return data.
                    mstore(memPtr, returndatasize())
                    returndatacopy(add(memPtr, 0x20), 0x00, returndatasize())
                    // Advance the `memPtr` by `returndatasize() + 0x20`,
                    // rounded up to the next multiple of 32.
                    let advancePtr := shl(5, shr(5, add(returndatasize(), 0x3f)))

                    memPtr := add(memPtr, advancePtr)
                    resultOffset := add(resultOffset, advancePtr)

                    // prettier-ignore
                    if eq(currentResultPtr, end) { break }
                }

                return(returndata, sub(memPtr, returndata))
            }

            mstore(0x00, 0x20)
            mstore(0x20, 0x00)
            return(0x00, 0x40)
        }
    }
}
