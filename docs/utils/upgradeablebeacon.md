# UpgradeableBeacon

Upgradeable beacon for ERC1967 beacon proxies.


<b>Note:</b>

- The implementation is intended to be used with ERC1967 beacon proxies. See: `LibClone.deployERC1967BeaconProxy` and related functions.
- For gas efficiency, the ownership functionality is baked into this contract.

<b>Optimized creation code (hex-encoded):</b>
`60406101c73d393d5160205180821760a01c3d3d3e803b1560875781684343a0dc92ed22dbfc558068911c5a209f08d5ec5e557fbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b3d38a23d7f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e03d38a3610132806100953d393df35b636d3e283b3d526004601cfdfe3d3560e01c635c60da1b14610120573d3560e01c80638da5cb5b1461010e5780633659cfe61460021b8163f2fde38b1460011b179063715018a6141780153d3d3e684343a0dc92ed22dbfc805490813303610101573d9260068116610089575b508290557f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e03d38a3005b925060048035938460a01c60243610173d3d3e146100ba5782156100ad573861005f565b637448fbae3d526004601cfd5b82803b156100f4578068911c5a209f08d5ec5e557fbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b3d38a2005b636d3e283b3d526004601cfd5b6382b429003d526004601cfd5b684343a0dc92ed22dbfc543d5260203df35b68911c5a209f08d5ec5e543d5260203df3`.
See: https://gist.github.com/Vectorized/365bd7f6e9a848010f00adb9e50a2516

<b>To get the initialization code:</b>
`abi.encodePacked(creationCode, abi.encode(initialOwner, initialImplementation))`

This optimized bytecode is compiled via Yul and is not verifiable via Etherscan
at the time of writing. For best gas efficiency, deploy the Yul version.
The Solidity version is provided as an interface / reference.



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