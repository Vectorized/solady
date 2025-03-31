// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
// solc: 0.8.28, optimization runs: 200, evm version: cancun.

/// @notice Relay proxy for EIP7702 delegations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/EIP7702Proxy.sol)
///
/// @dev Note: This relay proxy is useful for upgradeable EIP7702 accounts
/// without the need for redelegation.
///
/// EOA -> EIP7702Proxy (relay) -> EIP7702 account implementation.
///
/// This relay proxy also allows for correctly revealing the
/// "Read as Proxy" and "Write as Proxy" tabs on Etherscan.
contract EIP7702Proxy {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         IMMUTABLES                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev For differentiating calls on the EOA and calls on the proxy itself.
    uint256 internal immutable __self = uint256(uint160(address(this)));

    /// @dev The default implementation. Provided for optimization.
    /// Set if the `initialAdmin == address(0) && initialImplementation != address(0)`.
    uint256 internal immutable _defaultImplementation;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ERC-1967 storage slot for the implementation in the proxy.
    /// `uint256(keccak256("eip1967.proxy.implementation")) - 1`.
    bytes32 internal constant _ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev The ERC-1967 storage slot for the admin in the proxy.
    /// `uint256(keccak256("eip1967.proxy.admin")) - 1`.
    bytes32 internal constant _ERC1967_ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /// @dev The transient storage slot for requesting the proxy to initialize the implementation.
    /// `uint256(keccak256("eip7702.proxy.delegation.initialization.request")) - 1`.
    /// While we would love to use a smaller constant, this slot is used in both the proxy
    /// and the delegation, so we shall just use bytes32 in case we want to standardize this.
    bytes32 internal constant _EIP7702_PROXY_DELEGATION_INITIALIZATION_REQUEST_SLOT =
        0x94e11c6e41e7fb92cb8bb65e13fdfbd4eba8b831292a1a220f7915c78c7c078f;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor(address initialImplementation, address initialAdmin) payable {
        uint256 defaultImplementation;
        /// @solidity memory-safe-assembly
        assembly {
            // We will store the implementation in the storage regardless,
            // to aid proxy detection on block explorers.
            sstore(_ERC1967_IMPLEMENTATION_SLOT, initialImplementation)
            sstore(_ERC1967_ADMIN_SLOT, initialAdmin)
            defaultImplementation :=
                mul(lt(initialAdmin, iszero(iszero(initialImplementation))), initialImplementation)
        }
        _defaultImplementation = defaultImplementation;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          FALLBACK                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    fallback() external payable virtual {
        uint256 s = __self;
        uint256 defaultImplementation = _defaultImplementation;
        bytes32 implementationSlot = _ERC1967_IMPLEMENTATION_SLOT;
        uint256 addrMask = (~msg.data.length) >> 96;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, 1)
            // Workflow for calling on the proxy itself.
            // We cannot put these functions in the public ABI as this proxy must
            // fully forward all the calldata from EOAs pointing to this proxy.
            if iszero(xor(address(), s)) {
                if iszero(gt(calldatasize(), 1)) {
                    mstore(0x00, and(addrMask, sload(implementationSlot)))
                    return(0x00, 0x20)
                }
                let fnSel := shr(224, calldataload(0x00))
                // `implementation()`.
                if eq(0x5c60da1b, fnSel) {
                    mstore(0x00, and(addrMask, sload(implementationSlot)))
                    return(0x00, 0x20)
                }
                let adminSlot := _ERC1967_ADMIN_SLOT
                // `admin()`.
                if eq(0xf851a440, fnSel) {
                    mstore(0x00, sload(adminSlot))
                    return(0x00, 0x20)
                }
                // Admin workflow.
                if eq(caller(), sload(adminSlot)) {
                    let addrSlot :=
                        or(
                            mul(eq(0x8f283970, fnSel), adminSlot), // `changeAdmin(address)`.
                            mul(eq(0x0900f010, fnSel), implementationSlot) // `upgrade(address)`.
                        )
                    if addrSlot {
                        sstore(addrSlot, and(addrMask, calldataload(0x04)))
                        return(0x40, 0x20) // Return `true`.
                    }
                    // For minimalism, we shall skip events and calldata bounds checks.
                    // We don't need to forward any data to the new implementation.
                    // This "proxy" is actually close to an upgradeable beacon.
                }
                revert(0x00, 0x00)
            }
            // Workflow for the EIP7702 authority (i.e. the EOA).
            let implementation := and(addrMask, sload(implementationSlot)) // On EOA's storage.
            // Special workflow for retrieving the implementation directly.
            if eq(1, calldatasize()) {
                // If the preferred implementation is `address(0)`.
                if iszero(implementation) {
                    implementation := defaultImplementation
                    // If `defaultImplementation` is `address(0)`
                    if iszero(implementation) {
                        // Fetch the implementation from the proxy.
                        if staticcall(gas(), s, 0x00, 0x00, 0x00, 0x20) {
                            return(0x00, returndatasize())
                        }
                        revert(0x00, 0x00)
                    }
                }
                mstore(0x00, implementation)
                return(0x00, 0x20)
            }
            calldatacopy(0x00, 0x00, calldatasize()) // Copy the calldata for the delegatecall.
            // If the preferred implementation is `address(0)`.
            if iszero(implementation) {
                implementation := defaultImplementation
                // If `defaultImplementation` is `address(0)`, perform the initialization workflow.
                if iszero(implementation) {
                    if iszero(
                        and( // The arguments of `and` are evaluated from right to left.
                            delegatecall(
                                gas(), mload(calldatasize()), 0x00, calldatasize(), 0x00, 0x00
                            ),
                            // Fetch the implementation from the proxy.
                            staticcall(gas(), s, 0x00, 0x00, calldatasize(), 0x20)
                        )
                    ) {
                        returndatacopy(0x00, 0x00, returndatasize())
                        revert(0x00, returndatasize())
                    }
                    // Because we cannot reliably and efficiently tell if the call is made
                    // via staticcall or call, we shall ask the delegation to make a proxy delegation
                    // initialization request to signal that we should initialize the storage slot with
                    // the actual implementation. This also gives flexibility on whether to let the
                    // proxy auto-upgrade, or let the authority manually upgrade (via 7702 or passkey).
                    // A non-zero value in the transient storage denotes a initialization request.
                    let initializationRequestSlot :=
                        _EIP7702_PROXY_DELEGATION_INITIALIZATION_REQUEST_SLOT
                    if tload(initializationRequestSlot) {
                        // The `implementation` is still at `calldatasize()` in memory.
                        // Preserve the upper 96 bits when updating in case they are used for some stuff.
                        sstore(
                            implementationSlot,
                            or(and(not(addrMask), sload(implementationSlot)), mload(calldatasize()))
                        )
                        tstore(initializationRequestSlot, 0) // Clear.
                    }
                    returndatacopy(0x00, 0x00, returndatasize())
                    return(0x00, returndatasize())
                }
            }
            // Otherwise, just delegatecall and bubble up the results without initialization.
            if iszero(delegatecall(gas(), implementation, 0x00, calldatasize(), 0x00, 0x00)) {
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }
            returndatacopy(0x00, 0x00, returndatasize())
            return(0x00, returndatasize())
        }
    }
}
