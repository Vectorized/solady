# SafeTransferLib

Safe ETH and ERC20 transfer library that gracefully handles missing return values.


<b>Note:</b>

- For ETH transfers, please use `forceSafeTransferETH` for DoS protection.



<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### ETHTransferFailed()

```solidity
error ETHTransferFailed()
```

The ETH transfer has failed.

### TransferFromFailed()

```solidity
error TransferFromFailed()
```

The ERC20 `transferFrom` has failed.

### TransferFailed()

```solidity
error TransferFailed()
```

The ERC20 `transfer` has failed.

### ApproveFailed()

```solidity
error ApproveFailed()
```

The ERC20 `approve` has failed.

### TotalSupplyQueryFailed()

```solidity
error TotalSupplyQueryFailed()
```

The ERC20 `totalSupply` query has failed.

### Permit2Failed()

```solidity
error Permit2Failed()
```

The Permit2 operation has failed.

### Permit2AmountOverflow()

```solidity
error Permit2AmountOverflow()
```

The Permit2 amount must be less than `2**160 - 1`.

### Permit2ApproveFailed()

```solidity
error Permit2ApproveFailed()
```

The Permit2 approve operation has failed.

### Permit2LockdownFailed()

```solidity
error Permit2LockdownFailed()
```

The Permit2 lockdown operation has failed.

## Constants

### GAS_STIPEND_NO_STORAGE_WRITES

```solidity
uint256 internal constant GAS_STIPEND_NO_STORAGE_WRITES = 2300
```

Suggested gas stipend for contract receiving ETH that disallows any storage writes.

### GAS_STIPEND_NO_GRIEF

```solidity
uint256 internal constant GAS_STIPEND_NO_GRIEF = 100000
```

Suggested gas stipend for contract receiving ETH to perform a few   
storage reads and writes, but low enough to prevent griefing.

### DAI_DOMAIN_SEPARATOR

```solidity
bytes32 internal constant DAI_DOMAIN_SEPARATOR =
    0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7
```

The unique EIP-712 domain separator for the DAI token contract.

### WETH9

```solidity
address internal constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
```

The address for the WETH9 contract on Ethereum mainnet.

### PERMIT2

```solidity
address internal constant PERMIT2 =
    0x000000000022D473030F116dDEE9F6B43aC78BA3
```

The canonical Permit2 address.   
[Github](https://github.com/Uniswap/permit2)   
[Etherscan](https://etherscan.io/address/0x000000000022D473030F116dDEE9F6B43aC78BA3)

### ETH_MOVER

```solidity
address internal constant ETH_MOVER =
    0x00000000000073c48c8055bD43D1A53799176f0D
```

The canonical address of the `SELFDESTRUCT` ETH mover.   
See: https://gist.github.com/Vectorized/1cb8ad4cf393b1378e08f23f79bd99fa   
[Etherscan](https://etherscan.io/address/0x00000000000073c48c8055bD43D1A53799176f0D)

## ETH Operations

If the ETH transfer MUST succeed with a reasonable gas budget, use the force variants.   
The regular variants:   
- Forwards all remaining gas to the target.   
- Reverts if the target reverts.   
- Reverts if the current contract has insufficient balance.   
The force variants:   
- Forwards with an optional gas stipend   
  (defaults to `GAS_STIPEND_NO_GRIEF`, which is sufficient for most cases).   
- If the target reverts, or if the gas stipend is exhausted,   
  creates a temporary contract to force send the ETH via `SELFDESTRUCT`.   
  Future compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758.   
- Reverts if the current contract has insufficient balance.   
The try variants:   
- Forwards with a mandatory gas stipend.   
- Instead of reverting, returns whether the transfer succeeded.

### safeTransferETH(address,uint256)

```solidity
function safeTransferETH(address to, uint256 amount) internal
```

Sends `amount` (in wei) ETH to `to`.

### safeTransferAllETH(address)

```solidity
function safeTransferAllETH(address to) internal
```

Sends all the ETH in the current contract to `to`.

### forceSafeTransferETH(address,uint256,uint256)

```solidity
function forceSafeTransferETH(
    address to,
    uint256 amount,
    uint256 gasStipend
) internal
```

Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.

### forceSafeTransferAllETH(address,uint256)

```solidity
function forceSafeTransferAllETH(address to, uint256 gasStipend) internal
```

Force sends all the ETH in the current contract to `to`, with a `gasStipend`.

### forceSafeTransferETH(address,uint256)

```solidity
function forceSafeTransferETH(address to, uint256 amount) internal
```

Force sends `amount` (in wei) ETH to `to`, with `GAS_STIPEND_NO_GRIEF`.

### forceSafeTransferAllETH(address)

```solidity
function forceSafeTransferAllETH(address to) internal
```

Force sends all the ETH in the current contract to `to`, with `GAS_STIPEND_NO_GRIEF`.

### trySafeTransferETH(address,uint256,uint256)

```solidity
function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
    internal
    returns (bool success)
```

Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.

### trySafeTransferAllETH(address,uint256)

```solidity
function trySafeTransferAllETH(address to, uint256 gasStipend)
    internal
    returns (bool success)
```

Sends all the ETH in the current contract to `to`, with a `gasStipend`.

### safeMoveETH(address,uint256)

```solidity
function safeMoveETH(address to, uint256 amount)
    internal
    returns (address vault)
```

Force transfers ETH to `to`, without triggering the fallback (if any).   
This method attempts to use a separate contract to send via `SELFDESTRUCT`,   
and upon failure, deploys a minimal vault to accrue the ETH.

## ERC20 Operations

### safeTransferFrom(address,address,address,uint256)

```solidity
function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 amount
) internal
```

Sends `amount` of ERC20 `token` from `from` to `to`.   
Reverts upon failure.   
The `from` account must have at least `amount` approved for   
the current contract to manage.

### trySafeTransferFrom(address,address,address,uint256)

```solidity
function trySafeTransferFrom(
    address token,
    address from,
    address to,
    uint256 amount
) internal returns (bool success)
```

Sends `amount` of ERC20 `token` from `from` to `to`.   
The `from` account must have at least `amount` approved for the current contract to manage.

### safeTransferAllFrom(address,address,address)

```solidity
function safeTransferAllFrom(address token, address from, address to)
    internal
    returns (uint256 amount)
```

Sends all of ERC20 `token` from `from` to `to`.   
Reverts upon failure.   
The `from` account must have their entire balance approved for the current contract to manage.

### safeTransfer(address,address,uint256)

```solidity
function safeTransfer(address token, address to, uint256 amount) internal
```

Sends `amount` of ERC20 `token` from the current contract to `to`.   
Reverts upon failure.

### safeTransferAll(address,address)

```solidity
function safeTransferAll(address token, address to)
    internal
    returns (uint256 amount)
```

Sends all of ERC20 `token` from the current contract to `to`.   
Reverts upon failure.

### safeApprove(address,address,uint256)

```solidity
function safeApprove(address token, address to, uint256 amount) internal
```

Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.   
Reverts upon failure.

### safeApproveWithRetry(address,address,uint256)

```solidity
function safeApproveWithRetry(address token, address to, uint256 amount)
    internal
```

Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.   
If the initial attempt to approve fails, attempts to reset the approved amount to zero,   
then retries the approval again (some tokens, e.g. USDT, requires this).   
Reverts upon failure.

### balanceOf(address,address)

```solidity
function balanceOf(address token, address account)
    internal
    view
    returns (uint256 amount)
```

Returns the amount of ERC20 `token` owned by `account`.   
Returns zero if the `token` does not exist.

### checkBalanceOf(address,address)

```solidity
function checkBalanceOf(address token, address account)
    internal
    view
    returns (bool implemented, uint256 amount)
```

Performs a `token.balanceOf(account)` check.   
`implemented` denotes whether the `token` does not implement `balanceOf`.   
`amount` is zero if the `token` does not implement `balanceOf`.

### totalSupply(address)

```solidity
function totalSupply(address token)
    internal
    view
    returns (uint256 result)
```

Returns the total supply of the `token`.   
Reverts if the token does not exist or does not implement `totalSupply()`.

### safeTransferFrom2(address,address,address,uint256)

```solidity
function safeTransferFrom2(
    address token,
    address from,
    address to,
    uint256 amount
) internal
```

Sends `amount` of ERC20 `token` from `from` to `to`.   
If the initial attempt fails, try to use Permit2 to transfer the token.   
Reverts upon failure.   
The `from` account must have at least `amount` approved for the current contract to manage.

### permit2TransferFrom(address,address,address,uint256)

```solidity
function permit2TransferFrom(
    address token,
    address from,
    address to,
    uint256 amount
) internal
```

Sends `amount` of ERC20 `token` from `from` to `to` via Permit2.   
Reverts upon failure.

### permit2(address,address,address,uint256,uint256,uint8,bytes32,bytes32)

```solidity
function permit2(
    address token,
    address owner,
    address spender,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) internal
```

Permit a user to spend a given amount of   
another user's tokens via native EIP-2612 permit if possible, falling   
back to Permit2 if native permit fails or is not implemented on the token.

### simplePermit2(address,address,address,uint256,uint256,uint8,bytes32,bytes32)

```solidity
function simplePermit2(
    address token,
    address owner,
    address spender,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) internal
```

Simple permit on the Permit2 contract.

### permit2Approve(address,address,uint160,uint48)

```solidity
function permit2Approve(
    address token,
    address spender,
    uint160 amount,
    uint48 expiration
) internal
```

Approves `spender` to spend `amount` of `token` for `address(this)`.

### permit2Lockdown(address,address)

```solidity
function permit2Lockdown(address token, address spender) internal
```

Revokes an approval for `token` and `spender` for `address(this)`.