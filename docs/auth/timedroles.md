# TimedRoles

Timed multiroles authorization mixin.


<b>Note:</b>

This implementation is agnostic to the Ownable that the contract inherits from.
It performs a self-staticcall to the `owner()` function to determine the owner.
This is useful for situations where the contract inherits from
OpenZeppelin's Ownable, such as in LayerZero's OApp contracts.

This implementation performs a self-staticcall to `MAX_TIMED_ROLE()` to determine
the maximum timed role that can be set/unset. If the inheriting contract does not
have `MAX_TIMED_ROLE()`, then any timed role can be set/unset.

This implementation allows for any uint256 role,
it does NOT take in a bitmask of roles.
This is to accommodate teams that are allergic to bitwise flags.

By default, the `owner()` is the only account that is authorized to set timed roles.
This behavior can be changed via overrides.

This implementation is compatible with any Ownable.
This implementation is NOT compatible with OwnableRoles.

As timed roles can turn active or inactive anytime, enumeration is omitted here.
Querying the number of active timed roles will cost `O(n)` instead of `O(1)`.

Names are deliberately prefixed with "Timed", so that this contract
can be used in conjunction with EnumerableRoles without collisions.



<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### TimedRoleHolderIsZeroAddress()

```solidity
error TimedRoleHolderIsZeroAddress()
```

Cannot set the timed role of the zero address.

### InvalidTimedRole()

```solidity
error InvalidTimedRole()
```

The timed role has exceeded the maximum timed role.

### TimedRolesUnauthorized()

```solidity
error TimedRolesUnauthorized()
```

Unauthorized to perform the action.

### InvalidTimedRoleRange()

```solidity
error InvalidTimedRoleRange()
```

The `expires` cannot be less than the `start`.

## Public Update Functions

### setTimedRole(address,uint256,uint40,uint40)

```solidity
function setTimedRole(
    address holder,
    uint256 timedRole,
    uint40 start,
    uint40 expires
) public payable virtual
```

Sets the active time range of `timedRole` of `holder` to [`start`, `expires`].   
The `timedRole` is active when `start <= block.timestamp && block.timestamp <= expires`.

## Public Read Functions

### timedRoleActive(address,uint256)

```solidity
function timedRoleActive(address holder, uint256 timedRole)
    public
    view
    virtual
    returns (bool isActive, uint40 start, uint40 expires)
```

Returns whether the `timedRole` is active for `holder` and the active time range.

## Internal Functions

### _setTimedRole(address,uint256,uint40,uint40)

```solidity
function _setTimedRole(
    address holder,
    uint256 timedRole,
    uint40 start,
    uint40 expires
) internal virtual
```

Set the timed role for holder directly without authorization guard.

### _validateTimedRole(uint256)

```solidity
function _validateTimedRole(uint256 timedRole) internal view virtual
```

Requires the timedRole is not greater than `MAX_TIMED_ROLE()`.   
If `MAX_TIMED_ROLE()` is not implemented, this is an no-op.

### _authorizeSetTimedRole(address,uint256,uint40,uint40)

```solidity
function _authorizeSetTimedRole(
    address holder,
    uint256 timedRole,
    uint40 start,
    uint40 expires
) internal virtual
```

Checks that the caller is authorized to set the timed role.

### _hasAnyTimedRoles(address,bytes)

```solidity
function _hasAnyTimedRoles(address holder, bytes memory encodedTimeRoles)
    internal
    view
    virtual
    returns (bool result)
```

Returns if `holder` has any roles in `encodedTimeRoles`.   
`encodedTimeRoles` is `abi.encode(SAMPLE_TIMED_ROLE_0, SAMPLE_TIMED_ROLE_1, ...)`.

### _checkTimedRole(uint256)

```solidity
function _checkTimedRole(uint256 timedRole) internal view virtual
```

Reverts if `msg.sender` does not have `timedRole`.

### _checkTimedRoles(bytes)

```solidity
function _checkTimedRoles(bytes memory encodedTimedRoles)
    internal
    view
    virtual
```

Reverts if `msg.sender` does not have any timed role in `encodedTimedRoles`.

### _checkOwnerOrTimedRole(uint256)

```solidity
function _checkOwnerOrTimedRole(uint256 timedRole) internal view virtual
```

Reverts if `msg.sender` is not the contract owner and does not have `timedRole`.

### _checkOwnerOrTimedRoles(bytes)

```solidity
function _checkOwnerOrTimedRoles(bytes memory encodedTimedRoles)
    internal
    view
    virtual
```

Reverts if `msg.sender` is not the contract owner and   
does not have any timed role in `encodedTimedRoles`.

## Modifiers

### onlyTimedRole(uint256)

```solidity
modifier onlyTimedRole(uint256 timedRole) virtual
```

Marks a function as only callable by an account with `timedRole`.

### onlyTimedRoles(bytes)

```solidity
modifier onlyTimedRoles(bytes memory encodedTimedRoles) virtual
```

Marks a function as only callable by an account with any role in `encodedTimedRoles`.   
`encodedTimedRoles` is `abi.encode(SAMPLE_TIMED_ROLE_0, SAMPLE_TIMED_ROLE_1, ...)`.

### onlyOwnerOrTimedRole(uint256)

```solidity
modifier onlyOwnerOrTimedRole(uint256 timedRole) virtual
```

Marks a function as only callable by the owner or by an account with `timedRole`.

### onlyOwnerOrTimedRoles(bytes)

```solidity
modifier onlyOwnerOrTimedRoles(bytes memory encodedTimedRoles) virtual
```

Marks a function as only callable by the owner or   
by an account with any role in `encodedTimedRoles`.   
Checks for ownership first, then checks for roles.   
`encodedTimedRoles` is `abi.encode(SAMPLE_TIMED_ROLE_0, SAMPLE_TIMED_ROLE_1, ...)`.