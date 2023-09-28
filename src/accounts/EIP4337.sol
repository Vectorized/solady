// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice EIP-4337 Account Abstraction Base Contract.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/EIP4337.sol)
/// @author Infinitism (https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/core/BaseAccount.sol)
abstract contract EIP4337Account {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    uint256 internal constant _SIG_VALIDATION_FAILED = 1;

    address internal immutable _ENTRY_POINT;

    struct UserOperation {
        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        bytes signature;
    }

    constructor(address _entryPoint) {
        _ENTRY_POINT = _entryPoint;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Validate the signature against the hash of the request.
    /// Returns encoded validation data.
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        virtual
        returns (uint256 validationData);

    /// @dev Validate the nonce for the operation.
    /// Actual uniqueness is managed by the EntryPoint.
    function _validateNonce(uint256 nonce) internal view virtual {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTION                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Get the entry point singleton contract address.
    function entryPoint() public view virtual returns (address) {
        return _ENTRY_POINT;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*            VALIDATE USER OPERATION FUNCTION                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Validates a signature and nonce for an operation.
    /// Entry point will proceed only if validation succeeds.
    /// Signature failure returns `_SIG_VALIDATION_FAILED`.
    /// Other failures (e.g., nonce mismatch) will revert.
    ///
    /// Params:
    /// - userOp: Operation to be executed.
    /// - userOpHash: Hash of request data.
    /// - missingAccountFunds: Relay funds.
    ///
    /// Returns:
    /// - validationData: Encoded ValidationData struct.
    ///
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) public virtual returns (uint256 validationData) {
        if (msg.sender != _ENTRY_POINT) revert Unauthorized();

        validationData = _validateSignature(userOp, userOpHash);

        _validateNonce(userOp.nonce);

        if (missingAccountFunds != 0) {
            assembly {
                pop(call(gas(), caller(), missingAccountFunds, 0x00, 0x00, 0x00, 0x00))
            }
        }
    }
}
