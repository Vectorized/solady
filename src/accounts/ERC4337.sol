// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Receiver} from "./Receiver.sol";
import {Ownable} from "../auth/Ownable.sol";
import {UUPSUpgradeable} from "../utils/UUPSUpgradeable.sol";
import {LibZip} from "../utils/LibZip.sol";
import {ECDSA} from "../utils/ECDSA.sol";

/// @notice Simple ERC4337 account implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC4337.sol)
/// @author Infinitism (https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/samples/SimpleAccount.sol)
///
/// Recommended usage:
/// 1. Deploy the ERC4337 as an implementation contract, and verify it on Etherscan.
/// 2. Create a simple factory that uses `LibClone.deployERC1967` to clone the implementation,
contract ERC4337 is Ownable, UUPSUpgradeable, Receiver {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ERC4337 UserOperation struct.
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
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The lengths of the input arrays are not the same.
    error ArrayLengthsMismatch();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        INITIALIZER                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the account with the owner. Can only be called once.
    function initialize(address newOwner) public virtual {
        _initializeOwner(newOwner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        ENTRY POINT                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the canonical ERC4337 EntryPoint contract.
    /// Override this function to return a different EntryPoint.
    function entryPoint() public pure virtual returns (address) {
        return 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   VALIDATION OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Validate `userOp.signature` for the `userOpHash`.
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        virtual
        returns (uint256 validationData)
    {
        bool sigFailed = owner()
            != ECDSA.recoverCalldata(ECDSA.toEthSignedMessageHash(userOpHash), userOp.signature);
        /// @solidity memory-safe-assembly
        assembly {
            // Returns 0 if the recovered address matches the owner.
            // Else returns 1, which is equivalent to:
            // `(sigFailed ? 1 : 0) | (uint256(validUntil) << 160) | (uint256(validAfter) << (160 + 48))`.
            // where `validUntil` and `validAfter` are 0.
            validationData := iszero(iszero(sigFailed))
        }
    }

    /// @dev Override to validate the nonce of the UserOperation.
    /// This method may validate the nonce requirement of this account.
    /// e.g.
    /// To limit the nonce to use sequenced UserOperations only (no "out of order" UserOperations):
    ///      `require(nonce < type(uint64).max)`
    /// For a hypothetical account that *requires* the nonce to be out-of-order:
    ///      `require(nonce & type(uint64).max == 0)`
    ///
    /// The actual nonce uniqueness is managed by the EntryPoint, and thus no other
    /// action is needed by the account itself.
    function _validateNonce(uint256 nonce) internal virtual {
        nonce = nonce; // Silence unused variable warning.
    }

    /// @dev Sends to the EntryPoint (`msg.sender`) the missing funds for this transaction.
    /// subclass MAY override this method for better funds management
    /// (e.g. send to the EntryPoint more than the minimum required, so that in future transactions
    /// it will not be required to send again)
    ///
    /// `missingAccountFunds` is the minimum value this method should send the EntryPoint,
    /// which MAY be zero, in case there is enough deposit, or the userOp has a paymaster.
    function _payPrefund(uint256 missingAccountFunds) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if missingAccountFunds {
                // Ignore failure (its EntryPoint's job to verify, not the account's).
                pop(call(not(0), caller(), missingAccountFunds, codesize(), 0x00, codesize(), 0x00))
            }
        }
    }

    /// @dev Validates the signature and nonce.
    /// The EntryPoint will make the call to the recipient only if
    /// this validation call returns successfully.
    ///
    /// Signature failure should be reported by returning 1 (see: `_validateSignature`).
    /// This allows making a "simulation call" without a valid signature.
    /// Other failures (e.g. nonce mismatch, or invalid signature format)
    /// should still revert to signal failure.
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) public payable virtual onlyEntryPoint returns (uint256 validationData) {
        validationData = _validateSignature(userOp, userOpHash);
        _validateNonce(userOp.nonce);
        _payPrefund(missingAccountFunds);
    }

    /// @dev Requires that the caller is the EntryPoint.
    modifier onlyEntryPoint() virtual {
        if (msg.sender != entryPoint()) revert Unauthorized();
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 CALL EXECUTION OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Execute a call operation from this account.
    function execute(address target, uint256 value, bytes calldata data)
        public
        payable
        virtual
        onlyEntryPointOrOwner
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            calldatacopy(m, data.offset, data.length)
            if iszero(call(gas(), target, value, m, data.length, codesize(), 0x00)) {
                // Bubble up the revert if the delegatecall reverts.
                returndatacopy(m, 0x00, returndatasize())
                revert(m, returndatasize())
            }
        }
    }

    /// @dev Execute a sequence of call operations from this account.
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata data
    ) public payable virtual onlyEntryPointOrOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            if iszero(and(eq(targets.length, data.length),
                or(iszero(values.length), eq(values.length, data.length)))) {
                mstore(0x00, 0x3b800a46) // `ArrayLengthsMismatch()`.
                revert(0x1c, 0x04)
            }
            let end := add(targets.offset, shl(5, targets.length))
            if iszero(eq(targets.offset, end)) {
                let m := mload(0x40)
                // If `values` is empty, abuse out-of-bounds calldataload to get zero for values.
                let valuesOffsetDiff :=
                    or(shl(128, iszero(values.length)), sub(values.offset, targets.offset))
                let dataOffsetDiff := sub(data.offset, targets.offset)
                for {} 1 {} {
                    let o := add(data.offset, calldataload(add(targets.offset, dataOffsetDiff)))
                    calldatacopy(m, add(o, 0x20), calldataload(o))
                    if iszero(
                        call(
                            gas(), // Gas remaining.
                            calldataload(targets.offset), // Target.
                            calldataload(add(targets.offset, valuesOffsetDiff)), // Value.
                            m, // Start of input calldata.
                            calldataload(o), // Length of input calldata.
                            codesize(), // We will use `returndatasize` instead.
                            0x00 // We will use `returndatasize` instead.
                        )
                    ) {
                        // Bubble up the revert if the delegatecall reverts.
                        returndatacopy(m, 0x00, returndatasize())
                        revert(m, returndatasize())
                    }
                    targets.offset := add(targets.offset, 0x20)
                    if eq(targets.offset, end) { break }
                }
            }
        }
    }

    /// @dev Requires that the caller is the EntryPoint, or the owner, or the contract itself.
    modifier onlyEntryPointOrOwner() virtual {
        if (msg.sender != entryPoint()) _checkOwner();
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OVERRIDES                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Requires that the caller is the owner or the contract itself.
    /// This override affects the `onlyOwner` modifier.
    function _checkOwner() internal view virtual override(Ownable) {
        // Check that the caller is either the owner.
        if (msg.sender != owner()) {
            // Or the contract itself, such as when called via `execute`.
            if (msg.sender != address(this)) revert Unauthorized();
        }
    }

    /// @dev To prevent double-initialization.
    function _guardInitializeOwner() internal pure virtual override(Ownable) returns (bool) {
        return true;
    }

    /// @dev To ensure that only the owner can upgrade the implementation.
    function _authorizeUpgrade(address) internal virtual override(UUPSUpgradeable) onlyOwner {}

    /// @dev Handle token callbacks. If no token callback is triggered,
    /// use `LibZip.cdFallback` for generalized calldata decompression.
    fallback() external virtual override(Receiver) receiverFallback {
        LibZip.cdFallback();
    }
}
