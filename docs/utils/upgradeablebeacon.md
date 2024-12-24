# UpgradeableBeacon

Upgradeable beacon for ERC1967 beacon proxies.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### NewImplementationHasNoCode()

```solidity
error NewImplementationHasNoCode()
```

The new implementation is not a deployed contract.

### Unauthorized()

```solidity
error Unauthorized()
```

The caller is not authorized to perform the operation.

### NewOwnerIsZeroAddress()

```solidity
error NewOwnerIsZeroAddress()
```

The `newOwner` cannot be the zero address.

## Storage

### _UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT

```solidity
uint256 internal constant _UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT =
    0x911c5a209f08d5ec5e
```

The storage slot for the implementation address.   
`uint72(bytes9(keccak256("_UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT")))`.

### _UPGRADEABLE_BEACON_OWNER_SLOT

```solidity
uint256 internal constant _UPGRADEABLE_BEACON_OWNER_SLOT =
    0x4343a0dc92ed22dbfc
```

The storage slot for the owner address.   
`uint72(bytes9(keccak256("_UPGRADEABLE_BEACON_OWNER_SLOT")))`.

## Constructor

### _constructUpgradeableBeacon(address,address)

```solidity
function _constructUpgradeableBeacon(
    address initialOwner,
    address initialImplementation
) internal virtual
```

Called in the constructor. Override as required.

## Upgradeable Beacon Operations

### _initializeUpgradeableBeacon(address,address)

```solidity
function _initializeUpgradeableBeacon(
    address initialOwner,
    address initialImplementation
) internal virtual
```

Required to be called in the constructor or initializer.   
This function does not guard against double-initialization.

### _setImplementation(address)

```solidity
function _setImplementation(address newImplementation) internal virtual
```

Sets the implementation directly without authorization guard.

### _setOwner(address)

```solidity
function _setOwner(address newOwner) internal virtual
```

Sets the owner directly without authorization guard.

### implementation()

```solidity
function implementation() public view returns (address result)
```

Returns the implementation stored in the beacon.   
See: https://eips.ethereum.org/EIPS/eip-1967#beacon-contract-address

### owner()

```solidity
function owner() public view returns (address result)
```

Returns the owner of the beacon.

### upgradeTo(address)

```solidity
function upgradeTo(address newImplementation) public virtual onlyOwner
```

Allows the owner to upgrade the implementation.

### transferOwnership(address)

```solidity
function transferOwnership(address newOwner) public virtual onlyOwner
```

Allows the owner to transfer the ownership to `newOwner`.

### renounceOwnership()

```solidity
function renounceOwnership() public virtual onlyOwner
```

Allows the owner to renounce their ownership.

### _checkOwner()

```solidity
function _checkOwner() internal view virtual
```

Throws if the sender is not the owner.

## Modifiers

### onlyOwner()

```solidity
modifier onlyOwner() virtual
```

Marks a function as only callable by the owner.