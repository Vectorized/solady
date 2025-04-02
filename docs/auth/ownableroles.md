# OwnableRoles

Simple single owner and multiroles authorization mixin.


<b>Note:</b>

This implementation does NOT auto-initialize the owner to `msg.sender`.
You MUST call the `_initializeOwner` in the constructor / initializer.

While the ownable portion follows
[EIP-173](https://eips.ethereum.org/EIPS/eip-173) for compatibility,
the nomenclature for the 2-step ownership handover may be unique to this codebase.

<b>Inherits:</b>  

- [`auth/Ownable.sol`](auth/ownable.md)  


<!-- customintro:start --><!-- customintro:end -->

## Events

### RolesUpdated(address,uint256)

```solidity
event RolesUpdated(address indexed user, uint256 indexed roles)
```

The `user`'s roles is updated to `roles`.   
Each bit of `roles` represents whether the role is set.

## Internal Functions

### _setRoles(address,uint256)

```solidity
function _setRoles(address user, uint256 roles) internal virtual
```

Overwrite the roles directly without authorization guard.

### _updateRoles(address,uint256,bool)

```solidity
function _updateRoles(address user, uint256 roles, bool on)
    internal
    virtual
```

Updates the roles directly without authorization guard.   
If `on` is true, each set bit of `roles` will be turned on,   
otherwise, each set bit of `roles` will be turned off.

### _grantRoles(address,uint256)

```solidity
function _grantRoles(address user, uint256 roles) internal virtual
```

Grants the roles directly without authorization guard.   
Each bit of `roles` represents the role to turn on.

### _removeRoles(address,uint256)

```solidity
function _removeRoles(address user, uint256 roles) internal virtual
```

Removes the roles directly without authorization guard.   
Each bit of `roles` represents the role to turn off.

### _checkRoles(uint256)

```solidity
function _checkRoles(uint256 roles) internal view virtual
```

Throws if the sender does not have any of the `roles`.

### _checkOwnerOrRoles(uint256)

```solidity
function _checkOwnerOrRoles(uint256 roles) internal view virtual
```

Throws if the sender is not the owner,   
and does not have any of the `roles`.   
Checks for ownership first, then lazily checks for roles.

### _checkRolesOrOwner(uint256)

```solidity
function _checkRolesOrOwner(uint256 roles) internal view virtual
```

Throws if the sender does not have any of the `roles`,   
and is not the owner.   
Checks for roles first, then lazily checks for ownership.

### _rolesFromOrdinals(uint8[])

```solidity
function _rolesFromOrdinals(uint8[] memory ordinals)
    internal
    pure
    returns (uint256 roles)
```

Convenience function to return a `roles` bitmap from an array of `ordinals`.   
This is meant for frontends like Etherscan, and is therefore not fully optimized.   
Not recommended to be called on-chain.   
Made internal to conserve bytecode. Wrap it in a public function if needed.

### _ordinalsFromRoles(uint256)

```solidity
function _ordinalsFromRoles(uint256 roles)
    internal
    pure
    returns (uint8[] memory ordinals)
```

Convenience function to return an array of `ordinals` from the `roles` bitmap.   
This is meant for frontends like Etherscan, and is therefore not fully optimized.   
Not recommended to be called on-chain.   
Made internal to conserve bytecode. Wrap it in a public function if needed.

## Public Update Functions

### grantRoles(address,uint256)

```solidity
function grantRoles(address user, uint256 roles)
    public
    payable
    virtual
    onlyOwner
```

Allows the owner to grant `user` `roles`.   
If the `user` already has a role, then it will be an no-op for the role.

### revokeRoles(address,uint256)

```solidity
function revokeRoles(address user, uint256 roles)
    public
    payable
    virtual
    onlyOwner
```

Allows the owner to remove `user` `roles`.   
If the `user` does not have a role, then it will be an no-op for the role.

### renounceRoles(uint256)

```solidity
function renounceRoles(uint256 roles) public payable virtual
```

Allow the caller to remove their own roles.   
If the caller does not have a role, then it will be an no-op for the role.

## Public Read Functions

### rolesOf(address)

```solidity
function rolesOf(address user)
    public
    view
    virtual
    returns (uint256 roles)
```

Returns the roles of `user`.

### hasAnyRole(address,uint256)

```solidity
function hasAnyRole(address user, uint256 roles)
    public
    view
    virtual
    returns (bool)
```

Returns whether `user` has any of `roles`.

### hasAllRoles(address,uint256)

```solidity
function hasAllRoles(address user, uint256 roles)
    public
    view
    virtual
    returns (bool)
```

Returns whether `user` has all of `roles`.

## Modifiers

### onlyRoles(uint256)

```solidity
modifier onlyRoles(uint256 roles) virtual
```

Marks a function as only callable by an account with `roles`.

### onlyOwnerOrRoles(uint256)

```solidity
modifier onlyOwnerOrRoles(uint256 roles) virtual
```

Marks a function as only callable by the owner or by an account   
with `roles`. Checks for ownership first, then lazily checks for roles.

### onlyRolesOrOwner(uint256)

```solidity
modifier onlyRolesOrOwner(uint256 roles) virtual
```

Marks a function as only callable by an account with `roles`   
or the owner. Checks for roles first, then lazily checks for ownership.