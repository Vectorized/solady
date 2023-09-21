// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice EIP-4337 Account Abstraction Base Contract
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/EIP4337.sol)
/// @author Infinitism (https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/core/BaseAccount.sol)
abstract contract EIP4337Account {
    address internal immutable _ENTRY_POINT;
    uint256 internal constant _SIG_VALIDATION_FAILED = 1;

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

    error Unauthorized();

    constructor(address _entryPoint) {
        _ENTRY_POINT = _entryPoint;
    }

    /// @notice Get current entryPoint address.
    function entryPoint() public view virtual returns (address) {
        return _ENTRY_POINT;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*            VALIDATE USER OPERATION FUNCTION                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Validates user's signature and nonce for an operation.
    // Entry point will proceed only if validation succeeds.
    // Signature failure returns _SIG_VALIDATION_FAILED (1).
    // Other failures (e.g., nonce mismatch) should revert.
    //
    // Params:
    // - userOp: Operation to be executed.
    // - userOpHash: Hash of request data for signature.
    // - missingAccountFunds: Funds needed for the sender to proceed.
    //
    // Returns:
    // - validationData: Encoded ValidationData struct.
    //
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

    // Validate the signature against the hash of the request.
    // Returns encoded validation data.
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        virtual
        returns (uint256 validationData);

    // Validate the nonce for the operation.
    // Actual uniqueness is managed by the EntryPoint.
    function _validateNonce(uint256 nonce) internal view virtual {}
}
