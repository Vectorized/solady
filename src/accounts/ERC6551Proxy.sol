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

    /// @dev A very optimized proxy fallback function.
    /// Runtime gas cost is very near the optimal bytecode proxy (maybe about 15 gas more).
    fallback() external payable {
        assembly {
            mstore(0x40, returndatasize())
            calldatacopy(returndatasize(), returndatasize(), calldatasize())
        }
        uint256 d = _defaultImplementation;
        assembly {
            let s := sload(_ERC1967_IMPLEMENTATION_SLOT)
            d := or(shr(shl(96, s), d), s)
            // forgefmt: disable-next-item
            if iszero(delegatecall(gas(), d,
                returndatasize(), calldatasize(), codesize(), returndatasize())) { 
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize()) 
            }
            returndatacopy(0x00, 0x00, returndatasize())
            return(0x00, returndatasize())
        }
    }
}
