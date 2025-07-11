// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Relay proxy for upgradeable ERC6551 accounts.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC6551Proxy.sol)
/// @author ERC6551 team (https://github.com/erc6551/reference/blob/main/src/examples/upgradeable/ERC6551AccountProxy.sol)
///
/// @dev Note: This relay proxy is required for upgradeable ERC6551 accounts.
///
/// ERC6551 clone -> ERC6551Proxy (relay) -> ERC6551 account implementation.
///
/// This relay proxy also allows for correctly revealing the
/// "Read as Proxy" and "Write as Proxy" tabs on Etherscan.
///
/// After using the registry to deploy a ERC6551 clone pointing to this relay proxy,
/// users must send 0 ETH to the clone before clicking on "Is this a proxy?" on Etherscan.
/// Verification of this relay proxy on Etherscan is optional.
contract ERC6551Proxy {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         IMMUTABLES                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The default implementation.
    bytes32 internal immutable _defaultImplementation;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ERC-1967 storage slot for the implementation in the proxy.
    /// `uint256(keccak256("eip1967.proxy.implementation")) - 1`.
    bytes32 internal constant _ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor(address defaultImplementation) payable {
        _defaultImplementation = bytes32(uint256(uint160(defaultImplementation)));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          FALLBACK                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    fallback() external payable virtual {
        bytes32 implementation;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, returndatasize()) // Optimization trick to change `6080604052` into `3d604052`.
            implementation := sload(_ERC1967_IMPLEMENTATION_SLOT)
        }
        if (implementation == bytes32(0)) {
            implementation = _defaultImplementation;
            /// @solidity memory-safe-assembly
            assembly {
                // Only initialize if the calldatasize is zero, so that staticcalls to
                // functions (which will have 4-byte function selectors) won't revert.
                // Some users may be fine without Etherscan proxy detection and thus may
                // choose to not initialize the ERC1967 implementation slot.
                if iszero(calldatasize()) { sstore(_ERC1967_IMPLEMENTATION_SLOT, implementation) }
            }
        }
        /// @solidity memory-safe-assembly
        assembly {
            calldatacopy(returndatasize(), returndatasize(), calldatasize())
            // forgefmt: disable-next-item
            if iszero(delegatecall(gas(), implementation,
                returndatasize(), calldatasize(), codesize(), returndatasize())) {
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }
            returndatacopy(0x00, 0x00, returndatasize())
            return(0x00, returndatasize())
        }
    }
}
