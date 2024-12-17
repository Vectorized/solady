// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC7821} from "./ERC7821.sol";
import {LibERC7579} from "./LibERC7579.sol";
import {EnumerableRoles} from "../auth/EnumerableRoles.sol";

/// @notice Simple timelock.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/Timelock.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol)
///
/// @dev Note:
/// - This implementation only supports ERC7821 style execution.
/// - This implementation uses EnumerableRoles for better auditability.
/// - This implementation uses custom errors with arguments for easier debugging.
/// - `executionData` can be encoded in three different ways:
///   1. `abi.encode(calls)`.
///   2. `abi.encode(calls, abi.encode(predecessor))`.
///   3. `abi.encode(calls, abi.encode(predecessor, salt))`.
/// - Where `calls` is of type `(address,uint256,bytes)[]`, and
///   `predecessor` is the id of the proposal that is required to be already executed.
/// - If `predecessor` is `bytes32(0)`, it will be ignored (treated as if not required).
/// - The optional `salt` allows for multiple proposals representing the same payload.
/// - The proposal id is given by:
///   `keccak256(abi.encode(mode, keccak256(executionData)))`.
///
/// Supported modes:
/// - `bytes32(0x01000000000000000000...)`: does not support optional `opData`.
/// - `bytes32(0x01000000000078210001...)`: supports optional `opData`.
/// Where `opData` is `abi.encode(predecessor)` or `abi.encode(predecessor, salt)`,
/// and `...` is the remaining 22 bytes which can be anything.
/// For ease of mind, just use:
/// `0x0100000000007821000100000000000000000000000000000000000000000000`.
contract Timelock is ERC7821, EnumerableRoles {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Role that can add / remove roles without wait time.
    /// This role cannot directly propose, execute, or cancel.
    /// This role is NOT exempt from the execution wait time.
    uint256 public constant ADMIN_ROLE = 0;

    /// @dev Role that can propose operations.
    uint256 public constant PROPOSER_ROLE = 1;

    /// @dev Role that can execute operations.
    uint256 public constant EXECUTOR_ROLE = 2;

    /// @dev Role that can cancel proposed operations.
    uint256 public constant CANCELLER_ROLE = 3;

    /// @dev The maximum role.
    uint256 public constant MAX_ROLE = 3;

    /// @dev Assign this holder to a role to allow anyone to call
    /// the function guarded by `onlyRoleOrOpenRole`.
    address public constant OPEN_ROLE_HOLDER = 0x0303030303030303030303030303030303030303;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ENUMS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Represents the state of an operation.
    enum OperationState {
        Unset, // 0.
        Waiting, // 1.
        Ready, // 2.
        Done // 3.

    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The proposed operation has insufficient delay.
    error TimelockInsufficientDelay(uint256 delay, uint256 minDelay);

    /// @dev The operation cannot be performed.
    /// The `expectedStates` is a bitmap with the bits enabled for
    /// each enum position, starting from the least significant bit.
    error TimelockInvalidOperation(bytes32 id, uint256 expectedStates);

    /// @dev The operation has an predecessor that has not been executed.
    error TimelockUnexecutedPredecessor(bytes32 predecessor);

    /// @dev Unauthorized to call the function.
    error TimelockUnauthorized();

    /// @dev The delay cannot be greater than `2 ** 254 - 1`.
    error TimelockDelayOverflow();

    /// @dev The timelock has already been initialized.
    error TimelockAlreadyInitialized();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage slot for the timelock's minimum delay.
    /// We restrict the `minDelay` to be less than `2 ** 254 - 1`, and store the negation of it.
    /// This allows us to check if it has been initialized via a non-zero check.
    /// Slot of operation `id` is given by:
    /// ```
    ///     mstore(0x09, _TIMELOCK_SLOT)
    ///     mstore(0x00, id)
    ///     let operationIdSlot := keccak256(0x00, 0x29)
    /// ```
    /// Bits layout:
    /// - [0]       `done`.
    /// - [1..255]  `readyTimestamp`.
    uint256 private constant _TIMELOCK_SLOT = 0x477f2812565c76a73f;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The proposal `id` has been created.
    event Proposed(bytes32 indexed id, bytes32 mode, bytes executionData, uint256 readyTimestamp);

    /// @dev The proposal `id` has been executed.
    event Executed(bytes32 indexed id, bytes32 mode, bytes executionData);

    /// @dev The proposal `id` has been cancelled.
    event Cancelled(bytes32 indexed id);

    /// @dev The minimum delay has been set to `newMinDelay`.
    event MinDelaySet(uint256 newMinDelay);

    /// @dev `keccak256(bytes("Proposed(bytes32,bytes32,bytes,uint256)"))`.
    uint256 private constant _PROPOSED_EVENT_SIGNATURE =
        0x9b40ebcd599cbeb62eedb5e0c1db0879688a09d169ab92dbed4957d49a44b671;

    /// @dev `keccak256(bytes("Executed(bytes32,bytes32,bytes)"))`.
    uint256 private constant _EXECUTED_EVENT_SIGNATURE =
        0xb1fdd61c3a5405a73ea1f8fb29bfd62c6152241cb59843d3def17bfadb7cb0bf;

    /// @dev `keccak256(bytes("Cancelled(bytes32)"))`.
    uint256 private constant _CANCELLED_EVENT_SIGNATURE =
        0xbaa1eb22f2a492ba1a5fea61b8df4d27c6c8b5f3971e63bb58fa14ff72eedb70;

    /// @dev `keccak256(bytes("MinDelaySet(uint256)"))`.
    uint256 private constant _MIN_DELAY_SET_EVENT_SIGNATURE =
        0x496c64b8781f4ad77f1c285beea54cc413b72276389ad6dd916ea2841395e63d;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        INITIALIZER                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the timelock contract.
    function initialize(
        uint256 initialMinDelay,
        address initialAdmin,
        address[] calldata proposers,
        address[] calldata executors,
        address[] calldata cancellers
    ) public virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if shr(254, initialMinDelay) {
                mstore(0x00, 0xd1efaf25) // `TimelockDelayOverflow()`.
                revert(0x1c, 0x04)
            }
            let s := _TIMELOCK_SLOT
            if sload(s) {
                mstore(0x00, 0xc44f149c) // `TimelockAlreadyInitialized()`.
                revert(0x1c, 0x04)
            }
            sstore(s, not(initialMinDelay))
        }
        if (initialAdmin != address(0)) {
            _setRole(initialAdmin, ADMIN_ROLE, true);
        }
        _bulkSetRole(proposers, PROPOSER_ROLE, true);
        _bulkSetRole(executors, EXECUTOR_ROLE, true);
        _bulkSetRole(cancellers, CANCELLER_ROLE, true);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Proposes an execute payload (`mode`, `executionData`) with `delay`.
    /// Emits a {Proposed} event.
    function propose(bytes32 mode, bytes calldata executionData, uint256 delay)
        public
        virtual
        onlyRole(PROPOSER_ROLE)
        returns (bytes32 id)
    {
        LibERC7579.decodeBatchAndOpData(executionData); // Check if properly encoded.
        uint256 t = minDelay();
        /// @solidity memory-safe-assembly
        assembly {
            if shr(254, delay) {
                mstore(0x00, 0xd1efaf25) // `TimelockDelayOverflow()`.
                revert(0x1c, 0x04)
            }
            if lt(delay, t) {
                mstore(0x00, 0x54336609) // `TimelockInsufficientDelay(uint256,uint256)`.
                mstore(0x20, delay)
                mstore(0x40, t)
                revert(0x1c, 0x44)
            }
            let m := mload(0x40)
            calldatacopy(add(m, 0x80), executionData.offset, executionData.length)
            mstore(0x00, mode)
            mstore(0x20, keccak256(add(m, 0x80), executionData.length))
            id := keccak256(0x00, 0x40)
            mstore(0x09, _TIMELOCK_SLOT)
            mstore(0x00, id)
            let s := keccak256(0x00, 0x29) // Operation slot.
            if sload(s) {
                mstore(0x00, 0xd639b0bf) // `TimelockInvalidOperation(bytes32,uint256)`.
                mstore(0x20, id)
                mstore(0x40, 1) // `1 << OperationState.Unset`
                revert(0x1c, 0x44)
            }
            // Emits the {Proposed} event.
            mstore(m, mode)
            mstore(add(m, 0x20), 0x60)
            let r := add(delay, timestamp()) // `readyTimestamp`.
            sstore(s, shl(1, r)) // Update the operation in the storage.
            mstore(add(m, 0x40), r)
            mstore(add(m, 0x60), executionData.length)
            // Some indexers require the bytes to be zero-right padded.
            mstore(add(add(m, 0x80), executionData.length), 0) // Zeroize the slot after the end.
            // forgefmt: disable-next-item
            log2(m, add(0x80, and(not(0x1f), add(0x1f, executionData.length))),
                _PROPOSED_EVENT_SIGNATURE, id)
        }
    }

    /// @dev Cancels the operation with `id`.
    /// Emits a {Cancelled} event.
    function cancel(bytes32 id) public virtual onlyRole(CANCELLER_ROLE) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x09, _TIMELOCK_SLOT)
            mstore(0x00, id)
            let s := keccak256(0x00, 0x29) // Operation slot.
            let p := sload(s)
            if or(and(1, p), iszero(p)) {
                mstore(0x00, 0xd639b0bf) // `TimelockInvalidOperation(bytes32,uint256)`.
                mstore(0x20, id)
                mstore(0x40, 6) // `(1 << OperationState.Waiting) | (1 << OperationState.Ready)`
                revert(0x1c, 0x44)
            }
            sstore(s, 0) // Clears the operation's storage slot.
            // Emits the {Cancelled} event.
            log2(0x00, 0x00, _CANCELLED_EVENT_SIGNATURE, id)
        }
    }

    /// @dev Allows the timelock itself to set the minimum delay.
    /// Emits a {MinDelaySet} event.
    function setMinDelay(uint256 newMinDelay) public virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(eq(caller(), address())) {
                mstore(0x00, 0x55140ae8) // `TimelockUnauthorized()`.
                revert(0x1c, 0x04)
            }
            if shr(254, newMinDelay) {
                mstore(0x00, 0xd1efaf25) // `TimelockDelayOverflow()`.
                revert(0x1c, 0x04)
            }
            sstore(_TIMELOCK_SLOT, not(newMinDelay))
            // Emits the {SetMinDelay} event.
            mstore(0x00, newMinDelay)
            log1(0x00, 0x20, _MIN_DELAY_SET_EVENT_SIGNATURE)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC VIEW FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the minimum delay.
    function minDelay() public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := not(sload(_TIMELOCK_SLOT))
        }
    }

    /// @dev Returns the ready timestamp for `id`.
    function readyTimestamp(bytes32 id) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x09, _TIMELOCK_SLOT)
            mstore(0x00, id)
            result := shr(1, sload(keccak256(0x00, 0x29)))
        }
    }

    /// @dev Returns the current operation state of `id`.
    function operationState(bytes32 id) public view virtual returns (OperationState result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x09, _TIMELOCK_SLOT)
            mstore(0x00, id)
            result := sload(keccak256(0x00, 0x29))
            // forgefmt: disable-next-item
            result := mul(iszero(iszero(result)),
                add(and(result, 1), sub(2, lt(timestamp(), shr(1, result)))))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INTERNAL HELPERS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Helper to set roles in bulk.
    function _bulkSetRole(address[] calldata addresses, uint256 role, bool active)
        internal
        virtual
    {
        for (uint256 i; i != addresses.length;) {
            address a;
            /// @solidity memory-safe-assembly
            assembly {
                a := calldataload(add(addresses.offset, shl(5, i)))
                i := add(i, 1)
            }
            _setRole(a, role, active);
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OVERRIDES                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev For ERC7821.
    /// To ensure that the function can only be called by the proper role holder.
    /// To ensure that the operation is ready to be executed.
    /// Updates the operation state and emits a {Executed} event after the calls.
    function _execute(
        bytes32 mode,
        bytes calldata executionData,
        Call[] calldata calls,
        bytes calldata opData
    ) internal virtual override(ERC7821) {
        if (!_hasRole(OPEN_ROLE_HOLDER, EXECUTOR_ROLE)) _checkRole(EXECUTOR_ROLE);
        bytes32 id;
        uint256 s;
        /// @solidity memory-safe-assembly
        assembly {
            // Copies the `executionData` for the event and to compute the `id`.
            calldatacopy(mload(0x40), executionData.offset, executionData.length)
            mstore(0x00, mode)
            mstore(0x20, keccak256(mload(0x40), executionData.length))
            id := keccak256(0x00, 0x40)
            mstore(0x09, _TIMELOCK_SLOT)
            mstore(0x00, id)
            s := keccak256(0x00, 0x29)
            let p := sload(s)
            if or(or(and(1, p), iszero(p)), lt(timestamp(), shr(1, p))) {
                mstore(0x00, 0xd639b0bf) // `TimelockInvalidOperation(bytes32,uint256)`.
                mstore(0x20, id)
                mstore(0x40, 4) // `1 << OperationState.Ready`
                revert(0x1c, 0x44)
            }
            // Check if optional predecessor has been executed.
            if iszero(lt(opData.length, 0x20)) {
                let b := calldataload(opData.offset) // Predecessor's id.
                mstore(0x00, b) // `_TIMELOCK_SLOT` is already at `0x09`.
                if iszero(or(iszero(b), and(1, sload(keccak256(0x00, 0x29))))) {
                    mstore(0x00, 0x90a9a618) // `TimelockUnexecutedPredecessor(bytes32)`.
                    mstore(0x20, b)
                    revert(0x1c, 0x24)
                }
            }
        }
        _execute(calls, id);
        /// @solidity memory-safe-assembly
        assembly {
            // Recheck the operation after the calls, in case of reentrancy.
            let p := sload(s)
            if or(or(and(1, p), iszero(p)), lt(timestamp(), shr(1, p))) {
                mstore(0x00, 0xd639b0bf) // `TimelockInvalidOperation(bytes32,uint256)`.
                mstore(0x20, id)
                mstore(0x40, 4) // `1 << OperationState.Ready`
                revert(0x1c, 0x44)
            }
            let m := mload(0x40)
            // Copies the `executionData` for the event.
            calldatacopy(add(m, 0x60), executionData.offset, executionData.length)
            // Emits the {Executed} event.
            mstore(m, mode)
            mstore(add(m, 0x20), 0x40)
            mstore(add(m, 0x40), executionData.length)
            // Some indexers require the bytes to be zero-right padded.
            mstore(add(add(m, 0x60), executionData.length), 0) // Zeroize the slot after the end.
            // forgefmt: disable-next-item
            log2(m, add(0x60, and(not(0x1f), add(0x1f, executionData.length))),
                _EXECUTED_EVENT_SIGNATURE, id)
            sstore(s, or(1, p)) // Set the operation as executed in the storage.
        }
    }

    /// @dev This guards the public `setRole` function,
    /// such that it can only be called by the timelock itself, or an admin.
    function _authorizeSetRole(address, uint256, bool) internal virtual override(EnumerableRoles) {
        if (msg.sender != address(this)) _checkRole(ADMIN_ROLE);
    }
}
