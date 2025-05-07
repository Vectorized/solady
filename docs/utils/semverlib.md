# SemVerLib

Library for comparing SemVer.






<!-- customintro:start --><!-- customintro:end -->

## Comparison

### cmp(bytes32,bytes32)

```solidity
function cmp(bytes32 a, bytes32 b) internal pure returns (int256 result)
```

Returns -1 if `a < b`, 0 if `a == b`, 1 if `a > b`.   
For efficiency, this is a forgiving, non-reverting parser:   
- Early returns if a strict order can be determined.   
- Skips the first byte if it is `v` (case insensitive).   
- If a strict order cannot be determined, returns 0.