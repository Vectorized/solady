// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Base class for a contract that is multicallable.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MulticallLib.sol)
abstract contract Multicallable {
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        assembly {
            results := mload(0x40)
            mstore(results, data.length)
            
            let resultsOffsets := add(results, 0x20)

            let memPtr := add(resultsOffsets, shl(5, data.length))
            
            let dataLengthsEnd := add(data.offset, shl(5, data.length))

            for { let i := data.offset } iszero(eq(i, dataLengthsEnd)) { i := add(i, 0x20) } {
                // The offset of the current bytes in the calldata.
                let o := add(data.offset, calldataload(i))
                // Copy the current bytes from calldata to the memory.
                calldatacopy(
                    memPtr,
                    add(o, 0x20), // The offset of the current bytes' bytes.
                    calldataload(o) // The length of the current bytes.
                )
                if iszero(delegatecall(
                    gas(), 
                    address(), 
                    memPtr, 
                    calldataload(o), 
                    0x00, 
                    0x00
                )) {
                    // Bubble up the revert if the delegatecall reverts.
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
                // Append the current `memPtr` into `resultsOffsets`.
                mstore(resultsOffsets, memPtr)
                resultsOffsets := add(resultsOffsets, 0x20)

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
