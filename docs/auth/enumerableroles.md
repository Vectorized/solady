# EnumerableRoles

Enumerable multiroles authorization mixin.


<b>Note:</b>

This implementation is agnostic to the Ownable that the contract inherits from.
It performs a self-staticcall to the `owner()` function to determine the owner.
This is useful for situations where the contract inherits from
OpenZeppelin's Ownable, such as in LayerZero's OApp contracts.

This implementation performs a self-staticcall to `MAX_ROLE()` to determine
the maximum role that can be set/unset. If the inheriting contract does not
have `MAX_ROLE()`, then any role can be set/unset.

This implementation allows for any uint256 role,
it does NOT take in a bitmask of roles.
This is to accommodate teams that are allergic to bitwise flags.

By default, the `owner()` is the only account that is authorized to set roles.
This behavior can be changed via overrides.

This implementation is compatible with any Ownable.
This implementation is NOT compatible with OwnableRoles.



<!-- customintro:start --><!-- customintro:end -->

## Events

### RoleSet(address,uint256,bool)

```solidity
event RoleSet(
    address indexed holder, uint256 indexed role, bool indexed active
)
```

The status of `role` for `holder` has been set to `active`.

## Custom Errors

### RoleHoldersIndexOutOfBounds()

```solidity
error RoleHoldersIndexOutOfBounds()
```

The index is out of bounds of the role holders array.

### RoleHolderIsZeroAddress()

```solidity
error RoleHolderIsZeroAddress()
```

Cannot set the role of the zero address.

### InvalidRole()

```solidity
error InvalidRole()
```

The role has exceeded the maximum role.

### EnumerableRolesUnauthorized()

```solidity
error EnumerableRolesUnauthorized()
```

Unauthorized to perform the action.

## Public Update Functions

### setRole(address,uint256,bool)

```solidity
function setRole(address holder, uint256 role, bool active)
    public
    payable
    virtual
```

Sets the status of `role` of `holder` to `active`.

## Public Read Functions

### hasRole(address,uint256)

```solidity
function hasRole(address holder, uint256 role)
    public
    view
    virtual
    returns (bool result)
```

Returns if `holder` has active `role`.

### roleHolders(uint256)

```solidity
function roleHolders(uint256 role)
    public
    view
    virtual
    returns (address[] memory result)
```

Returns an array of the holders of `role`.

### roleHolderCount(uint256)

```solidity
function roleHolderCount(uint256 role)
    public
    view
    virtual
    returns (uint256 result)
```

Returns the total number of holders of `role`.

### roleHolderAt(uint256,uint256)

```solidity
function roleHolderAt(uint256 role, uint256 i)
    public
    view
    virtual
    returns (address result)
```

Returns the holder of `role` at the index `i`.

## Internal Functions

### _setRole(address,uint256,bool)

```solidity
function _setRole(address holder, uint256 role, bool active)
    internal
    virtual
```

Set the role for holder directly without authorization guard.

### _validateRole(uint256)

```solidity
function _validateRole(uint256 role) internal view virtual
```

Requires the role is not greater than `MAX_ROLE()`.   
If `MAX_ROLE()` is not implemented, this is an no-op.

### _authorizeSetRole(address,uint256,bool)

```solidity
function _authorizeSetRole(address holder, uint256 role, bool active)
    internal
    virtual
```

Checks that the caller is authorized to set the role.

### _hasAnyRoles(address,bytes)

```solidity
function _hasAnyRoles(address holder, bytes memory encodedRoles)
    internal
    view
    virtual
    returns (bool result)
```

Returns if `holder` has any roles in `encodedRoles`.   
`encodedRoles` is `abi.encode(SAMPLE_ROLE_0, SAMPLE_ROLE_1, ...)`.

### _checkRole(uint256)

```solidity
function _checkRole(uint256 role) internal view virtual
```

Reverts if `msg.sender` does not have `role`.

### _checkRoles(bytes)

```solidity
function _checkRoles(bytes memory encodedRoles) internal view virtual
```

Reverts if `msg.sender` does not have any role in `encodedRoles`.

### _checkOwnerOrRole(uint256)

```solidity
function _checkOwnerOrRole(uint256 role) internal view virtual
```

Reverts if `msg.sender` is not the contract owner and does not have `role`.

### _checkOwnerOrRoles(bytes)

```solidity
function _checkOwnerOrRoles(bytes memory encodedRoles)
    internal
    view
    virtual
```

Reverts if `msg.sender` is not the contract owner and   
does not have any role in `encodedRoles`.

## Modifiers

### onlyRole(uint256)

```solidity
modifier onlyRole(uint256 role) virtual
```

Marks a function as only callable by an account with `role`.

### onlyRoles(bytes)

```solidity
modifier onlyRoles(bytes memory encodedRoles) virtual
```

Marks a function as only callable by an account with any role in `encodedRoles`.   
`encodedRoles` is `abi.encode(SAMPLE_ROLE_0, SAMPLE_ROLE_1, ...)`.

### onlyOwnerOrRole(uint256)

```solidity
modifier onlyOwnerOrRole(uint256 role) virtual
```

Marks a function as only callable by the owner or by an account with `role`.

### onlyOwnerOrRoles(bytes)

```solidity
modifier onlyOwnerOrRoles(bytes memory encodedRoles) virtual
```

Marks a function as only callable by the owner or   
by an account with any role in `encodedRoles`.   
Checks for ownership first, then checks for roles.   
`encodedRoles` is `abi.encode(SAMPLE_ROLE_0, SAMPLE_ROLE_1, ...)`.