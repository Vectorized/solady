// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple ERC6551 account proxy implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC6551Proxy.sol)
/// @author ERC6551 team (https://github.com/erc6551/reference/blob/main/src/examples/upgradeable/ERC6551AccountProxy.sol)
///
/// Note: This proxy is specially developed for use with ERC6551 upgradeable accounts,
/// such that it can show the "Read as Proxy" and "Write as Proxy" tabs on Etherscan.
contract ERC6551Proxy {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         IMMUTABLES                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The default implementation.
    uint256 internal immutable _defaultImplementation;

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
        _defaultImplementation = uint256(uint160(defaultImplementation));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          FALLBACK                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    fallback() external payable {
        uint256 d = _defaultImplementation;
        assembly {
            mstore(0x40, returndatasize())
            calldatacopy(returndatasize(), returndatasize(), calldatasize())
            let implementation := sload(_ERC1967_IMPLEMENTATION_SLOT)
            // If the implementation is zero, initialize it to the default.
            // This is required for Etherscan proxy detection.
            if iszero(implementation) {
                sstore(_ERC1967_IMPLEMENTATION_SLOT, d)
                implementation := d
            }
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
