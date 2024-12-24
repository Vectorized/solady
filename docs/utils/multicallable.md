# Multicallable

Contract that enables a single call to call multiple methods on itself.


<b>WARNING:</b>
This implementation is NOT to be used with ERC2771 out-of-the-box.
https://blog.openzeppelin.com/arbitrary-address-spoofing-vulnerability-erc2771context-multicall-public-disclosure
This also applies to potentially other ERCs / patterns appending to the back of calldata.

We do NOT have a check for ERC2771, as we do not inherit from OpenZeppelin's context.
Moreover, it is infeasible and inefficient for us to add checks and mitigations
for all possible ERC / patterns appending to the back of calldata.

We would highly recommend using an alternative pattern such as
https://github.com/Vectorized/multicaller
which is more flexible, futureproof, and safer by default.



<!-- customintro:start --><!-- customintro:end -->

## Functions

### multicall(bytes[])

```solidity
function multicall(bytes[] calldata data)
    public
    payable
    virtual
    returns (bytes[] memory)
```

Apply `delegatecall` with the current contract to each calldata in `data`,   
and store the `abi.encode` formatted results of each `delegatecall` into `results`.   
If any of the `delegatecall`s reverts, the entire context is reverted,   
and the error is bubbled up.   
By default, this function directly returns the results and terminates the call context.   
If you need to add before and after actions to the multicall, please override this function.

### _multicall(bytes[])

```solidity
function _multicall(bytes[] calldata data)
    internal
    virtual
    returns (bytes32 results)
```

The inner logic of `multicall`.   
This function is included so that you can override `multicall`   
to add before and after actions, and use the `_multicallDirectReturn` function.

### _multicallResultsToBytesArray(bytes32)

```solidity
function _multicallResultsToBytesArray(bytes32 results)
    internal
    pure
    virtual
    returns (bytes[] memory decoded)
```

Decodes the `results` into an array of bytes.   
This can be useful if you need to access the results or re-encode it.

### _multicallDirectReturn(bytes32)

```solidity
function _multicallDirectReturn(bytes32 results) internal pure virtual
```

Directly returns the `results` and terminates the current call context.   
`results` must be from `_multicall`, else behavior is undefined.