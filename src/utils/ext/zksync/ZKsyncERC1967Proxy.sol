// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice A sufficiently minimal ERC1967 proxy tailored made for ZKsync.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ext/zksync/ZKsyncERC1967Proxy.sol)
contract ZKsyncERC1967Proxy {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when the proxy's implementation is upgraded.
    event Upgraded(address indexed implementation);

    /// @dev `keccak256(bytes("Upgraded(address)"))`.
    uint256 private constant _UPGRADED_EVENT_SIGNATURE =
        0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ERC-1967 storage slot for the implementation in the proxy.
    /// `uint256(keccak256("eip1967.proxy.implementation")) - 1`.
    bytes32 internal constant _ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev The storage slot for the deployer.
    /// `uint256(keccak256("ZKsyncERC1967Proxy.deployer")) - 1`.
    bytes32 internal constant _ZKSYNC_ERC1967_PROXY_DEPLOYER_SLOT =
        0x83aea57e05b1947e389ff216588717a5ffa47e2175df535893bc27b10acffeb2;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor() payable {
        /// @solidity memory-safe-assembly
        assembly {
            sstore(_ZKSYNC_ERC1967_PROXY_DEPLOYER_SLOT, caller())
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          FALLBACK                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    fallback() external payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, 0) // Optimization trick to remove free memory pointer initialization.
            // For the special case of 1-byte calldata, return the implementation.
            if eq(calldatasize(), 1) {
                mstore(0x00, sload(_ERC1967_IMPLEMENTATION_SLOT))
                return(0x00, 0x20)
            }
            // Deployer workflow.
            if eq(caller(), sload(_ZKSYNC_ERC1967_PROXY_DEPLOYER_SLOT)) {
                let newImplementation := calldataload(0x00)
                sstore(_ERC1967_IMPLEMENTATION_SLOT, newImplementation)
                if gt(calldatasize(), 0x20) {
                    let n := sub(calldatasize(), 0x20)
                    calldatacopy(0x00, 0x20, n)
                    if iszero(delegatecall(gas(), newImplementation, 0x00, n, 0x00, 0x00)) {
                        // Bubble up the revert if the call reverts.
                        returndatacopy(0x00, 0x00, returndatasize())
                        revert(0x00, returndatasize())
                    }
                }
                // Emit the {Upgraded} event.
                log2(0x00, 0x00, _UPGRADED_EVENT_SIGNATURE, newImplementation)
                stop() // End the context.
            }
            // Perform the delegatecall.
            let implementation := sload(_ERC1967_IMPLEMENTATION_SLOT)
            calldatacopy(0x00, 0x00, calldatasize())
            let s := delegatecall(gas(), implementation, 0x00, calldatasize(), 0x00, 0x00)
            returndatacopy(0x00, 0x00, returndatasize())
            if iszero(s) { revert(0x00, returndatasize()) }
            return(0x00, returndatasize())
        }
    }
}
