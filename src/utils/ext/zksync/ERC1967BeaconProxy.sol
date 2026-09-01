// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice A sufficiently minimal ERC1967 beacon proxy tailor-made for ZKsync.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ext/zksync/ERC1967BeaconProxy.sol)
contract ERC1967BeaconProxy {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when the proxy's beacon is upgraded.
    event BeaconUpgraded(address indexed beacon);

    /// @dev `keccak256(bytes("BeaconUpgraded(address)"))`.
    uint256 private constant _BEACON_UPGRADED_EVENT_SIGNATURE =
        0x1cf3b03a6cf19fa2baba4df148e9dcabedea7f8a5c07840e207e5c089be95d3e;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ERC-1967 storage slot for the beacon in the proxy.
    /// `uint256(keccak256("eip1967.proxy.beacon")) - 1`.
    bytes32 internal constant _ERC1967_BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /// @dev The storage slot for the deployer.
    /// `uint256(keccak256("ERC1967BeaconProxy.deployer")) - 1`.
    bytes32 internal constant _ERC1967_BEACON_PROXY_DEPLOYER_SLOT =
        0xabc1f855dddf3277214739f5a08d8b9db61505a97fd0c09e835a2d800705b3bc;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor() payable {
        /// @solidity memory-safe-assembly
        assembly {
            sstore(_ERC1967_BEACON_PROXY_DEPLOYER_SLOT, caller())
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
                mstore(0x00, 0x5c60da1b) // `implementation()`.
                let s := staticcall(gas(), sload(_ERC1967_BEACON_SLOT), 0x1c, 0x04, 0x00, 0x20)
                if iszero(and(gt(returndatasize(), 0x1f), s)) { revert(0x00, 0x00) }
                return(0x00, 0x20) // Return the implementation.
            }
            // Deployer workflow.
            if eq(caller(), sload(_ERC1967_BEACON_PROXY_DEPLOYER_SLOT)) {
                let beacon := calldataload(0x00)
                sstore(_ERC1967_BEACON_SLOT, beacon)
                // Make the initialization call
                if gt(calldatasize(), 0x20) {
                    mstore(0x00, 0x5c60da1b) // `implementation()`.
                    let t := staticcall(gas(), beacon, 0x1c, 0x04, 0x00, 0x20)
                    if iszero(and(gt(returndatasize(), 0x1f), t)) { revert(0x00, 0x00) }
                    let implementation := mload(0x00)
                    let n := sub(calldatasize(), 0x20)
                    calldatacopy(0x00, 0x20, n)
                    if iszero(delegatecall(gas(), implementation, 0x00, n, 0x00, 0x00)) {
                        // Bubble up the revert if the call reverts.
                        returndatacopy(0x00, 0x00, returndatasize())
                        revert(0x00, returndatasize())
                    }
                }
                // Emit the {BeaconUpgraded} event.
                log2(0x00, 0x00, _BEACON_UPGRADED_EVENT_SIGNATURE, beacon)
                stop() // End the context.
            }
            // Query the beacon.
            mstore(0x00, 0x5c60da1b) // `implementation()`.
            let s := staticcall(gas(), sload(_ERC1967_BEACON_SLOT), 0x1c, 0x04, 0x00, 0x20)
            if iszero(and(gt(returndatasize(), 0x1f), s)) { revert(0x00, 0x00) }
            let implementation := mload(0x00)
            // Perform the delegatecall.
            calldatacopy(0x00, 0x00, calldatasize())
            s := delegatecall(gas(), implementation, 0x00, calldatasize(), 0x00, 0x00)
            returndatacopy(0x00, 0x00, returndatasize())
            if iszero(s) { revert(0x00, returndatasize()) }
            return(0x00, returndatasize())
        }
    }
}
