# Timelock

Simple timelock.


<b>Note:</b>

- This implementation only supports ERC7821 style execution.
- This implementation uses EnumerableRoles for better auditability.
- This implementation uses custom errors with arguments for easier debugging.
- `executionData` can be encoded in three different ways&#58;
    1. `abi.encode(calls)`.
    2. `abi.encode(calls, abi.encode(predecessor))`.
    3. `abi.encode(calls, abi.encode(predecessor, salt))`.
- Where `calls` is of type `(address,uint256,bytes)[]`, and
`predecessor` is the id of the proposal that is required to be already executed.
- If `predecessor` is `bytes32(0)`, it will be ignored (treated as if not required).
- The optional `salt` allows for multiple proposals representing the same payload.
- The proposal id is given by&#58;
`keccak256(abi.encode(mode, keccak256(executionData)))`.

We recommended including the salt, even though it is optional for convenience.

<b>Supported modes:</b>
- `bytes32(0x01000000000000000000...)`&#58; does not support optional `opData`.
- `bytes32(0x01000000000078210001...)`&#58; supports optional `opData`.
Where `opData` is `abi.encode(predecessor)` or `abi.encode(predecessor, salt)`,
and `...` is the remaining 22 bytes which can be anything. For ease of mind, just use:
`0x0100000000007821000100000000000000000000000000000000000000000000`.

<b>Inherits:</b>  

- [`accounts/ERC7821.sol`](accounts/erc7821.md)  
- [`auth/EnumerableRoles.sol`](auth/enumerableroles.md)  


<!-- customintro:start --><!-- customintro:end -->

## Constants

### ADMIN_ROLE

```solidity
uint256 public constant ADMIN_ROLE = 0
```

Role that can add / remove roles without wait time.   
This role cannot directly propose, execute, or cancel.   
This role is NOT exempt from the execution wait time.

### PROPOSER_ROLE

```solidity
uint256 public constant PROPOSER_ROLE = 1
```

Role that can propose operations.

### EXECUTOR_ROLE

```solidity
uint256 public constant EXECUTOR_ROLE = 2
```

Role that can execute operations.

### CANCELLER_ROLE

```solidity
uint256 public constant CANCELLER_ROLE = 3
```

Role that can cancel proposed operations.

### MAX_ROLE

```solidity
uint256 public constant MAX_ROLE = 3
```

The maximum role.

### OPEN_ROLE_HOLDER

```solidity
address public constant OPEN_ROLE_HOLDER =
    0x0303030303030303030303030303030303030303
```

Assign this holder to a role to allow anyone to call   
the function guarded by `onlyRoleOrOpenRole`.

## Enums

### OperationState

```solidity
enum OperationState {
    Unset, // 0.
    Waiting, // 1.
    Ready, // 2.
    Done // 3.

}
```

Represents the state of an operation.

## Custom Errors

### TimelockInsufficientDelay(uint256,uint256)

```solidity
error TimelockInsufficientDelay(uint256 delay, uint256 minDelay)
```

The proposed operation has insufficient delay.

### TimelockInvalidOperation(bytes32,uint256)

```solidity
error TimelockInvalidOperation(bytes32 id, uint256 expectedStates)
```

The operation cannot be performed.   
The `expectedStates` is a bitmap with the bits enabled for   
each enum position, starting from the least significant bit.

### TimelockUnexecutedPredecessor(bytes32)

```solidity
error TimelockUnexecutedPredecessor(bytes32 predecessor)
```

The operation has an predecessor that has not been executed.

### TimelockUnauthorized()

```solidity
error TimelockUnauthorized()
```

Unauthorized to call the function.

### TimelockDelayOverflow()

```solidity
error TimelockDelayOverflow()
```

The delay cannot be greater than `2 ** 254 - 1`.

### TimelockAlreadyInitialized()

```solidity
error TimelockAlreadyInitialized()
```

The timelock has already been initialized.

## Initializer

### initialize(uint256,address,address[],address[],address[])

```solidity
function initialize(
    uint256 initialMinDelay,
    address initialAdmin,
    address[] calldata proposers,
    address[] calldata executors,
    address[] calldata cancellers
) public virtual
```

Initializes the timelock contract.

### _initializeTimelockAuthorizationCheck()

```solidity
function _initializeTimelockAuthorizationCheck() internal virtual
```

The Timelock is best used via a minimal proxy.   
But in case it is not, we want to guard `initialize` from frontrun griefing.   
Authorizing both `msg.sender` and `tx.origin` caters to the use case where   
the Timelock is being deployed via a factory (e.g. Nicks, CreateX).   
Always call `initialize` as soon as possible after deployment.   
In the rare case where `msg.sender` or `tx.origin` are untrusted   
and abused to frontrun, `initialize` will revert on reinitialization,   
so you will know that the deployment is compromised and must be discarded.

## Public Update Functions

### propose(bytes32,bytes,uint256)

```solidity
function propose(bytes32 mode, bytes calldata executionData, uint256 delay)
    public
    virtual
    onlyRole(PROPOSER_ROLE)
    returns (bytes32 id)
```

Proposes an execute payload (`mode`, `executionData`) with `delay`.   
Emits a {Proposed} event.

### cancel(bytes32)

```solidity
function cancel(bytes32 id) public virtual onlyRole(CANCELLER_ROLE)
```

Cancels the operation with `id`.   
Emits a {Cancelled} event.

### setMinDelay(uint256)

```solidity
function setMinDelay(uint256 newMinDelay) public virtual
```

Allows the timelock itself to set the minimum delay.   
Emits a {MinDelaySet} event.

## Public View Functions

### minDelay()

```solidity
function minDelay() public view virtual returns (uint256 result)
```

Returns the minimum delay.

### readyTimestamp(bytes32)

```solidity
function readyTimestamp(bytes32 id)
    public
    view
    virtual
    returns (uint256 result)
```

Returns the ready timestamp for `id`.

### operationState(bytes32)

```solidity
function operationState(bytes32 id)
    public
    view
    virtual
    returns (OperationState result)
```

Returns the current operation state of `id`.

## Internal Helpers

### _bulkSetRole(address[],uint256,bool)

```solidity
function _bulkSetRole(
    address[] calldata addresses,
    uint256 role,
    bool active
) internal virtual
```

Helper to set roles in bulk.

## Overrides

### _execute(bytes32,bytes,Call[],bytes)

```solidity
function _execute(
    bytes32 mode,
    bytes calldata executionData,
    Call[] calldata calls,
    bytes calldata opData
) internal virtual override(ERC7821)
```

For ERC7821.   
To ensure that the function can only be called by the proper role holder.   
To ensure that the operation is ready to be executed.   
Updates the operation state and emits a {Executed} event after the calls.

### _authorizeSetRole(address,uint256,bool)

```solidity
function _authorizeSetRole(address, uint256, bool)
    internal
    virtual
    override(EnumerableRoles)
```

This guards the public `setRole` function,   
such that it can only be called by the timelock itself, or an admin.