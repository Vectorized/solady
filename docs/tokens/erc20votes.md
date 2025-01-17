# ERC20Votes

ERC20 with votes based on ERC5805 and ERC6372.




<b>Inherits:</b>  

- [`tokens/ERC20.sol`](tokens/erc20.md)  


<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### ERC5805FutureLookup()

```solidity
error ERC5805FutureLookup()
```

The timepoint is in the future.

### ERC5805DelegateSignatureExpired()

```solidity
error ERC5805DelegateSignatureExpired()
```

The ERC5805 signature to set a delegate has expired.

### ERC5805DelegateInvalidSignature()

```solidity
error ERC5805DelegateInvalidSignature()
```

The ERC5805 signature to set a delegate is invalid.

### ERC5805CheckpointIndexOutOfBounds()

```solidity
error ERC5805CheckpointIndexOutOfBounds()
```

Out-of-bounds access for the checkpoints.

### ERC5805CheckpointValueOverflow()

```solidity
error ERC5805CheckpointValueOverflow()
```

Arithmetic overflow when pushing a new checkpoint.

### ERC5805CheckpointValueUnderflow()

```solidity
error ERC5805CheckpointValueUnderflow()
```

Arithmetic underflow when pushing a new checkpoint.

## ERC6372

### CLOCK_MODE()

```solidity
function CLOCK_MODE() public view virtual returns (string memory)
```

Returns the clock mode.

### clock()

```solidity
function clock() public view virtual returns (uint48 result)
```

Returns the current clock.

## ERC5805

### getVotes(address)

```solidity
function getVotes(address account) public view virtual returns (uint256)
```

Returns the latest amount of voting units for `account`.

### getPastVotes(address,uint256)

```solidity
function getPastVotes(address account, uint256 timepoint)
    public
    view
    virtual
    returns (uint256)
```

Returns the latest amount of voting units `account` has before or during `timepoint`.

### delegates(address)

```solidity
function delegates(address delegator)
    public
    view
    virtual
    returns (address result)
```

Returns the current voting delegate of `delegator`.

### delegate(address)

```solidity
function delegate(address delegatee) public virtual
```

Set the voting delegate of the caller to `delegatee`.

### delegateBySig(address,uint256,uint256,uint8,bytes32,bytes32)

```solidity
function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
) public virtual
```

Sets the voting delegate of the signature signer to `delegatee`.

## Other Vote Public View Functions

### checkpointCount(address)

```solidity
function checkpointCount(address account)
    public
    view
    virtual
    returns (uint256 result)
```

Returns the number of checkpoints for `account`.

### checkpointAt(address,uint256)

```solidity
function checkpointAt(address account, uint256 i)
    public
    view
    virtual
    returns (uint48 checkpointClock, uint256 checkpointValue)
```

Returns the voting checkpoint for `account` at index `i`.

### getVotesTotalSupply()

```solidity
function getVotesTotalSupply() public view virtual returns (uint256)
```

Returns the latest amount of total voting units.

### getPastVotesTotalSupply(uint256)

```solidity
function getPastVotesTotalSupply(uint256 timepoint)
    public
    view
    virtual
    returns (uint256)
```

Returns the latest amount of total voting units before or during `timepoint`.

## Internal Functions

### _getVotingUnits(address)

```solidity
function _getVotingUnits(address delegator)
    internal
    view
    virtual
    returns (uint256)
```

Returns the amount of voting units `delegator` has control over.   
Override if you need a different formula.

### _afterTokenTransfer(address,address,uint256)

```solidity
function _afterTokenTransfer(address from, address to, uint256 amount)
    internal
    virtual
    override
```

ERC20 after token transfer internal hook.

### _transferVotingUnits(address,address,uint256)

```solidity
function _transferVotingUnits(address from, address to, uint256 amount)
    internal
    virtual
```

Used in `_afterTokenTransfer(address from, address to, uint256 amount)`.

### _moveDelegateVotes(address,address,uint256)

```solidity
function _moveDelegateVotes(address from, address to, uint256 amount)
    internal
    virtual
```

Transfer `amount` of delegated votes from `from` to `to`.   
Emits a {DelegateVotesChanged} event for each change of delegated votes.

### _delegate(address,address)

```solidity
function _delegate(address account, address delegatee) internal virtual
```

Delegates all of `account`'s voting units to `delegatee`.   
Emits the {DelegateChanged} and {DelegateVotesChanged} events.