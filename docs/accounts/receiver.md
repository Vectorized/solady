# Receiver

Receiver mixin for ETH and safe-transferred ERC721 and ERC1155 tokens.


<b>Note:</b>

- Handles all ERC721 and ERC1155 token safety callbacks.
- Collapses function table gas overhead and code size.
- Utilizes fallback so unknown calldata will pass on.



<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### FnSelectorNotRecognized()

```solidity
error FnSelectorNotRecognized()
```

The function selector is not recognized.

## Receive / Fallback

### receive()

```solidity
receive() external payable virtual
```

For receiving ETH.

### fallback()

```solidity
fallback() external payable virtual receiverFallback
```

Fallback function with the `receiverFallback` modifier.

### receiverFallback()

```solidity
modifier receiverFallback() virtual
```

Modifier for the fallback function to handle token callbacks.

### _useReceiverFallbackBody()

```solidity
function _useReceiverFallbackBody() internal view virtual returns (bool)
```

Whether we want to use the body of the `receiverFallback` modifier.

### _beforeReceiverFallbackBody()

```solidity
function _beforeReceiverFallbackBody() internal virtual
```

Called before the body of the `receiverFallback` modifier.

### _afterReceiverFallbackBody()

```solidity
function _afterReceiverFallbackBody() internal virtual
```

Called after the body of the `receiverFallback` modifier.