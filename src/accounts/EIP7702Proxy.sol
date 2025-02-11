// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

    /// @dev For allowing the differentiation of the EOA and the proxy itself.
    uint256 internal immutable __self = uint256(uint160(address(this)));

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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor(address initialImplementation, address initialAdmin) payable {
        /// @solidity memory-safe-assembly
        assembly {
            sstore(_ERC1967_IMPLEMENTATION_SLOT, shr(96, shl(96, initialImplementation)))
            sstore(_ERC1967_ADMIN_SLOT, shr(96, shl(96, initialAdmin)))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          FALLBACK                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    fallback() external payable virtual {
        uint256 s = __self;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, returndatasize()) // Optimization trick to change `6040608052` into `3d604052`.
            // Workflow for calling on the proxy itself.
            // We cannot put these functions in the public ABI as this proxy must
            // fully forward all the calldata from EOAs pointing to this proxy.
            if iszero(xor(address(), s)) {
                if iszero(calldatasize()) {
                    mstore(calldatasize(), sload(_ERC1967_IMPLEMENTATION_SLOT))
                    return(calldatasize(), 0x20)
                }
                let fnSel := shr(224, calldataload(0x00))
                // `implementation()`.
                if eq(0x5c60da1b, fnSel) {
                    if staticcall(gas(), address(), calldatasize(), 0x00, 0x00, 0x20) {
                        return(0x00, returndatasize())
                    }
                }
                let admin := sload(_ERC1967_ADMIN_SLOT)
                // `admin()`.
                if eq(0xf851a440, fnSel) {
                    mstore(0x00, admin)
                    return(0x00, 0x20)
                }
                // Admin workflow.
                if eq(caller(), admin) {
                    let addr := shr(96, shl(96, calldataload(0x04)))
                    // `changeAdmin(address)`.
                    if eq(0x8f283970, fnSel) {
                        sstore(_ERC1967_ADMIN_SLOT, addr)
                        mstore(0x00, 1)
                        return(0x00, 0x20) // Store and return `true`.
                    }
                    // `upgrade(address)`.
                    if eq(0x0900f010, fnSel) {
                        sstore(_ERC1967_IMPLEMENTATION_SLOT, addr)
                        mstore(0x00, 1)
                        return(0x00, 0x20) // Store and return `true`.
                    }
                    // For minimalism, we shall skip events and calldata bounds checks.
                    // We don't need to forward any data to the new implementation.
                    // This "proxy" is actually close to an upgradeable beacon.
                }
                revert(returndatasize(), 0x00)
            }
            // Workflow for the EIP7702 authority (i.e. the EOA).
            // As the authority's storage may be polluted by previous delegations,
            // we should always fetch the latest implementation from the proxy.
            calldatacopy(0x00, 0x00, calldatasize()) // Forward calldata into the delegatecall.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    delegatecall(
                        gas(), mload(calldatasize()), 0x00, calldatasize(), calldatasize(), 0x00
                    ),
                    staticcall(gas(), s, calldatasize(), 0x00, calldatasize(), 0x20)
                )
            ) {
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }
            returndatacopy(0x00, 0x00, returndatasize())
            return(0x00, returndatasize())
        }
    }
}
