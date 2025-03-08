// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Receiver} from "./Receiver.sol";
import {LibZip} from "../utils/LibZip.sol";
import {Ownable} from "../auth/Ownable.sol";
import {UUPSUpgradeable} from "../utils/UUPSUpgradeable.sol";
import {SignatureCheckerLib, ERC1271} from "../accounts/ERC1271.sol";

/// @notice Simple ERC4337 account implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC4337.sol)
/// @author Infinitism (https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/samples/SimpleAccount.sol)
///
/// @dev Recommended usage:
/// 1. Deploy the ERC4337 as an implementation contract, and verify it on Etherscan.
/// 2. Create a factory that uses `LibClone.deployERC1967` or
///    `LibClone.deployDeterministicERC1967` to clone the implementation.
///    See: `ERC4337Factory.sol`.
///
/// Note:
/// ERC4337 is a very complicated standard with many potential gotchas.
/// Also, it is subject to change and has not been finalized
/// (so accounts are encouraged to be upgradeable).
/// Usually, ERC4337 account implementations are developed by companies with ample funds
/// for security reviews. This implementation is intended to serve as a base reference
/// for smart account developers working in such companies. If you are using this
/// implementation, please do get one or more security reviews before deployment.
abstract contract ERC4337 is Ownable, UUPSUpgradeable, Receiver, ERC1271 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The packed ERC4337 user operation (userOp) struct.
    struct PackedUserOperation {
        address sender;
        uint256 nonce;
        bytes initCode; // Factory address and `factoryData` (or empty).
        bytes callData;
        bytes32 accountGasLimits; // `verificationGas` (16 bytes) and `callGas` (16 bytes).
        uint256 preVerificationGas;
        bytes32 gasFees; // `maxPriorityFee` (16 bytes) and `maxFeePerGas` (16 bytes).
        bytes paymasterAndData; // Paymaster fields (or empty).
        bytes signature;
    }

    /// @dev Call struct for the `executeBatch` function.
    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys this ERC4337 account implementation and disables initialization (see below).
    constructor() payable {
        _disableERC4337ImplementationInitializer();
    }

    /// @dev Automatically initializes the owner for the implementation. This blocks someone
    /// from initializing the implementation and doing a delegatecall to SELFDESTRUCT.
    /// Proxies to the implementation will still be able to initialize as per normal.
    function _disableERC4337ImplementationInitializer() internal virtual {
        // Note that `Ownable._guardInitializeOwner` has been and must be overridden
        // to return true, to block double-initialization. We'll initialize to `address(1)`,
        // so that it's easier to verify that the implementation has been initialized.
        _initializeOwner(address(1));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        INITIALIZER                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the account with the owner. Can only be called once.
    function initialize(address newOwner) public payable virtual {
        _initializeOwner(newOwner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        ENTRY POINT                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the canonical ERC4337 EntryPoint contract (0.7).
    /// Override this function to return a different EntryPoint.
    function entryPoint() public view virtual returns (address) {
        return 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   VALIDATION OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Validates the signature and nonce.
    /// The EntryPoint will make the call to the recipient only if
    /// this validation call returns successfully.
    ///
    /// Signature failure should be reported by returning 1 (see: `_validateSignature`).
    /// This allows making a "simulation call" without a valid signature.
    /// Other failures (e.g. nonce mismatch, or invalid signature format)
    /// should still revert to signal failure.
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        payable
        virtual
        onlyEntryPoint
        payPrefund(missingAccountFunds)
        returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);
        _validateNonce(userOp.nonce);
    }

    /// @dev Validate `userOp.signature` for the `userOpHash`.
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        virtual
        returns (uint256 validationData)
    {
        bool success = SignatureCheckerLib.isValidSignatureNowCalldata(
            owner(), SignatureCheckerLib.toEthSignedMessageHash(userOpHash), userOp.signature
        );
        /// @solidity memory-safe-assembly
        assembly {
            // Returns 0 if the recovered address matches the owner.
            // Else returns 1, which is equivalent to:
            // `(success ? 0 : 1) | (uint256(validUntil) << 160) | (uint256(validAfter) << (160 + 48))`
            // where `validUntil` is 0 (indefinite) and `validAfter` is 0.
            validationData := iszero(success)
        }
    }

    /// @dev Override to validate the nonce of the userOp.
    /// This method may validate the nonce requirement of this account.
    /// e.g.
    /// To limit the nonce to use sequenced userOps only (no "out of order" userOps):
    ///      `require(nonce < type(uint64).max)`
    /// For a hypothetical account that *requires* the nonce to be out-of-order:
    ///      `require(nonce & type(uint64).max == 0)`
    ///
    /// The actual nonce uniqueness is managed by the EntryPoint, and thus no other
    /// action is needed by the account itself.
    function _validateNonce(uint256 nonce) internal virtual {
        nonce = nonce; // Silence unused variable warning.
    }

    /// @dev Sends to the EntryPoint (i.e. `msg.sender`) the missing funds for this transaction.
    /// Subclass MAY override this modifier for better funds management.
    /// (e.g. send to the EntryPoint more than the minimum required, so that in future transactions
    /// it will not be required to send again)
    ///
    /// `missingAccountFunds` is the minimum value this modifier should send the EntryPoint,
    /// which MAY be zero, in case there is enough deposit, or the userOp has a paymaster.
    modifier payPrefund(uint256 missingAccountFunds) virtual {
        _;
        /// @solidity memory-safe-assembly
        assembly {
            if missingAccountFunds {
                // Ignore failure (it's EntryPoint's job to verify, not the account's).
                pop(call(gas(), caller(), missingAccountFunds, codesize(), 0x00, codesize(), 0x00))
            }
        }
    }

    /// @dev Requires that the caller is the EntryPoint.
    modifier onlyEntryPoint() virtual {
        if (msg.sender != entryPoint()) revert Unauthorized();
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    EXECUTION OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Execute a call from this account.
    function execute(address target, uint256 value, bytes calldata data)
        public
        payable
        virtual
        onlyEntryPointOrOwner
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            calldatacopy(result, data.offset, data.length)
            if iszero(call(gas(), target, value, result, data.length, codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    /// @dev Execute a sequence of calls from this account.
    function executeBatch(Call[] calldata calls)
        public
        payable
        virtual
        onlyEntryPointOrOwner
        returns (bytes[] memory results)
    {
        /// @solidity memory-safe-assembly
        assembly {
            results := mload(0x40)
            mstore(results, calls.length)
            let r := add(0x20, results)
            let m := add(r, shl(5, calls.length))
            calldatacopy(r, calls.offset, shl(5, calls.length))
            for { let end := m } iszero(eq(r, end)) { r := add(r, 0x20) } {
                let e := add(calls.offset, mload(r))
                let o := add(e, calldataload(add(e, 0x40)))
                calldatacopy(m, add(o, 0x20), calldataload(o))
                // forgefmt: disable-next-item
                if iszero(call(gas(), calldataload(e), calldataload(add(e, 0x20)),
                    m, calldataload(o), codesize(), 0x00)) {
                    // Bubble up the revert if the call reverts.
                    returndatacopy(m, 0x00, returndatasize())
                    revert(m, returndatasize())
                }
                mstore(r, m) // Append `m` into `results`.
                mstore(m, returndatasize()) // Store the length,
                let p := add(m, 0x20)
                returndatacopy(p, 0x00, returndatasize()) // and copy the returndata.
                m := add(p, returndatasize()) // Advance `m`.
            }
            mstore(0x40, m) // Allocate the memory.
        }
    }

    /// @dev Execute a delegatecall with `delegate` on this account.
    function delegateExecute(address delegate, bytes calldata data)
        public
        payable
        virtual
        onlyEntryPointOrOwner
        delegateExecuteGuard
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            calldatacopy(result, data.offset, data.length)
            // Forwards the `data` to `delegate` via delegatecall.
            if iszero(delegatecall(gas(), delegate, result, data.length, codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    /// @dev Ensures that the owner and implementation slots' values aren't changed.
    /// You can override this modifier to ensure the sanctity of other storage slots too.
    modifier delegateExecuteGuard() virtual {
        bytes32 ownerSlotValue;
        bytes32 implementationSlotValue;
        /// @solidity memory-safe-assembly
        assembly {
            implementationSlotValue := sload(_ERC1967_IMPLEMENTATION_SLOT)
            ownerSlotValue := sload(_OWNER_SLOT)
        }
        _;
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(
                and(
                    eq(implementationSlotValue, sload(_ERC1967_IMPLEMENTATION_SLOT)),
                    eq(ownerSlotValue, sload(_OWNER_SLOT))
                )
            ) { revert(codesize(), 0x00) }
        }
    }

    /// @dev Requires that the caller is the EntryPoint, the owner, or the account itself.
    modifier onlyEntryPointOrOwner() virtual {
        if (msg.sender != entryPoint()) _checkOwner();
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 DIRECT STORAGE OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the raw storage value at `storageSlot`.
    function storageLoad(bytes32 storageSlot) public view virtual returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(storageSlot)
        }
    }

    /// @dev Writes the raw storage value at `storageSlot`.
    function storageStore(bytes32 storageSlot, bytes32 storageValue)
        public
        payable
        virtual
        onlyEntryPointOrOwner
        storageStoreGuard(storageSlot)
    {
        /// @solidity memory-safe-assembly
        assembly {
            sstore(storageSlot, storageValue)
        }
    }

    /// @dev Ensures that the `storageSlot` is prohibited for direct storage writes.
    /// You can override this modifier to ensure the sanctity of other storage slots too.
    modifier storageStoreGuard(bytes32 storageSlot) virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if or(eq(storageSlot, _OWNER_SLOT), eq(storageSlot, _ERC1967_IMPLEMENTATION_SLOT)) {
                revert(codesize(), 0x00)
            }
        }
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     DEPOSIT OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the account's balance on the EntryPoint.
    function getDeposit() public view virtual returns (uint256 result) {
        address ep = entryPoint();
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, address()) // Store the `account` argument.
            mstore(0x00, 0x70a08231) // `balanceOf(address)`.
            result :=
                mul( // Returns 0 if the EntryPoint does not exist.
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), ep, 0x1c, 0x24, 0x20, 0x20)
                    )
                )
        }
    }

    /// @dev Deposit more funds for this account in the EntryPoint.
    function addDeposit() public payable virtual {
        address ep = entryPoint();
        /// @solidity memory-safe-assembly
        assembly {
            // The EntryPoint has balance accounting logic in the `receive()` function, as defined in ERC-4337.
            // forgefmt: disable-next-item
            if iszero(mul(extcodesize(ep), call(gas(), ep, callvalue(), codesize(), 0x00, codesize(), 0x00))) {
                revert(codesize(), 0x00) // For gas estimation.
            }
        }
    }

    /// @dev Withdraw ETH from the account's deposit on the EntryPoint.
    function withdrawDepositTo(address to, uint256 amount) public payable virtual onlyOwner {
        address ep = entryPoint();
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x205c2878000000000000000000000000) // `withdrawTo(address,uint256)`.
            if iszero(mul(extcodesize(ep), call(gas(), ep, 0, 0x10, 0x44, codesize(), 0x00))) {
                returndatacopy(mload(0x40), 0x00, returndatasize())
                revert(mload(0x40), returndatasize())
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OVERRIDES                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Requires that the caller is the owner or the account itself.
    /// This override affects the `onlyOwner` modifier.
    function _checkOwner() internal view virtual override(Ownable) {
        if (msg.sender != owner()) if (msg.sender != address(this)) revert Unauthorized();
    }

    /// @dev To prevent double-initialization (reuses the owner storage slot for efficiency).
    function _guardInitializeOwner() internal pure virtual override(Ownable) returns (bool) {
        return true;
    }

    /// @dev Uses the `owner` as the ERC1271 signer.
    function _erc1271Signer() internal view virtual override(ERC1271) returns (address) {
        return owner();
    }

    /// @dev Allow the entry point to skip the ERC7739 nested typed data workflow.
    /// This is safe as the entry point already includes the smart account in the user op digest.
    function _erc1271CallerIsSafe() internal view virtual override(ERC1271) returns (bool) {
        return msg.sender == entryPoint() || ERC1271._erc1271CallerIsSafe();
    }

    /// @dev To ensure that only the owner or the account itself can upgrade the implementation.
    function _authorizeUpgrade(address) internal virtual override(UUPSUpgradeable) onlyOwner {}

    /// @dev If you don't need to use `LibZip.cdFallback`, override this function to return false.
    function _useLibZipCdFallback() internal view virtual returns (bool) {
        return true;
    }

    /// @dev Handle token callbacks. If no token callback is triggered,
    /// use `LibZip.cdFallback` for generalized calldata decompression.
    fallback() external payable virtual override(Receiver) receiverFallback {
        if (_useLibZipCdFallback()) {
            // Reverts with out-of-gas by recursing infinitely if the first 4 bytes
            // of the decompressed `msg.data` doesn't match any function selector.
            LibZip.cdFallback();
        } else {
            revert FnSelectorNotRecognized();
        }
    }
}
