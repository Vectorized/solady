// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC7821} from "./ERC7821.sol";
import {EnumerableRoles} from "../auth/EnumerableRoles.sol";

/// @notice Simple timelock.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/Timelock.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol)
contract Timelock is ERC7821, EnumerableRoles {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Role that can propose operations.
    uint256 public constant PROPOSER_ROLE = 0;

    /// @dev Role that can execute operations.
    uint256 public constant EXECUTOR_ROLE = 1;

    /// @dev Role that can cancel proposed operations.
    uint256 public constant CANCELLER_ROLE = 2;

    /// @dev The maximum role.
    uint256 public constant MAX_ROLE = 2;

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

    /// @dev The delay cannot be greater than `2**253 - 1`.
    error TimelockDelayOverflow();

    /// @dev The timelock has already been initialized.
    error TimelockAlreadyInitialized();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage slot for the timelock's minimum delay and the initialized flag.
    /// Bits layout:
    /// - [0]       `initialized`.
    /// - [1..254]  `minDelay`.
    /// The location of the `operationState[id]` is given by:
    /// `xor(shl(72, id), _TIMELOCK_SLOT)`.
    uint256 private constant _TIMELOCK_SLOT = 0x477f2812565c76a73f;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The proposal `id` has been created.
    event Proposed(bytes32 indexed id, bytes executionData, uint256 readyTimestamp);

    /// @dev The proposal `id` has been executed.
    event Executed(bytes32 indexed id, bytes executionData);

    /// @dev The proposal `id` has been cancelled.
    event Cancelled(bytes32 indexed id);

    /// @dev The minimum delay has been set to `newMinDelay`.
    event MinDelaySet(uint256 newMinDelay);

    /// @dev `keccak256(bytes("Proposed(bytes32,bytes,uint256)"))`.
    uint256 private constant _PROPOSED_EVENT_SIGNATURE =
        0xbebd4e757b91b0f4e9671796f940352b8ce72b4878d18387feb19859ae5c9e25;

    /// @dev `keccak256(bytes("Executed(bytes32,bytes)"))`.
    uint256 private constant _EXECUTED_EVENT_SIGNATURE =
        0xda66fcfe5711520a570ced34d4cdebbe652fe74713bf2bc9db4ba54357e5a96f;

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
        address[] calldata proposers,
        address[] calldata executors,
        address[] calldata cancellers
    ) public virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let s := _TIMELOCK_SLOT
            if and(sload(s), 1) {
                mstore(0x00, 0xc44f149c) // `TimelockAlreadyInitialized()`.
                revert(0x1c, 0x04)
            }
            if shr(253, initialMinDelay) {
                mstore(0x00, 0xd1efaf25) // `TimelockDelayOverflow()`.
                revert(0x1c, 0x04)
            }
            sstore(s, or(shl(1, initialMinDelay), 1))
        }
        _bulkSetRole(proposers, PROPOSER_ROLE, true);
        _bulkSetRole(executors, EXECUTOR_ROLE, true);
        _bulkSetRole(cancellers, CANCELLER_ROLE, true);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Proposes an `executionData` with `delay`.
    function propose(bytes calldata executionData, uint256 delay)
        public
        virtual
        onlyRole(PROPOSER_ROLE)
        returns (bytes32 id)
    {
        uint256 t = minDelay();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            calldatacopy(add(m, 0x60), executionData.offset, executionData.length)
            id := keccak256(add(m, 0x60), executionData.length)
            if lt(delay, t) {
                mstore(0x00, 0x54336609) // `TimelockInsufficientDelay(uint256,uint256)`.
                mstore(0x20, delay)
                mstore(0x40, t)
                revert(0x1c, 0x44)
            }
            if shr(253, delay) {
                mstore(0x00, 0xd1efaf25) // `TimelockDelayOverflow()`.
                revert(0x1c, 0x04)
            }
            let s := xor(shl(72, id), _TIMELOCK_SLOT)
            let p := sload(s)
            if p {
                mstore(0x00, 0xd639b0bf) // `TimelockInvalidOperation(bytes32,uint256)`.
                mstore(0x20, id)
                mstore(0x40, 1) // `1 << OperationState.Unset`
                revert(0x1c, 0x44)
            }
            mstore(m, 0x40)
            t := add(delay, timestamp())
            sstore(s, shl(1, t))
            mstore(add(m, 0x20), t)
            mstore(add(m, 0x40), executionData.length)
            log2(m, add(0x60, executionData.length), _PROPOSED_EVENT_SIGNATURE, id)
        }
    }

    /// @dev Cancels the operation with `id`.
    function cancel(bytes32 id) public virtual onlyRole(CANCELLER_ROLE) {
        /// @solidity memory-safe-assembly
        assembly {
            let s := xor(shl(72, id), _TIMELOCK_SLOT)
            let p := sload(s)
            if or(and(1, p), iszero(p)) {
                mstore(0x00, 0xd639b0bf) // `TimelockInvalidOperation(bytes32,uint256)`.
                mstore(0x20, id)
                mstore(0x40, 6) // `(1 << OperationState.Waiting) | (1 << OperationState.Ready)`
                revert(0x1c, 0x44)
            }
            sstore(s, 0)
            log2(0x00, 0x00, _CANCELLED_EVENT_SIGNATURE, id)
        }
    }

    /// @dev Allows the timelock itself to set the minimum delay.
    function setMinDelay(uint256 newMinDelay) public virtual onlyTimelock {
        /// @solidity memory-safe-assembly
        assembly {
            if shr(253, newMinDelay) {
                mstore(0x00, 0xd1efaf25) // `TimelockDelayOverflow()`.
                revert(0x1c, 0x04)
            }
            sstore(_TIMELOCK_SLOT, or(shl(1, newMinDelay), 1))
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
            result := shr(1, sload(_TIMELOCK_SLOT))
        }
    }

    /// @dev Returns the ready timestamp for `id`.
    function readyTimestamp(bytes32 id) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := shr(1, sload(xor(shl(72, id), _TIMELOCK_SLOT)))
        }
    }

    /// @dev Returns the current operation state of `id`.
    function operationState(bytes32 id) public view virtual returns (OperationState result) {
        /// @solidity memory-safe-assembly
        assembly {
            let p := sload(xor(shl(72, id), _TIMELOCK_SLOT))
            result :=
                mul(iszero(iszero(p)), or(mul(3, and(p, 1)), sub(2, lt(timestamp(), shr(1, p)))))
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
        uint256 j;
        uint256 n = addresses.length << 5;
        if (n != uint256(0)) {
            do {
                address a;
                /// @solidity memory-safe-assembly
                assembly {
                    a := calldataload(add(addresses.offset, j))
                    j := add(j, 0x20)
                }
                _setRole(a, role, active);
            } while (j != n);
        }
    }

    /// @dev Guards a function such that it can only be executed by the timelock itself.
    modifier onlyTimelock() virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(eq(caller(), address())) {
                mstore(0x00, 0x55140ae8) // ~TimelockUnauthorized()`.
                revert(0x1c, 0x04)
            }
        }
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OVERRIDES                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev For ERC7821.
    /// To ensure that the function can only be called by the proper role holder.
    /// To ensure that the operation is ready to be executed.
    /// For updating the operation state.
    function _execute(
        bytes32,
        bytes calldata executionData,
        Call[] calldata calls,
        bytes calldata opData
    ) internal virtual override(ERC7821) returns (bytes[] memory reuslts) {
        if (!_hasRole(OPEN_ROLE_HOLDER, EXECUTOR_ROLE)) _checkRole(EXECUTOR_ROLE);
        bytes32 id;
        uint256 s;
        /// @solidity memory-safe-assembly
        assembly {
            // Copies the `executionData` for the event and to compute the `id`.
            calldatacopy(mload(0x40), executionData.offset, executionData.length)
            id := keccak256(mload(0x40), executionData.length)
            s := xor(shl(72, id), _TIMELOCK_SLOT)
            let p := sload(s)
            if or(or(and(1, p), iszero(p)), lt(timestamp(), shr(1, p))) {
                mstore(0x00, 0xd639b0bf) // `TimelockInvalidOperation(bytes32,uint256)`.
                mstore(0x20, id)
                mstore(0x40, 4) // `1 << OperationState.Ready`
                revert(0x1c, 0x44)
            }
            // Check if optional predecessor has been executed.
            if iszero(lt(opData.length, 0x20)) {
                let predecessor := calldataload(opData.offset)
                if predecessor {
                    if iszero(and(1, sload(xor(shl(72, predecessor), _TIMELOCK_SLOT)))) {
                        mstore(0x00, 0x90a9a618) // `TimelockUnexecutedPredecessor(bytes32)`.
                        mstore(0x20, predecessor)
                        revert(0x1c, 0x24)
                    }
                }
            }
        }
        reuslts = _execute(calls, id);
        /// @solidity memory-safe-assembly
        assembly {
            let p := sload(s)
            if or(or(and(1, p), iszero(p)), lt(timestamp(), shr(1, p))) {
                mstore(0x00, 0xd639b0bf) // `TimelockInvalidOperation(bytes32,uint256)`.
                mstore(0x20, id)
                mstore(0x40, 4) // `1 << OperationState.Ready`
                revert(0x1c, 0x44)
            }
            let m := mload(0x40)
            // Copies the `executionData` for the event.
            calldatacopy(add(m, 0x40), executionData.offset, executionData.length)
            mstore(m, 0x20)
            mstore(add(m, 0x20), executionData.length)
            // Emits the {Executed} event. We will just do it here to save gas.
            log2(m, add(0x40, executionData.length), _EXECUTED_EVENT_SIGNATURE, id)
            sstore(s, or(1, p)) // Set the operation as executed in the storage.
        }
    }

    /// @dev This guards the public `setRole` function,
    /// such that it can only be called by the timelock itself.
    function _authorizeSetRole(address, uint256, bool)
        internal
        virtual
        override(EnumerableRoles)
        onlyTimelock
    {}
}
