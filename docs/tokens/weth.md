# WETH

Simple Wrapped Ether implementation.

All spenders are treated as ERC-8255 legacy-compatible because this contract
has no owner-controlled spender policy.




<b>Inherits:</b>  

- [`tokens/ERC20.sol`](tokens/erc20.md)  


<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### ETHTransferFailed()

```solidity
error ETHTransferFailed()
```

The ETH transfer has failed.

## ERC20 Metadata

### name()

```solidity
function name() public view virtual override returns (string memory)
```

Returns the name of the token.

### symbol()

```solidity
function symbol() public view virtual override returns (string memory)
```

Returns the symbol of the token.

## WETH

### deposit()

```solidity
function deposit() public payable virtual
```

Deposits `amount` ETH of the caller and mints `amount` WETH to the caller.

### withdraw(uint256)

```solidity
function withdraw(uint256 amount) public virtual
```

Burns `amount` WETH of the caller and sends `amount` ETH to the caller.

### receive()

```solidity
receive() external payable virtual
```

Equivalent to `deposit()`.
