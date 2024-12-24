# Lifebuoy

Class that allows for rescue of ETH, ERC20, ERC721 tokens.


<b>This contract is created to mitigate the following disasters:</b>

- Careless user sends tokens to the wrong chain or wrong contract.
- Careless dev deploys a contract without a withdraw function in attempt to rescue
careless user's tokens, due to deployment nonce mismatch caused by
script misfire / misconfiguration.
- Careless dev forgets to add a withdraw function to a NFT sale contract.

<b>Note:</b>

if you are deploying via a untrusted `tx.origin`,
you MUST override `_lifebuoyDefaultDeployer` to return a trusted address.

<b>For best safety:</b>
- For non-escrow contracts, inherit Lifebuoy as much as possible,
and leave it unlocked.
- For escrow contracts, lock access as tight as possible,
as soon as possible. Or simply don't inherit Lifebuoy. Escrow: Your contract is designed to hold ETH, ERC20s, ERC721s
(e.g. liquidity pools).

<b>All rescue and rescue authorization functions require either:</b>
- Caller is the deployer
AND the contract is not a proxy
AND `rescueLocked() & _LIFEBUOY_DEPLOYER_ACCESS_LOCK == 0`.
- Caller is `owner()`
AND `rescueLocked() & _LIFEBUOY_OWNER_ACCESS_LOCK == 0`.

The choice of using bit flags to represent locked statuses is for
efficiency, flexibility, convenience.

This contract is optimized with a priority on minimal bytecode size,
as the methods are not intended to be called often.



<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### RescueUnauthorizedOrLocked()

```solidity
error RescueUnauthorizedOrLocked()
```

The caller is not authorized to rescue or lock the rescue function.

### RescueTransferFailed()

```solidity
error RescueTransferFailed()
```

The rescue operation has failed due to a failed transfer.

## Lock Flags Constants

These flags are kept internal to avoid bloating up the function dispatch.   
You can just copy paste this into your own code.

### _LIFEBUOY_DEPLOYER_ACCESS_LOCK

```solidity
uint256 internal constant _LIFEBUOY_DEPLOYER_ACCESS_LOCK = 1 << 0
```

Flag to denote that the deployer's access is locked. (1)

### _LIFEBUOY_OWNER_ACCESS_LOCK

```solidity
uint256 internal constant _LIFEBUOY_OWNER_ACCESS_LOCK = 1 << 1
```

Flag to denote that the `owner()`'s access is locked. (2)

### _LIFEBUOY_LOCK_RESCUE_LOCK

```solidity
uint256 internal constant _LIFEBUOY_LOCK_RESCUE_LOCK = 1 << 2
```

Flag to denote that the `lockRescue` function is locked. (4)

### _LIFEBUOY_RESCUE_ETH_LOCK

```solidity
uint256 internal constant _LIFEBUOY_RESCUE_ETH_LOCK = 1 << 3
```

Flag to denote that the `rescueETH` function is locked. (8)

### _LIFEBUOY_RESCUE_ERC20_LOCK

```solidity
uint256 internal constant _LIFEBUOY_RESCUE_ERC20_LOCK = 1 << 4
```

Flag to denote that the `rescueERC20` function is locked. (16)

### _LIFEBUOY_RESCUE_ERC721_LOCK

```solidity
uint256 internal constant _LIFEBUOY_RESCUE_ERC721_LOCK = 1 << 5
```

Flag to denote that the `rescueERC721` function is locked. (32)

### _LIFEBUOY_RESCUE_ERC1155_LOCK

```solidity
uint256 internal constant _LIFEBUOY_RESCUE_ERC1155_LOCK = 1 << 6
```

Flag to denote that the `rescueERC1155` function is locked. (64)

### _LIFEBUOY_RESCUE_ERC6909_LOCK

```solidity
uint256 internal constant _LIFEBUOY_RESCUE_ERC6909_LOCK = 1 << 7
```

Flag to denote that the `rescueERC6909` function is locked. (128)

## Immutables

### _lifebuoyDeployerHash

```solidity
bytes32 internal immutable _lifebuoyDeployerHash
```

For checking that the caller is the deployer and   
that the context is not a delegatecall   
(so that the implementation deployer cannot drain proxies).

## Storage

### _RESCUE_LOCKED_FLAGS_SLOT

```solidity
bytes32 internal constant _RESCUE_LOCKED_FLAGS_SLOT =
    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffb8e2915b
```

The rescue locked flags slot is given by:   
`bytes32(~uint256(uint32(bytes4(keccak256("_RESCUE_LOCKED_FLAGS_SLOT_NOT")))))`.   
It is intentionally chosen to be a high value   
to avoid collision with lower slots.   
The choice of manual storage layout is to enable compatibility   
with both regular and upgradeable contracts.

## Constructor

### _lifebuoyDefaultDeployer()

```solidity
function _lifebuoyDefaultDeployer()
    internal
    view
    virtual
    returns (address)
```

Returns `tx.origin` by default. Override to return another address if needed.   
Note: If you are deploying via a untrusted `tx.origin` (e.g. ERC4337 bundler)   
you MUST override this function to return a trusted address.

## Rescue Operations

### rescueETH(address,uint256)

```solidity
function rescueETH(address to, uint256 amount)
    public
    payable
    virtual
    onlyRescuer(_LIFEBUOY_RESCUE_ETH_LOCK)
```

Sends `amount` (in wei) ETH from the current contract to `to`.   
Reverts upon failure.

### rescueERC20(address,address,uint256)

```solidity
function rescueERC20(address token, address to, uint256 amount)
    public
    payable
    virtual
    onlyRescuer(_LIFEBUOY_RESCUE_ERC20_LOCK)
```

Sends `amount` of ERC20 `token` from the current contract to `to`.   
Does not check for existence of token or return data. Reverts upon failure.

### rescueERC721(address,address,uint256)

```solidity
function rescueERC721(address token, address to, uint256 id)
    public
    payable
    virtual
    onlyRescuer(_LIFEBUOY_RESCUE_ERC721_LOCK)
```

Sends `id` of ERC721 `token` from the current contract to `to`.   
Does not check for existence of token or return data. Reverts upon failure.

### rescueERC1155(address,address,uint256,uint256,bytes)

```solidity
function rescueERC1155(
    address token,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
) public payable virtual onlyRescuer(_LIFEBUOY_RESCUE_ERC1155_LOCK)
```

Sends `amount` of `id` of ERC1155 `token` from the current contract to `to`.   
Does not check for existence of token or return data. Reverts upon failure.

### rescueERC6909(address,address,uint256,uint256)

```solidity
function rescueERC6909(
    address token,
    address to,
    uint256 id,
    uint256 amount
) public payable virtual onlyRescuer(_LIFEBUOY_RESCUE_ERC6909_LOCK)
```

Sends `amount` of `id` of ERC6909 `token` from the current contract to `to`.   
Does not check for existence of token or return data. Reverts upon failure.

## Rescue Authorization Operations

### rescueLocked()

```solidity
function rescueLocked() public view virtual returns (uint256 locks)
```

Returns the flags denoting whether access to rescue functions   
(including `lockRescue`) is locked.

### lockRescue(uint256)

```solidity
function lockRescue(uint256 locksToSet)
    public
    payable
    virtual
    onlyRescuer(_LIFEBUOY_LOCK_RESCUE_LOCK)
```

Locks (i.e. permanently removes) access to rescue functions (including `lockRescue`).

### _lockRescue(uint256)

```solidity
function _lockRescue(uint256 locksToSet) internal virtual
```

Internal function to set the lock flags without going through access control.

### _checkRescuer(uint256)

```solidity
function _checkRescuer(uint256 modeLock) internal view virtual
```

Requires that the rescue function being guarded is:   
1. Not locked, AND   
2. Called by either:   
  (a) The `owner()`, OR   
  (b) The deployer (if not via a delegate call and deployer is an EOA).

### onlyRescuer(uint256)

```solidity
modifier onlyRescuer(uint256 modeLock) virtual
```

Modifier that calls `_checkRescuer()` at the start of the function.