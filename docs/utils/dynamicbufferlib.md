# DynamicBufferLib

Library for buffers with automatic capacity resizing.






<!-- customintro:start --><!-- customintro:end -->

## Structs

### DynamicBuffer

```solidity
struct DynamicBuffer {
    bytes data;
}
```

Type to represent a dynamic buffer in memory.   
You can directly assign to `data`, and the `p` function will   
take care of the memory allocation.

## Operations

Some of these functions return the same buffer for function chaining.   
e.g. `buffer.p("1").p("2")`.

### length(DynamicBuffer)

```solidity
function length(DynamicBuffer memory buffer)
    internal
    pure
    returns (uint256)
```

Shorthand for `buffer.data.length`.

### reserve(DynamicBuffer,uint256)

```solidity
function reserve(DynamicBuffer memory buffer, uint256 minimum)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Reserves at least `minimum` amount of contiguous memory.

### clear(DynamicBuffer)

```solidity
function clear(DynamicBuffer memory buffer)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Clears the buffer without deallocating the memory.

### s(DynamicBuffer)

```solidity
function s(DynamicBuffer memory buffer)
    internal
    pure
    returns (string memory)
```

Returns a string pointing to the underlying bytes data.   
Note: The string WILL change if the buffer is updated.

### p(DynamicBuffer,bytes)

```solidity
function p(DynamicBuffer memory buffer, bytes memory data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `data` to `buffer`.

### p(DynamicBuffer,bytes,bytes)

```solidity
function p(
    DynamicBuffer memory buffer,
    bytes memory data0,
    bytes memory data1
) internal pure returns (DynamicBuffer memory result)
```

Appends `data0`, `data1` to `buffer`.

### p(DynamicBuffer,bytes,bytes,bytes)

```solidity
function p(
    DynamicBuffer memory buffer,
    bytes memory data0,
    bytes memory data1,
    bytes memory data2
) internal pure returns (DynamicBuffer memory result)
```

Appends `data0` .. `data2` to `buffer`.

### p(DynamicBuffer,bytes,bytes,bytes,bytes)

```solidity
function p(
    DynamicBuffer memory buffer,
    bytes memory data0,
    bytes memory data1,
    bytes memory data2,
    bytes memory data3
) internal pure returns (DynamicBuffer memory result)
```

Appends `data0` .. `data3` to `buffer`.

### p(DynamicBuffer,bytes,bytes,bytes,bytes,bytes)

```solidity
function p(
    DynamicBuffer memory buffer,
    bytes memory data0,
    bytes memory data1,
    bytes memory data2,
    bytes memory data3,
    bytes memory data4
) internal pure returns (DynamicBuffer memory result)
```

Appends `data0` .. `data4` to `buffer`.

### p(DynamicBuffer,bytes,bytes,bytes,bytes,bytes,bytes)

```solidity
function p(
    DynamicBuffer memory buffer,
    bytes memory data0,
    bytes memory data1,
    bytes memory data2,
    bytes memory data3,
    bytes memory data4,
    bytes memory data5
) internal pure returns (DynamicBuffer memory result)
```

Appends `data0` .. `data5` to `buffer`.

### p(DynamicBuffer,bytes,bytes,bytes,bytes,bytes,bytes,bytes)

```solidity
function p(
    DynamicBuffer memory buffer,
    bytes memory data0,
    bytes memory data1,
    bytes memory data2,
    bytes memory data3,
    bytes memory data4,
    bytes memory data5,
    bytes memory data6
) internal pure returns (DynamicBuffer memory result)
```

Appends `data0` .. `data6` to `buffer`.

### pBool(DynamicBuffer,bool)

```solidity
function pBool(DynamicBuffer memory buffer, bool data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bool(data))` to buffer.

### pAddress(DynamicBuffer,address)

```solidity
function pAddress(DynamicBuffer memory buffer, address data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(address(data))` to buffer.

### pUint8(DynamicBuffer,uint8)

```solidity
function pUint8(DynamicBuffer memory buffer, uint8 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint8(data))` to buffer.

### pUint16(DynamicBuffer,uint16)

```solidity
function pUint16(DynamicBuffer memory buffer, uint16 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint16(data))` to buffer.

### pUint24(DynamicBuffer,uint24)

```solidity
function pUint24(DynamicBuffer memory buffer, uint24 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint24(data))` to buffer.

### pUint32(DynamicBuffer,uint32)

```solidity
function pUint32(DynamicBuffer memory buffer, uint32 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint32(data))` to buffer.

### pUint40(DynamicBuffer,uint40)

```solidity
function pUint40(DynamicBuffer memory buffer, uint40 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint40(data))` to buffer.

### pUint48(DynamicBuffer,uint48)

```solidity
function pUint48(DynamicBuffer memory buffer, uint48 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint48(data))` to buffer.

### pUint56(DynamicBuffer,uint56)

```solidity
function pUint56(DynamicBuffer memory buffer, uint56 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint56(data))` to buffer.

### pUint64(DynamicBuffer,uint64)

```solidity
function pUint64(DynamicBuffer memory buffer, uint64 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint64(data))` to buffer.

### pUint72(DynamicBuffer,uint72)

```solidity
function pUint72(DynamicBuffer memory buffer, uint72 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint72(data))` to buffer.

### pUint80(DynamicBuffer,uint80)

```solidity
function pUint80(DynamicBuffer memory buffer, uint80 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint80(data))` to buffer.

### pUint88(DynamicBuffer,uint88)

```solidity
function pUint88(DynamicBuffer memory buffer, uint88 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint88(data))` to buffer.

### pUint96(DynamicBuffer,uint96)

```solidity
function pUint96(DynamicBuffer memory buffer, uint96 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint96(data))` to buffer.

### pUint104(DynamicBuffer,uint104)

```solidity
function pUint104(DynamicBuffer memory buffer, uint104 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint104(data))` to buffer.

### pUint112(DynamicBuffer,uint112)

```solidity
function pUint112(DynamicBuffer memory buffer, uint112 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint112(data))` to buffer.

### pUint120(DynamicBuffer,uint120)

```solidity
function pUint120(DynamicBuffer memory buffer, uint120 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint120(data))` to buffer.

### pUint128(DynamicBuffer,uint128)

```solidity
function pUint128(DynamicBuffer memory buffer, uint128 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint128(data))` to buffer.

### pUint136(DynamicBuffer,uint136)

```solidity
function pUint136(DynamicBuffer memory buffer, uint136 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint136(data))` to buffer.

### pUint144(DynamicBuffer,uint144)

```solidity
function pUint144(DynamicBuffer memory buffer, uint144 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint144(data))` to buffer.

### pUint152(DynamicBuffer,uint152)

```solidity
function pUint152(DynamicBuffer memory buffer, uint152 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint152(data))` to buffer.

### pUint160(DynamicBuffer,uint160)

```solidity
function pUint160(DynamicBuffer memory buffer, uint160 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint160(data))` to buffer.

### pUint168(DynamicBuffer,uint168)

```solidity
function pUint168(DynamicBuffer memory buffer, uint168 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint168(data))` to buffer.

### pUint176(DynamicBuffer,uint176)

```solidity
function pUint176(DynamicBuffer memory buffer, uint176 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint176(data))` to buffer.

### pUint184(DynamicBuffer,uint184)

```solidity
function pUint184(DynamicBuffer memory buffer, uint184 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint184(data))` to buffer.

### pUint192(DynamicBuffer,uint192)

```solidity
function pUint192(DynamicBuffer memory buffer, uint192 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint192(data))` to buffer.

### pUint200(DynamicBuffer,uint200)

```solidity
function pUint200(DynamicBuffer memory buffer, uint200 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint200(data))` to buffer.

### pUint208(DynamicBuffer,uint208)

```solidity
function pUint208(DynamicBuffer memory buffer, uint208 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint208(data))` to buffer.

### pUint216(DynamicBuffer,uint216)

```solidity
function pUint216(DynamicBuffer memory buffer, uint216 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint216(data))` to buffer.

### pUint224(DynamicBuffer,uint224)

```solidity
function pUint224(DynamicBuffer memory buffer, uint224 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint224(data))` to buffer.

### pUint232(DynamicBuffer,uint232)

```solidity
function pUint232(DynamicBuffer memory buffer, uint232 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint232(data))` to buffer.

### pUint240(DynamicBuffer,uint240)

```solidity
function pUint240(DynamicBuffer memory buffer, uint240 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint240(data))` to buffer.

### pUint248(DynamicBuffer,uint248)

```solidity
function pUint248(DynamicBuffer memory buffer, uint248 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint248(data))` to buffer.

### pUint256(DynamicBuffer,uint256)

```solidity
function pUint256(DynamicBuffer memory buffer, uint256 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(uint256(data))` to buffer.

### pBytes1(DynamicBuffer,bytes1)

```solidity
function pBytes1(DynamicBuffer memory buffer, bytes1 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes1(data))` to buffer.

### pBytes2(DynamicBuffer,bytes2)

```solidity
function pBytes2(DynamicBuffer memory buffer, bytes2 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes2(data))` to buffer.

### pBytes3(DynamicBuffer,bytes3)

```solidity
function pBytes3(DynamicBuffer memory buffer, bytes3 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes3(data))` to buffer.

### pBytes4(DynamicBuffer,bytes4)

```solidity
function pBytes4(DynamicBuffer memory buffer, bytes4 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes4(data))` to buffer.

### pBytes5(DynamicBuffer,bytes5)

```solidity
function pBytes5(DynamicBuffer memory buffer, bytes5 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes5(data))` to buffer.

### pBytes6(DynamicBuffer,bytes6)

```solidity
function pBytes6(DynamicBuffer memory buffer, bytes6 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes6(data))` to buffer.

### pBytes7(DynamicBuffer,bytes7)

```solidity
function pBytes7(DynamicBuffer memory buffer, bytes7 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes7(data))` to buffer.

### pBytes8(DynamicBuffer,bytes8)

```solidity
function pBytes8(DynamicBuffer memory buffer, bytes8 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes8(data))` to buffer.

### pBytes9(DynamicBuffer,bytes9)

```solidity
function pBytes9(DynamicBuffer memory buffer, bytes9 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes9(data))` to buffer.

### pBytes10(DynamicBuffer,bytes10)

```solidity
function pBytes10(DynamicBuffer memory buffer, bytes10 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes10(data))` to buffer.

### pBytes11(DynamicBuffer,bytes11)

```solidity
function pBytes11(DynamicBuffer memory buffer, bytes11 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes11(data))` to buffer.

### pBytes12(DynamicBuffer,bytes12)

```solidity
function pBytes12(DynamicBuffer memory buffer, bytes12 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes12(data))` to buffer.

### pBytes13(DynamicBuffer,bytes13)

```solidity
function pBytes13(DynamicBuffer memory buffer, bytes13 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes13(data))` to buffer.

### pBytes14(DynamicBuffer,bytes14)

```solidity
function pBytes14(DynamicBuffer memory buffer, bytes14 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes14(data))` to buffer.

### pBytes15(DynamicBuffer,bytes15)

```solidity
function pBytes15(DynamicBuffer memory buffer, bytes15 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes15(data))` to buffer.

### pBytes16(DynamicBuffer,bytes16)

```solidity
function pBytes16(DynamicBuffer memory buffer, bytes16 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes16(data))` to buffer.

### pBytes17(DynamicBuffer,bytes17)

```solidity
function pBytes17(DynamicBuffer memory buffer, bytes17 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes17(data))` to buffer.

### pBytes18(DynamicBuffer,bytes18)

```solidity
function pBytes18(DynamicBuffer memory buffer, bytes18 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes18(data))` to buffer.

### pBytes19(DynamicBuffer,bytes19)

```solidity
function pBytes19(DynamicBuffer memory buffer, bytes19 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes19(data))` to buffer.

### pBytes20(DynamicBuffer,bytes20)

```solidity
function pBytes20(DynamicBuffer memory buffer, bytes20 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes20(data))` to buffer.

### pBytes21(DynamicBuffer,bytes21)

```solidity
function pBytes21(DynamicBuffer memory buffer, bytes21 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes21(data))` to buffer.

### pBytes22(DynamicBuffer,bytes22)

```solidity
function pBytes22(DynamicBuffer memory buffer, bytes22 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes22(data))` to buffer.

### pBytes23(DynamicBuffer,bytes23)

```solidity
function pBytes23(DynamicBuffer memory buffer, bytes23 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes23(data))` to buffer.

### pBytes24(DynamicBuffer,bytes24)

```solidity
function pBytes24(DynamicBuffer memory buffer, bytes24 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes24(data))` to buffer.

### pBytes25(DynamicBuffer,bytes25)

```solidity
function pBytes25(DynamicBuffer memory buffer, bytes25 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes25(data))` to buffer.

### pBytes26(DynamicBuffer,bytes26)

```solidity
function pBytes26(DynamicBuffer memory buffer, bytes26 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes26(data))` to buffer.

### pBytes27(DynamicBuffer,bytes27)

```solidity
function pBytes27(DynamicBuffer memory buffer, bytes27 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes27(data))` to buffer.

### pBytes28(DynamicBuffer,bytes28)

```solidity
function pBytes28(DynamicBuffer memory buffer, bytes28 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes28(data))` to buffer.

### pBytes29(DynamicBuffer,bytes29)

```solidity
function pBytes29(DynamicBuffer memory buffer, bytes29 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes29(data))` to buffer.

### pBytes30(DynamicBuffer,bytes30)

```solidity
function pBytes30(DynamicBuffer memory buffer, bytes30 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes30(data))` to buffer.

### pBytes31(DynamicBuffer,bytes31)

```solidity
function pBytes31(DynamicBuffer memory buffer, bytes31 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes31(data))` to buffer.

### pBytes32(DynamicBuffer,bytes32)

```solidity
function pBytes32(DynamicBuffer memory buffer, bytes32 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Appends `abi.encodePacked(bytes32(data))` to buffer.

### p()

```solidity
function p() internal pure returns (DynamicBuffer memory result)
```

Shorthand for returning a new buffer.

### p(bytes)

```solidity
function p(bytes memory data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `p(p(), data)`.

### p(bytes,bytes)

```solidity
function p(bytes memory data0, bytes memory data1)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `p(p(), data0, data1)`.

### p(bytes,bytes,bytes)

```solidity
function p(bytes memory data0, bytes memory data1, bytes memory data2)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `p(p(), data0, .., data2)`.

### p(bytes,bytes,bytes,bytes)

```solidity
function p(
    bytes memory data0,
    bytes memory data1,
    bytes memory data2,
    bytes memory data3
) internal pure returns (DynamicBuffer memory result)
```

Shorthand for `p(p(), data0, .., data3)`.

### p(bytes,bytes,bytes,bytes,bytes)

```solidity
function p(
    bytes memory data0,
    bytes memory data1,
    bytes memory data2,
    bytes memory data3,
    bytes memory data4
) internal pure returns (DynamicBuffer memory result)
```

Shorthand for `p(p(), data0, .., data4)`.

### p(bytes,bytes,bytes,bytes,bytes,bytes)

```solidity
function p(
    bytes memory data0,
    bytes memory data1,
    bytes memory data2,
    bytes memory data3,
    bytes memory data4,
    bytes memory data5
) internal pure returns (DynamicBuffer memory result)
```

Shorthand for `p(p(), data0, .., data5)`.

### p(bytes,bytes,bytes,bytes,bytes,bytes,bytes)

```solidity
function p(
    bytes memory data0,
    bytes memory data1,
    bytes memory data2,
    bytes memory data3,
    bytes memory data4,
    bytes memory data5,
    bytes memory data6
) internal pure returns (DynamicBuffer memory result)
```

Shorthand for `p(p(), data0, .., data6)`.

### pBool(bool)

```solidity
function pBool(bool data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBool(p(), data)`.

### pAddress(address)

```solidity
function pAddress(address data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pAddress(p(), data)`.

### pUint8(uint8)

```solidity
function pUint8(uint8 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint8(p(), data)`.

### pUint16(uint16)

```solidity
function pUint16(uint16 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint16(p(), data)`.

### pUint24(uint24)

```solidity
function pUint24(uint24 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint24(p(), data)`.

### pUint32(uint32)

```solidity
function pUint32(uint32 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint32(p(), data)`.

### pUint40(uint40)

```solidity
function pUint40(uint40 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint40(p(), data)`.

### pUint48(uint48)

```solidity
function pUint48(uint48 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint48(p(), data)`.

### pUint56(uint56)

```solidity
function pUint56(uint56 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint56(p(), data)`.

### pUint64(uint64)

```solidity
function pUint64(uint64 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint64(p(), data)`.

### pUint72(uint72)

```solidity
function pUint72(uint72 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint72(p(), data)`.

### pUint80(uint80)

```solidity
function pUint80(uint80 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint80(p(), data)`.

### pUint88(uint88)

```solidity
function pUint88(uint88 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint88(p(), data)`.

### pUint96(uint96)

```solidity
function pUint96(uint96 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint96(p(), data)`.

### pUint104(uint104)

```solidity
function pUint104(uint104 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint104(p(), data)`.

### pUint112(uint112)

```solidity
function pUint112(uint112 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint112(p(), data)`.

### pUint120(uint120)

```solidity
function pUint120(uint120 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint120(p(), data)`.

### pUint128(uint128)

```solidity
function pUint128(uint128 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint128(p(), data)`.

### pUint136(uint136)

```solidity
function pUint136(uint136 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint136(p(), data)`.

### pUint144(uint144)

```solidity
function pUint144(uint144 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint144(p(), data)`.

### pUint152(uint152)

```solidity
function pUint152(uint152 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint152(p(), data)`.

### pUint160(uint160)

```solidity
function pUint160(uint160 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint160(p(), data)`.

### pUint168(uint168)

```solidity
function pUint168(uint168 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint168(p(), data)`.

### pUint176(uint176)

```solidity
function pUint176(uint176 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint176(p(), data)`.

### pUint184(uint184)

```solidity
function pUint184(uint184 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint184(p(), data)`.

### pUint192(uint192)

```solidity
function pUint192(uint192 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint192(p(), data)`.

### pUint200(uint200)

```solidity
function pUint200(uint200 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint200(p(), data)`.

### pUint208(uint208)

```solidity
function pUint208(uint208 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint208(p(), data)`.

### pUint216(uint216)

```solidity
function pUint216(uint216 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint216(p(), data)`.

### pUint224(uint224)

```solidity
function pUint224(uint224 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint224(p(), data)`.

### pUint232(uint232)

```solidity
function pUint232(uint232 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint232(p(), data)`.

### pUint240(uint240)

```solidity
function pUint240(uint240 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint240(p(), data)`.

### pUint248(uint248)

```solidity
function pUint248(uint248 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint248(p(), data)`.

### pUint256(uint256)

```solidity
function pUint256(uint256 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pUint256(p(), data)`.

### pBytes1(bytes1)

```solidity
function pBytes1(bytes1 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes1(p(), data)`.

### pBytes2(bytes2)

```solidity
function pBytes2(bytes2 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes2(p(), data)`.

### pBytes3(bytes3)

```solidity
function pBytes3(bytes3 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes3(p(), data)`.

### pBytes4(bytes4)

```solidity
function pBytes4(bytes4 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes4(p(), data)`.

### pBytes5(bytes5)

```solidity
function pBytes5(bytes5 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes5(p(), data)`.

### pBytes6(bytes6)

```solidity
function pBytes6(bytes6 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes6(p(), data)`.

### pBytes7(bytes7)

```solidity
function pBytes7(bytes7 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes7(p(), data)`.

### pBytes8(bytes8)

```solidity
function pBytes8(bytes8 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes8(p(), data)`.

### pBytes9(bytes9)

```solidity
function pBytes9(bytes9 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes9(p(), data)`.

### pBytes10(bytes10)

```solidity
function pBytes10(bytes10 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes10(p(), data)`.

### pBytes11(bytes11)

```solidity
function pBytes11(bytes11 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes11(p(), data)`.

### pBytes12(bytes12)

```solidity
function pBytes12(bytes12 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes12(p(), data)`.

### pBytes13(bytes13)

```solidity
function pBytes13(bytes13 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes13(p(), data)`.

### pBytes14(bytes14)

```solidity
function pBytes14(bytes14 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes14(p(), data)`.

### pBytes15(bytes15)

```solidity
function pBytes15(bytes15 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes15(p(), data)`.

### pBytes16(bytes16)

```solidity
function pBytes16(bytes16 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes16(p(), data)`.

### pBytes17(bytes17)

```solidity
function pBytes17(bytes17 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes17(p(), data)`.

### pBytes18(bytes18)

```solidity
function pBytes18(bytes18 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes18(p(), data)`.

### pBytes19(bytes19)

```solidity
function pBytes19(bytes19 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes19(p(), data)`.

### pBytes20(bytes20)

```solidity
function pBytes20(bytes20 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes20(p(), data)`.

### pBytes21(bytes21)

```solidity
function pBytes21(bytes21 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes21(p(), data)`.

### pBytes22(bytes22)

```solidity
function pBytes22(bytes22 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes22(p(), data)`.

### pBytes23(bytes23)

```solidity
function pBytes23(bytes23 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes23(p(), data)`.

### pBytes24(bytes24)

```solidity
function pBytes24(bytes24 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes24(p(), data)`.

### pBytes25(bytes25)

```solidity
function pBytes25(bytes25 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes25(p(), data)`.

### pBytes26(bytes26)

```solidity
function pBytes26(bytes26 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes26(p(), data)`.

### pBytes27(bytes27)

```solidity
function pBytes27(bytes27 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes27(p(), data)`.

### pBytes28(bytes28)

```solidity
function pBytes28(bytes28 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes28(p(), data)`.

### pBytes29(bytes29)

```solidity
function pBytes29(bytes29 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes29(p(), data)`.

### pBytes30(bytes30)

```solidity
function pBytes30(bytes30 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes30(p(), data)`.

### pBytes31(bytes31)

```solidity
function pBytes31(bytes31 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes31(p(), data)`.

### pBytes32(bytes32)

```solidity
function pBytes32(bytes32 data)
    internal
    pure
    returns (DynamicBuffer memory result)
```

Shorthand for `pBytes32(p(), data)`.