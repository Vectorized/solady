// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/// @notice Library for accessing block hashes way beyond the 256-block limit. ref: EIP-2935
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibBlockHash.sol)
library LibBlockHash {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Address of the EIP-2935 history storage contract.
    /// See: https://eips.ethereum.org/EIPS/eip-2935
    address internal constant HISTORY_STORAGE_ADDRESS = 0x0000F90827F1C53a10cb7A02335B175320002935;

    /// @dev Retrieves the block hash for any historical block within the supported range.
    /// The function gracefully handles future blocks and blocks beyond the history window by returning zero, 
    /// consistent with the EVM's native `BLOCKHASH` behavior.
    function blockHash(uint256 blockNumber) internal view returns (bytes32 hash) {
        assembly {
            let current := number()
            let distance := sub(current, blockNumber)
            
            // Check if distance < 257
            if lt(distance, 257) {
                // Return blockhash(blockNumber)
                mstore(0x00, blockhash(blockNumber))
                return(0x00, 0x20)
            }
            
            // Store the blockNumber in scratch space
            mstore(0x00, blockNumber)
            mstore(0x20, 0)

            // call history storage address
            pop(staticcall(gas(), HISTORY_STORAGE_ADDRESS, 0x00, 0x20, 0x20, 0x20))

            // load result
            hash := mload(0x20)
        }
    }
}