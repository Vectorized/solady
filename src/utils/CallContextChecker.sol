// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Call context checker mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/CallContextChecker.sol)
contract CallContextChecker {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The call is from an unauthorized call context.
    error UnauthorizedCallContext();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         IMMUTABLES                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev For checking if the context is a delegate call.
    ///
    /// Note: To enable use cases with an immutable default implementation in the bytecode,
    /// (see: ERC6551Proxy), we don't require that the proxy address must match the
    /// value stored in the implementation slot, which may not be initialized.
    uint256 private immutable __self = uint256(uint160(address(this)));

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    CALL CONTEXT CHECKS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // A proxy call can be either via a `delegatecall` to an implementation,
    // or a 7702 call on an authority that points to a delegation.

    /// @dev Returns whether the current call context is on a EIP7702 authority
    /// (i.e. externally owned account).
    function _onEIP7702Authority() internal view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            extcodecopy(address(), 0x00, 0x00, 0x20)
            // Note: Checking that it starts with hex"ef01" is the most general and futureproof.
            // 7702 bytecode is `abi.encodePacked(hex"ef01", uint8(version), address(delegation))`.
            result := eq(0xef01, shr(240, mload(0x00)))
        }
    }

    /// @dev Returns the implementation of this contract.
    function _selfImplementation() internal view virtual returns (address) {
        return address(uint160(__self));
    }

    /// @dev Returns whether the current call context is on the implementation itself.
    function _onImplementation() internal view virtual returns (bool) {
        return __self == uint160(address(this));
    }

    /// @dev Requires that the current call context is performed via a EIP7702 authority.
    function _checkOnlyEIP7702Authority() internal view virtual {
        if (!_onEIP7702Authority()) _revertUnauthorizedCallContext();
    }

    /// @dev Requires that the current call context is performed via a proxy.
    function _checkOnlyProxy() internal view virtual {
        if (_onImplementation()) _revertUnauthorizedCallContext();
    }

    /// @dev Requires that the current call context is NOT performed via a proxy.
    /// This is the opposite of `checkOnlyProxy`.
    function _checkNotDelegated() internal view virtual {
        if (!_onImplementation()) _revertUnauthorizedCallContext();
    }

    /// @dev Requires that the current call context is performed via a EIP7702 authority.
    modifier onlyEIP7702Authority() virtual {
        _checkOnlyEIP7702Authority();
        _;
    }

    /// @dev Requires that the current call context is performed via a proxy.
    modifier onlyProxy() virtual {
        _checkOnlyProxy();
        _;
    }

    /// @dev Requires that the current call context is NOT performed via a proxy.
    /// This is the opposite of `onlyProxy`.
    modifier notDelegated() virtual {
        _checkNotDelegated();
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _revertUnauthorizedCallContext() private pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x9f03a026) // `UnauthorizedCallContext()`.
            revert(0x1c, 0x04)
        }
    }
}
