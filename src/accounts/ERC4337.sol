// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import {Receiver} from "./Receiver.sol";

/// @notice Simple ERC4337 account implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC4337.sol)
/// @author Infinitism (https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/samples/SimpleAccount.sol)
abstract contract ERC4337Account { /*is Receiver*/
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Canonical ERC4337 entry point contract. May be updated through overrides.
    address internal constant _ENTRY_POINT = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    /// @dev If signature recovery fails return number 1.
    uint256 internal constant _SIG_VALIDATION_FAILED = 1;

    /// @dev Op structure.
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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Fetches 'clones with immutable arguments' owner hashed.
    function _getOwner() internal view virtual returns (bytes32 o) {
        /// @solidity memory-safe-assembly
        assembly {
            o :=
                calldataload(
                    add(sub(calldatasize(), shr(240, calldataload(sub(calldatasize(), 2)))), 0x20)
                )
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONs                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the canonical ERC4337 entry point contract.
    /// Override this function to return a different entry point.
    function entryPoint() public pure virtual returns (address) {
        return _ENTRY_POINT;
    }

    /// @dev Returns the owner of this account's operations.
    /// Override this function to return a different owner.
    function owner() public view virtual returns (address) {
        return address(uint160(uint256(_getOwner())));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*            VALIDATE USER SIGNATURE FUNCTION                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev ERC1271 contract signature validation logic.
    function isValidSignature(bytes32 hash, bytes calldata signature)
        public
        view
        virtual
        returns (bytes4 isValid)
    {
        bytes32 user = _getOwner(); // Pull operation owner onto stack.
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, hash)
            mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
            calldatacopy(0x40, signature.offset, 0x40) // Copy `r` and `s`.
            if eq(user, mload(staticcall(gas(), 1, 0, 0x80, 0x01, 0x20))) { isValid := 0x1626ba7e }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*            VALIDATE USER OPERATION FUNCTION                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Validates a user signature for execute operation.
    /// Entry point will proceed only if validation succeeds.
    /// Signature failure returns `_SIG_VALIDATION_FAILED`.
    /// Other failures (e.g., nonce mismatch) will revert.
    ///
    /// Params:
    /// - userOp: Operation for user execution.
    /// - userOpHash: Hashed user operation.
    /// - missingAccountFunds: Relay funds.
    ///
    /// Returns:
    /// - validationData: `0` on success.
    /// `_SIG_VALIDATION_FAILED` on fail.
    /// Override to customize validation.
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) public payable virtual returns (uint256 validationData) {
        bytes calldata signature = userOp.signature; // Memo signature.
        address entryPt = entryPoint(); // Pull entry point onto stack.
        bytes32 user = _getOwner(); // Pull operation owner onto stack.
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the entry point, revert.
            if xor(caller(), entryPt) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, userOpHash)
            mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
            calldatacopy(0x40, signature.offset, 0x40) // Copy `r` and `s`.
            // If recovered public key is not the owner, return number 1.
            if xor(user, mload(staticcall(gas(), 1, 0x00, 0x80, 0x01, 0x20))) {
                validationData := _SIG_VALIDATION_FAILED
            }
            mstore(0x40, m) // Restore the free memory pointer.
            // Refund the entry point if any relayer gas owed.
            if gt(missingAccountFunds, 0) {
                pop(call(gas(), caller(), missingAccountFunds, 0x00, 0x00, 0x00, 0x00))
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*             EXECUTE USER OPERATION FUNCTION                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Execute call operation from this account. Only the owner or entry point may call.
    function execute(address to, uint256 value, bytes calldata data) public payable virtual {
        address entryPt = entryPoint(); // Pull entry point onto stack.
        bytes32 user = _getOwner(); // Pull operation owner onto stack.
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is neither entry point nor user, revert.
            if and(xor(caller(), entryPt), xor(caller(), user)) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
            calldatacopy(0, data.offset, data.length)
            let success := call(gas(), to, value, 0x00, data.length, 0x00, 0x00)
            returndatacopy(0x00, 0x00, returndatasize())
            if iszero(success) { revert(0x00, returndatasize()) }
            return(0x00, returndatasize())
        }
    }
}
