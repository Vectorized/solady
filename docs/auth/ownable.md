# Ownable

Simple single owner authorization mixin.


<b>Note:</b>

This implementation does NOT auto-initialize the owner to `msg.sender`.
You MUST call the `_initializeOwner` in the constructor / initializer.

While the ownable portion follows
[EIP-173](https://eips.ethereum.org/EIPS/eip-173) for compatibility,
the nomenclature for the 2-step ownership handover may be unique to this codebase.



<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### Unauthorized()

```solidity
error Unauthorized()
```

The caller is not authorized to call the function.

### NewOwnerIsZeroAddress()

```solidity
error NewOwnerIsZeroAddress()
```

The `newOwner` cannot be the zero address.

### NoHandoverRequest()

```solidity
error NoHandoverRequest()
```

The `pendingOwner` does not have a valid handover request.

### AlreadyInitialized()

```solidity
error AlreadyInitialized()
```

Cannot double-initialize.

## Events

### OwnershipTransferred(address,address)

```solidity
event OwnershipTransferred(
    address indexed oldOwner, address indexed newOwner
)
```

The ownership is transferred from `oldOwner` to `newOwner`.   
This event is intentionally kept the same as OpenZeppelin's Ownable to be   
compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),   
despite it not being as lightweight as a single argument event.

### OwnershipHandoverRequested(address)

```solidity
event OwnershipHandoverRequested(address indexed pendingOwner)
```

An ownership handover to `pendingOwner` has been requested.

### OwnershipHandoverCanceled(address)

```solidity
event OwnershipHandoverCanceled(address indexed pendingOwner)
```

The ownership handover to `pendingOwner` has been canceled.

## Storage

### _OWNER_SLOT

```solidity
bytes32 internal constant _OWNER_SLOT =
    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff74873927
```

The owner slot is given by:   
`bytes32(~uint256(uint32(bytes4(keccak256("_OWNER_SLOT_NOT")))))`.   
It is intentionally chosen to be a high value   
to avoid collision with lower slots.   
The choice of manual storage layout is to enable compatibility   
with both regular and upgradeable contracts.

## Internal Functions

### _guardInitializeOwner()

```solidity
function _guardInitializeOwner()
    internal
    pure
    virtual
    returns (bool guard)
```

Override to return true to make `_initializeOwner` prevent double-initialization.

### _initializeOwner(address)

```solidity
function _initializeOwner(address newOwner) internal virtual
```

Initializes the owner directly without authorization guard.   
This function must be called upon initialization,   
regardless of whether the contract is upgradeable or not.   
This is to enable generalization to both regular and upgradeable contracts,   
and to save gas in case the initial owner is not the caller.   
For performance reasons, this function will not check if there   
is an existing owner.

### _setOwner(address)

```solidity
function _setOwner(address newOwner) internal virtual
```

Sets the owner directly without authorization guard.

### _checkOwner()

```solidity
function _checkOwner() internal view virtual
```

Throws if the sender is not the owner.

### _ownershipHandoverValidFor()

```solidity
function _ownershipHandoverValidFor()
    internal
    view
    virtual
    returns (uint64)
```

Returns how long a two-step ownership handover is valid for in seconds.   
Override to return a different value if needed.   
Made internal to conserve bytecode. Wrap it in a public function if needed.

## Public Update Functions

### transferOwnership(address)

```solidity
function transferOwnership(address newOwner)
    public
    payable
    virtual
    onlyOwner
```

Allows the owner to transfer the ownership to `newOwner`.

### renounceOwnership()

```solidity
function renounceOwnership() public payable virtual onlyOwner
```

Allows the owner to renounce their ownership.

### requestOwnershipHandover()

```solidity
function requestOwnershipHandover() public payable virtual
```

Request a two-step ownership handover to the caller.   
The request will automatically expire in 48 hours (172800 seconds) by default.

### cancelOwnershipHandover()

```solidity
function cancelOwnershipHandover() public payable virtual
```

Cancels the two-step ownership handover to the caller, if any.

### completeOwnershipHandover(address)

```solidity
function completeOwnershipHandover(address pendingOwner)
    public
    payable
    virtual
    onlyOwner
```

Allows the owner to complete the two-step ownership handover to `pendingOwner`.   
Reverts if there is no existing ownership handover requested by `pendingOwner`.

## Public Read Functions

### owner()

```solidity
function owner() public view virtual returns (address result)
```

Returns the owner of the contract.

### ownershipHandoverExpiresAt(address)

```solidity
function ownershipHandoverExpiresAt(address pendingOwner)
    public
    view
    virtual
    returns (uint256 result)
```

Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.

## Modifiers

### onlyOwner()

```solidity
modifier onlyOwner() virtual
```

Marks a function as only callable by the owner.