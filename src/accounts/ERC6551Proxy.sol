// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple ERC6551 account proxy implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC6551Proxy.sol)
/// @author ERC6551 team (https://github.com/erc6551/reference/blob/main/src/examples/upgradeable/ERC6551AccountProxy.sol)
contract ERC6551Proxy {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         IMMUTABLES                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The default implementation.
    address internal immutable _defaultImplementation;

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
        _defaultImplementation = defaultImplementation;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          FALLBACK                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    fallback() external payable {
        address d = _defaultImplementation;
        assembly {
            calldatacopy(returndatasize(), returndatasize(), calldatasize())
            let s := sload(_ERC1967_IMPLEMENTATION_SLOT)
            // Forwards the `data` to `delegate` via delegatecall.
            // forgefmt: disable-next-item
            s := delegatecall(gas(), or(s, mul(d, iszero(shl(96, s)))),
                returndatasize(), calldatasize(), codesize(), returndatasize())
            returndatacopy(0x00, 0x00, returndatasize())
            if iszero(s) { revert(0x00, returndatasize()) }
            return(0x00, returndatasize())
        }
    }
}
