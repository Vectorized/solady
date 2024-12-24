# GasBurnerLib

Library for burning gas without reverting.


Intended for Contract Secured Revenue (CSR).

<b>Recommendation:</b> for the amount of gas to burn,
pass in an admin-controlled dynamic value instead of a hardcoded one.
This is so that you can adjust your contract as needed depending on market conditions,
and to give you and your users a leeway in case the L2 chain change the rules.



<!-- customintro:start --><!-- customintro:end -->

## Functions

### burnPure(uint256)

```solidity
function burnPure(uint256 x) internal pure
```

Burns approximately `x` amount of gas.

### burnView(uint256)

```solidity
function burnView(uint256 x) internal view
```

Burns approximately `x` amount of gas.

### burn(uint256)

```solidity
function burn(uint256 x) internal
```

Burns approximately `x` amount of gas.