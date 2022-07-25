// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Contract that enables a single call to call multiple methods on itself.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Multicallable.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Multicallable.sol)
abstract contract Multicallable {
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        assembly {
            results := mload(0x40)
            mstore(results, data.length)

            // The slot of the end of the offsets in `data`.
            // `shl` 5 is equivalent to multiplying by 0x20.
            let end := add(data.offset, shl(5, data.length))
            // Pointer to the array of pointers to each of the the returned data in `results`.
            let resultsPtrs := add(results, 0x20)
            // Pointer to the top of the memory (i.e. start of the free memory).
            // `shl` 5 is equivalent to multiplying by 0x20.
            let memPtr := add(resultsPtrs, shl(5, data.length))

            // prettier-ignore
            for { let i := data.offset } iszero(eq(i, end)) { i := add(i, 0x20) } {
                // The offset of the current bytes in the calldata.
                let o := add(data.offset, calldataload(i))
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
                // Append the current `memPtr` into `resultsPtrs`.
                mstore(resultsPtrs, memPtr)
                resultsPtrs := add(resultsPtrs, 0x20)

                // Append the `returndatasize()`, and the return data.
                mstore(memPtr, returndatasize())
                returndatacopy(add(memPtr, 0x20), 0x00, returndatasize())
                // Advance the `memPtr` by `returndatasize() + 0x20`,
                // rounded up to the next multiple of 32.
                memPtr := and(add(add(memPtr, returndatasize()), 0x3f), 0xffffffffffffffe0)
            }
            mstore(0x40, memPtr)
        }
    }
}
