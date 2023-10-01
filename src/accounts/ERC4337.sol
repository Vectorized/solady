// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import {Receiver} from "./Receiver.sol";
import {LibZip} from "../utils/LibZip.sol";

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

    /// @dev Fetches 'clones with immutable arguments' user as hash.
    /// This implementation is opinionated to single-user-ownership.
    /// Contract accounts can be set to divide operational concerns.
    function _getUser() internal pure virtual returns (bytes32 user) {
        /// @solidity memory-safe-assembly
        assembly {
            user :=
                calldataload(
                    add(sub(calldatasize(), shr(0xF0, calldataload(sub(calldatasize(), 0x2)))), 0x20)
                )
        }
    }

    /// @dev Returns the canonical ERC4337 entry point contract.
    /// Override this function to return a different entry point.
    function _entryPoint() internal pure virtual returns (address) {
        return _ENTRY_POINT;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*            VALIDATE USER SIGNATURE FUNCTION                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Validates the user signature via ERC1271 contract method.
    function isValidSignature(bytes32 hash, bytes calldata signature)
        public
        view
        virtual
        returns (bytes4 isValid)
    {
        bytes32 user = _getUser(); // Pull operation owner onto stack.
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            if eq(signature.length, 65) {
                mstore(0x00, hash)
                mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
                calldatacopy(0x40, signature.offset, 0x40) // Copy `r` and `s`.
                if eq(user, mload(staticcall(gas(), 1, 0, 0x80, 0x01, 0x20))) {
                    mstore(0x60, 0) // Restore the zero slot.
                    mstore(0x40, m) // Restore the free memory pointer.
                    mstore(0x20, 0x1626ba7e) // Store magic value.
                    return(0x3C, 0x20) // Return magic value.
                }
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.

            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), signature.length)
            // Copy the `signature` over.
            calldatacopy(add(m, 0x64), signature.offset, signature.length)
            // forgefmt: disable-next-item
            if and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    user, // The `user` signer address.
                    m, // Offset of calldata in memory.
                    add(signature.length, 0x64), // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            ) { isValid := 0x1626ba7e }
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
        bytes calldata signature = userOp.signature; // Memo the user signature.
        address entryPt = _entryPoint(); // Pull the entry point onto stack.
        bytes32 user = _getUser(); // Pull the user onto stack.
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the entry point, revert.
            if xor(caller(), entryPt) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
            let m := mload(0x40) // Cache the free memory pointer.
            if eq(signature.length, 65) {
                mstore(0x00, userOpHash)
                mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
                calldatacopy(0x40, signature.offset, 0x40) // Copy `r` and `s`.
                // If the recovered public key is not the user, return number 1.
                if xor(user, mload(staticcall(gas(), 1, 0x00, 0x80, 0x01, 0x20))) {
                    validationData := _SIG_VALIDATION_FAILED
                }
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.

            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), userOpHash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), signature.length)
            // Copy the `signature` over.
            calldatacopy(add(m, 0x64), signature.offset, signature.length)
            // forgefmt: disable-next-item
            if iszero(and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    user, // The `user` signer address.
                    m, // Offset of calldata in memory.
                    add(signature.length, 0x64), // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )) { validationData := _SIG_VALIDATION_FAILED }

            // Refund the entry point if any relayer gas owed.
            if gt(missingAccountFunds, 0) {
                pop(call(gas(), caller(), missingAccountFunds, 0x00, 0x00, 0x00, 0x00))
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*             EXECUTE USER OPERATION FUNCTION                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Execute call operation from this account. Only the user or entry point may call.
    function execute(address to, uint256 value, bytes calldata data) public payable virtual {
        address entryPt = _entryPoint(); // Pull the entry point onto stack.
        bytes32 user = _getUser(); // Pull the user onto stack.
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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      FALLBACK FUNCTION                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Handle token callbacks in Receiver
    /// and then LibZip for data compression.
    fallback() external /*override*/ virtual {
        //super.fallback();
        LibZip.cdFallback();
    }
}
