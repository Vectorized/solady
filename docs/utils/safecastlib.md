# SafeCastLib

Safe integer casting library that reverts on overflow.


Optimized for runtime gas for very high number of optimizer runs (i.e. >= 1000000).



<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### Overflow()

```solidity
error Overflow()
```

Unable to cast to the target type due to overflow.

## Unsigned Integer Safe Casting Operations

### toUint8(uint256)

```solidity
function toUint8(uint256 x) internal pure returns (uint8)
```

Casts `x` to a uint8. Reverts on overflow.

### toUint16(uint256)

```solidity
function toUint16(uint256 x) internal pure returns (uint16)
```

Casts `x` to a uint16. Reverts on overflow.

### toUint24(uint256)

```solidity
function toUint24(uint256 x) internal pure returns (uint24)
```

Casts `x` to a uint24. Reverts on overflow.

### toUint32(uint256)

```solidity
function toUint32(uint256 x) internal pure returns (uint32)
```

Casts `x` to a uint32. Reverts on overflow.

### toUint40(uint256)

```solidity
function toUint40(uint256 x) internal pure returns (uint40)
```

Casts `x` to a uint40. Reverts on overflow.

### toUint48(uint256)

```solidity
function toUint48(uint256 x) internal pure returns (uint48)
```

Casts `x` to a uint48. Reverts on overflow.

### toUint56(uint256)

```solidity
function toUint56(uint256 x) internal pure returns (uint56)
```

Casts `x` to a uint56. Reverts on overflow.

### toUint64(uint256)

```solidity
function toUint64(uint256 x) internal pure returns (uint64)
```

Casts `x` to a uint64. Reverts on overflow.

### toUint72(uint256)

```solidity
function toUint72(uint256 x) internal pure returns (uint72)
```

Casts `x` to a uint72. Reverts on overflow.

### toUint80(uint256)

```solidity
function toUint80(uint256 x) internal pure returns (uint80)
```

Casts `x` to a uint80. Reverts on overflow.

### toUint88(uint256)

```solidity
function toUint88(uint256 x) internal pure returns (uint88)
```

Casts `x` to a uint88. Reverts on overflow.

### toUint96(uint256)

```solidity
function toUint96(uint256 x) internal pure returns (uint96)
```

Casts `x` to a uint96. Reverts on overflow.

### toUint104(uint256)

```solidity
function toUint104(uint256 x) internal pure returns (uint104)
```

Casts `x` to a uint104. Reverts on overflow.

### toUint112(uint256)

```solidity
function toUint112(uint256 x) internal pure returns (uint112)
```

Casts `x` to a uint112. Reverts on overflow.

### toUint120(uint256)

```solidity
function toUint120(uint256 x) internal pure returns (uint120)
```

Casts `x` to a uint120. Reverts on overflow.

### toUint128(uint256)

```solidity
function toUint128(uint256 x) internal pure returns (uint128)
```

Casts `x` to a uint128. Reverts on overflow.

### toUint136(uint256)

```solidity
function toUint136(uint256 x) internal pure returns (uint136)
```

Casts `x` to a uint136. Reverts on overflow.

### toUint144(uint256)

```solidity
function toUint144(uint256 x) internal pure returns (uint144)
```

Casts `x` to a uint144. Reverts on overflow.

### toUint152(uint256)

```solidity
function toUint152(uint256 x) internal pure returns (uint152)
```

Casts `x` to a uint152. Reverts on overflow.

### toUint160(uint256)

```solidity
function toUint160(uint256 x) internal pure returns (uint160)
```

Casts `x` to a uint160. Reverts on overflow.

### toUint168(uint256)

```solidity
function toUint168(uint256 x) internal pure returns (uint168)
```

Casts `x` to a uint168. Reverts on overflow.

### toUint176(uint256)

```solidity
function toUint176(uint256 x) internal pure returns (uint176)
```

Casts `x` to a uint176. Reverts on overflow.

### toUint184(uint256)

```solidity
function toUint184(uint256 x) internal pure returns (uint184)
```

Casts `x` to a uint184. Reverts on overflow.

### toUint192(uint256)

```solidity
function toUint192(uint256 x) internal pure returns (uint192)
```

Casts `x` to a uint192. Reverts on overflow.

### toUint200(uint256)

```solidity
function toUint200(uint256 x) internal pure returns (uint200)
```

Casts `x` to a uint200. Reverts on overflow.

### toUint208(uint256)

```solidity
function toUint208(uint256 x) internal pure returns (uint208)
```

Casts `x` to a uint208. Reverts on overflow.

### toUint216(uint256)

```solidity
function toUint216(uint256 x) internal pure returns (uint216)
```

Casts `x` to a uint216. Reverts on overflow.

### toUint224(uint256)

```solidity
function toUint224(uint256 x) internal pure returns (uint224)
```

Casts `x` to a uint224. Reverts on overflow.

### toUint232(uint256)

```solidity
function toUint232(uint256 x) internal pure returns (uint232)
```

Casts `x` to a uint232. Reverts on overflow.

### toUint240(uint256)

```solidity
function toUint240(uint256 x) internal pure returns (uint240)
```

Casts `x` to a uint240. Reverts on overflow.

### toUint248(uint256)

```solidity
function toUint248(uint256 x) internal pure returns (uint248)
```

Casts `x` to a uint248. Reverts on overflow.

## Signed Integer Safe Casting Operations

### toInt8(int256)

```solidity
function toInt8(int256 x) internal pure returns (int8)
```

Casts `x` to a int8. Reverts on overflow.

### toInt16(int256)

```solidity
function toInt16(int256 x) internal pure returns (int16)
```

Casts `x` to a int16. Reverts on overflow.

### toInt24(int256)

```solidity
function toInt24(int256 x) internal pure returns (int24)
```

Casts `x` to a int24. Reverts on overflow.

### toInt32(int256)

```solidity
function toInt32(int256 x) internal pure returns (int32)
```

Casts `x` to a int32. Reverts on overflow.

### toInt40(int256)

```solidity
function toInt40(int256 x) internal pure returns (int40)
```

Casts `x` to a int40. Reverts on overflow.

### toInt48(int256)

```solidity
function toInt48(int256 x) internal pure returns (int48)
```

Casts `x` to a int48. Reverts on overflow.

### toInt56(int256)

```solidity
function toInt56(int256 x) internal pure returns (int56)
```

Casts `x` to a int56. Reverts on overflow.

### toInt64(int256)

```solidity
function toInt64(int256 x) internal pure returns (int64)
```

Casts `x` to a int64. Reverts on overflow.

### toInt72(int256)

```solidity
function toInt72(int256 x) internal pure returns (int72)
```

Casts `x` to a int72. Reverts on overflow.

### toInt80(int256)

```solidity
function toInt80(int256 x) internal pure returns (int80)
```

Casts `x` to a int80. Reverts on overflow.

### toInt88(int256)

```solidity
function toInt88(int256 x) internal pure returns (int88)
```

Casts `x` to a int88. Reverts on overflow.

### toInt96(int256)

```solidity
function toInt96(int256 x) internal pure returns (int96)
```

Casts `x` to a int96. Reverts on overflow.

### toInt104(int256)

```solidity
function toInt104(int256 x) internal pure returns (int104)
```

Casts `x` to a int104. Reverts on overflow.

### toInt112(int256)

```solidity
function toInt112(int256 x) internal pure returns (int112)
```

Casts `x` to a int112. Reverts on overflow.

### toInt120(int256)

```solidity
function toInt120(int256 x) internal pure returns (int120)
```

Casts `x` to a int120. Reverts on overflow.

### toInt128(int256)

```solidity
function toInt128(int256 x) internal pure returns (int128)
```

Casts `x` to a int128. Reverts on overflow.

### toInt136(int256)

```solidity
function toInt136(int256 x) internal pure returns (int136)
```

Casts `x` to a int136. Reverts on overflow.

### toInt144(int256)

```solidity
function toInt144(int256 x) internal pure returns (int144)
```

Casts `x` to a int144. Reverts on overflow.

### toInt152(int256)

```solidity
function toInt152(int256 x) internal pure returns (int152)
```

Casts `x` to a int152. Reverts on overflow.

### toInt160(int256)

```solidity
function toInt160(int256 x) internal pure returns (int160)
```

Casts `x` to a int160. Reverts on overflow.

### toInt168(int256)

```solidity
function toInt168(int256 x) internal pure returns (int168)
```

Casts `x` to a int168. Reverts on overflow.

### toInt176(int256)

```solidity
function toInt176(int256 x) internal pure returns (int176)
```

Casts `x` to a int176. Reverts on overflow.

### toInt184(int256)

```solidity
function toInt184(int256 x) internal pure returns (int184)
```

Casts `x` to a int184. Reverts on overflow.

### toInt192(int256)

```solidity
function toInt192(int256 x) internal pure returns (int192)
```

Casts `x` to a int192. Reverts on overflow.

### toInt200(int256)

```solidity
function toInt200(int256 x) internal pure returns (int200)
```

Casts `x` to a int200. Reverts on overflow.

### toInt208(int256)

```solidity
function toInt208(int256 x) internal pure returns (int208)
```

Casts `x` to a int208. Reverts on overflow.

### toInt216(int256)

```solidity
function toInt216(int256 x) internal pure returns (int216)
```

Casts `x` to a int216. Reverts on overflow.

### toInt224(int256)

```solidity
function toInt224(int256 x) internal pure returns (int224)
```

Casts `x` to a int224. Reverts on overflow.

### toInt232(int256)

```solidity
function toInt232(int256 x) internal pure returns (int232)
```

Casts `x` to a int232. Reverts on overflow.

### toInt240(int256)

```solidity
function toInt240(int256 x) internal pure returns (int240)
```

Casts `x` to a int240. Reverts on overflow.

### toInt248(int256)

```solidity
function toInt248(int256 x) internal pure returns (int248)
```

Casts `x` to a int248. Reverts on overflow.

## Other Safe Casting Operations

### toInt8(uint256)

```solidity
function toInt8(uint256 x) internal pure returns (int8)
```

Casts `x` to a int8. Reverts on overflow.

### toInt16(uint256)

```solidity
function toInt16(uint256 x) internal pure returns (int16)
```

Casts `x` to a int16. Reverts on overflow.

### toInt24(uint256)

```solidity
function toInt24(uint256 x) internal pure returns (int24)
```

Casts `x` to a int24. Reverts on overflow.

### toInt32(uint256)

```solidity
function toInt32(uint256 x) internal pure returns (int32)
```

Casts `x` to a int32. Reverts on overflow.

### toInt40(uint256)

```solidity
function toInt40(uint256 x) internal pure returns (int40)
```

Casts `x` to a int40. Reverts on overflow.

### toInt48(uint256)

```solidity
function toInt48(uint256 x) internal pure returns (int48)
```

Casts `x` to a int48. Reverts on overflow.

### toInt56(uint256)

```solidity
function toInt56(uint256 x) internal pure returns (int56)
```

Casts `x` to a int56. Reverts on overflow.

### toInt64(uint256)

```solidity
function toInt64(uint256 x) internal pure returns (int64)
```

Casts `x` to a int64. Reverts on overflow.

### toInt72(uint256)

```solidity
function toInt72(uint256 x) internal pure returns (int72)
```

Casts `x` to a int72. Reverts on overflow.

### toInt80(uint256)

```solidity
function toInt80(uint256 x) internal pure returns (int80)
```

Casts `x` to a int80. Reverts on overflow.

### toInt88(uint256)

```solidity
function toInt88(uint256 x) internal pure returns (int88)
```

Casts `x` to a int88. Reverts on overflow.

### toInt96(uint256)

```solidity
function toInt96(uint256 x) internal pure returns (int96)
```

Casts `x` to a int96. Reverts on overflow.

### toInt104(uint256)

```solidity
function toInt104(uint256 x) internal pure returns (int104)
```

Casts `x` to a int104. Reverts on overflow.

### toInt112(uint256)

```solidity
function toInt112(uint256 x) internal pure returns (int112)
```

Casts `x` to a int112. Reverts on overflow.

### toInt120(uint256)

```solidity
function toInt120(uint256 x) internal pure returns (int120)
```

Casts `x` to a int120. Reverts on overflow.

### toInt128(uint256)

```solidity
function toInt128(uint256 x) internal pure returns (int128)
```

Casts `x` to a int128. Reverts on overflow.

### toInt136(uint256)

```solidity
function toInt136(uint256 x) internal pure returns (int136)
```

Casts `x` to a int136. Reverts on overflow.

### toInt144(uint256)

```solidity
function toInt144(uint256 x) internal pure returns (int144)
```

Casts `x` to a int144. Reverts on overflow.

### toInt152(uint256)

```solidity
function toInt152(uint256 x) internal pure returns (int152)
```

Casts `x` to a int152. Reverts on overflow.

### toInt160(uint256)

```solidity
function toInt160(uint256 x) internal pure returns (int160)
```

Casts `x` to a int160. Reverts on overflow.

### toInt168(uint256)

```solidity
function toInt168(uint256 x) internal pure returns (int168)
```

Casts `x` to a int168. Reverts on overflow.

### toInt176(uint256)

```solidity
function toInt176(uint256 x) internal pure returns (int176)
```

Casts `x` to a int176. Reverts on overflow.

### toInt184(uint256)

```solidity
function toInt184(uint256 x) internal pure returns (int184)
```

Casts `x` to a int184. Reverts on overflow.

### toInt192(uint256)

```solidity
function toInt192(uint256 x) internal pure returns (int192)
```

Casts `x` to a int192. Reverts on overflow.

### toInt200(uint256)

```solidity
function toInt200(uint256 x) internal pure returns (int200)
```

Casts `x` to a int200. Reverts on overflow.

### toInt208(uint256)

```solidity
function toInt208(uint256 x) internal pure returns (int208)
```

Casts `x` to a int208. Reverts on overflow.

### toInt216(uint256)

```solidity
function toInt216(uint256 x) internal pure returns (int216)
```

Casts `x` to a int216. Reverts on overflow.

### toInt224(uint256)

```solidity
function toInt224(uint256 x) internal pure returns (int224)
```

Casts `x` to a int224. Reverts on overflow.

### toInt232(uint256)

```solidity
function toInt232(uint256 x) internal pure returns (int232)
```

Casts `x` to a int232. Reverts on overflow.

### toInt240(uint256)

```solidity
function toInt240(uint256 x) internal pure returns (int240)
```

Casts `x` to a int240. Reverts on overflow.

### toInt248(uint256)

```solidity
function toInt248(uint256 x) internal pure returns (int248)
```

Casts `x` to a int248. Reverts on overflow.

### toInt256(uint256)

```solidity
function toInt256(uint256 x) internal pure returns (int256)
```

Casts `x` to a int256. Reverts on overflow.

### toUint256(int256)

```solidity
function toUint256(int256 x) internal pure returns (uint256)
```

Casts `x` to a uint256. Reverts on overflow.