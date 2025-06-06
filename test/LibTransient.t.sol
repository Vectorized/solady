// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./utils/SoladyTest.sol";
import {LibTransient} from "../src/utils/LibTransient.sol";
import {LibClone} from "../src/utils/LibClone.sol";

contract A {
    address public immutable b;

    constructor() {
        b = abi.decode(LibTransient.registryGet("b"), (address));
    }
}

contract B {
    address public immutable a;

    constructor() {
        a = abi.decode(LibTransient.registryGet("a"), (address));
    }
}

contract LibTransientTest is SoladyTest {
    using LibTransient for *;

    function testSetAndGetBytesTransient() public {
        vm.chainId(2);
        _testSetAndGetBytesTransient("123");
        _testSetAndGetBytesTransient("12345678901234567890123456789012345678901234567890");
        _testSetAndGetBytesTransient("123");
    }

    function _testSetAndGetBytesTransient(bytes memory data) internal {
        LibTransient.TBytes storage p = LibTransient.tBytes(uint256(0));
        p.setCompat(data);
        assertEq(p.lengthCompat(), data.length);
        assertEq(p.getCompat(), data);
    }

    function testSetAndGetBytesTransientCalldata(
        uint256 tSlot,
        bytes calldata data0,
        bytes calldata data1
    ) public {
        vm.chainId(_randomUniform() & 3);
        unchecked {
            LibTransient.TBytes storage p0 = LibTransient.tBytes(tSlot);
            LibTransient.TBytes storage p1 = LibTransient.tBytes(tSlot + 1);
            if (_randomChance(2)) {
                p0.setCalldataCompat(data0);
                p1.setCalldataCompat(data1);
            } else {
                p0.setCompat(data0);
                p1.setCompat(data1);
            }
            assertEq(p0.getCompat(), data0);
            assertEq(p1.getCompat(), data1);
            if (_randomChance(2)) {
                p0.setCalldataCompat(data1);
                p1.setCalldataCompat(data0);
            } else {
                p0.setCompat(data1);
                p1.setCompat(data0);
            }
            assertEq(p0.getCompat(), data1);
            assertEq(p1.getCompat(), data0);
            p0.clearCompat();
            assertEq(p0.lengthCompat(), 0);
            assertEq(p0.getCompat(), "");
            assertEq(p1.getCompat(), data0);
            p1.clearCompat();
            assertEq(p1.lengthCompat(), 0);
            assertEq(p1.getCompat(), "");
            assertEq(p0.lengthCompat(), 0);
            assertEq(p0.getCompat(), "");
        }
    }

    function testSetAndGetBytesTransient(uint256 tSlot, bytes memory data) public {
        vm.chainId(_randomUniform() & 3);
        LibTransient.TBytes storage p = LibTransient.tBytes(tSlot);
        if (_randomChance(8)) data = _randomBytes();
        p.setCompat(data);
        assertEq(p.lengthCompat(), data.length);
        if (_randomChance(8)) {
            _misalignFreeMemoryPointer();
            _brutalizeMemory();
        }
        bytes memory retrieved = p.getCompat();
        _checkMemory(retrieved);
        assertEq(retrieved, data);
        p.clearCompat();
        assertEq(p.lengthCompat(), 0);
        assertEq(p.getCompat(), "");
    }

    function testSetAndGetBytesTransientCalldata(uint256 tSlot, bytes calldata data) public {
        vm.chainId(_randomUniform() & 3);
        LibTransient.TBytes storage p = LibTransient.tBytes(tSlot);
        p.setCompat(data);
        assertEq(p.lengthCompat(), data.length);
        assertEq(p.getCompat(), data);
        p.clearCompat();
        assertEq(p.lengthCompat(), 0);
        assertEq(p.getCompat(), "");
    }

    function testSetAndGetUint256Transient(uint256 tSlot, uint256 value) public {
        vm.chainId(_randomUniform() & 3);
        LibTransient.TUint256 storage p = LibTransient.tUint256(tSlot);
        p.setCompat(value);
        assertEq(p.getCompat(), value);
        p.clearCompat();
        assertEq(p.getCompat(), 0);
    }

    function testSetAndGetInt256Transient(uint256 tSlot, int256 value) public {
        vm.chainId(_randomUniform() & 3);
        LibTransient.TInt256 storage p = LibTransient.tInt256(tSlot);
        p.setCompat(value);
        assertEq(p.getCompat(), value);
        p.clearCompat();
        assertEq(p.getCompat(), 0);
    }

    function testSetAndGetAddressTransient(uint256 tSlot, address value) public {
        vm.chainId(_randomUniform() & 3);
        LibTransient.TAddress storage p = LibTransient.tAddress(tSlot);
        p.setCompat(_brutalized(value));
        assertEq(p.getCompat(), value);
        p.clearCompat();
        assertEq(p.getCompat(), address(0));
    }

    function testSetAndGetBytes32Transient(uint256 tSlot, bytes32 value) public {
        vm.chainId(_randomUniform() & 3);
        LibTransient.TBytes32 storage p = LibTransient.tBytes32(tSlot);
        p.setCompat(value);
        assertEq(p.getCompat(), value);
        p.clearCompat();
        assertEq(p.getCompat(), bytes32(0));
    }

    function testSetAndGetBoolTransient(uint256 tSlot, bool value) public {
        vm.chainId(_randomUniform() & 3);
        LibTransient.TBool storage p = LibTransient.tBool(tSlot);
        p.setCompat(_brutalized(value));
        assertEq(p.getCompat(), value);
        p.clearCompat();
        assertEq(p.getCompat(), false);
    }

    function testUint256IncDecTransient() public {
        for (uint256 c; c < 3; ++c) {
            vm.chainId(c);
            uint256 tSlot;
            LibTransient.TUint256 storage p = LibTransient.tUint256(tSlot);
            p.setCompat(10);
            assertEq(this.tUintIncCompat(tSlot), 11);
            assertEq(p.getCompat(), 11);
            assertEq(this.tUintIncCompat(tSlot, 20), 31);
            assertEq(p.getCompat(), 31);
            p.setCompat(2 ** 256 - 2);
            assertEq(this.tUintIncCompat(tSlot), 2 ** 256 - 1);
            assertEq(p.getCompat(), 2 ** 256 - 1);
            vm.expectRevert();
            this.tUintIncCompat(tSlot);
            vm.expectRevert();
            this.tUintIncCompat(tSlot, 10);
            assertEq(this.tUintDecCompat(tSlot), 2 ** 256 - 2);
            assertEq(p.getCompat(), 2 ** 256 - 2);
            p.setCompat(10);
            assertEq(this.tUintDecCompat(tSlot, 5), 5);
            assertEq(p.getCompat(), 5);
            assertEq(this.tUintDecCompat(tSlot, 5), 0);
            assertEq(p.getCompat(), 0);
            vm.expectRevert();
            this.tUintDecCompat(tSlot);
            vm.expectRevert();
            this.tUintDecCompat(tSlot, 5);
            p.setCompat(10);
            assertEq(this.tUintIncSignedCompat(tSlot, 1), 11);
            assertEq(p.getCompat(), 11);
            assertEq(this.tUintIncSignedCompat(tSlot, -1), 10);
            assertEq(p.getCompat(), 10);
            assertEq(this.tUintDecSignedCompat(tSlot, 1), 9);
            assertEq(p.getCompat(), 9);
            assertEq(this.tUintDecSignedCompat(tSlot, -1), 10);
            assertEq(p.getCompat(), 10);
        }
    }

    function tUintIncSignedCompat(uint256 tSlot, int256 delta) public returns (uint256) {
        return LibTransient.tUint256(tSlot).incSignedCompat(delta);
    }

    function tUintDecSignedCompat(uint256 tSlot, int256 delta) public returns (uint256) {
        return LibTransient.tUint256(tSlot).decSignedCompat(delta);
    }

    function tUintIncCompat(uint256 tSlot, uint256 delta) public returns (uint256) {
        return LibTransient.tUint256(tSlot).incCompat(delta);
    }

    function tUintDecCompat(uint256 tSlot, uint256 delta) public returns (uint256) {
        return LibTransient.tUint256(tSlot).decCompat(delta);
    }

    function tUintIncCompat(uint256 tSlot) public returns (uint256) {
        return LibTransient.tUint256(tSlot).incCompat();
    }

    function tUintDecCompat(uint256 tSlot) public returns (uint256) {
        return LibTransient.tUint256(tSlot).decCompat();
    }

    function tIntIncCompat(uint256 tSlot, int256 delta) public returns (int256) {
        return LibTransient.tInt256(tSlot).incCompat(delta);
    }

    function tIntDecCompat(uint256 tSlot, int256 delta) public returns (int256) {
        return LibTransient.tInt256(tSlot).decCompat(delta);
    }

    function tIntIncCompat(uint256 tSlot) public returns (int256) {
        return LibTransient.tInt256(tSlot).incCompat();
    }

    function tIntDecCompat(uint256 tSlot) public returns (int256) {
        return LibTransient.tInt256(tSlot).decCompat();
    }

    function testSetBytesTransientRevertsIfLengthTooBig(uint256 n) public {
        n = _bound(n, 0x100000000, type(uint256).max);
        vm.chainId(_randomUniform() & 3);
        vm.expectRevert();
        this.setBytesTransientWithLengthTooBig(n);
    }

    function testSetBytesTransientRevertsIfLengthTooBigCalldata(uint256 n) public {
        n = _bound(n, 0x100000000, type(uint256).max);
        vm.chainId(_randomUniform() & 3);
        vm.expectRevert();
        this.setBytesTransientWithLengthTooBigCalldata(n);
    }

    function setBytesTransientWithLengthTooBig(uint256 n) public {
        bytes memory data;
        /// @solidity memory-safe-assembly
        assembly {
            data := mload(0x40)
            mstore(data, n)
            mstore(0x40, add(data, 0x20))
        }
        LibTransient.tBytes(uint256(0)).setCompat(data);
    }

    function setBytesTransientWithLengthTooBigCalldata(uint256 n) public {
        bytes calldata data;
        /// @solidity memory-safe-assembly
        assembly {
            data.offset := 0
            data.length := n
        }
        LibTransient.tBytes(uint256(0)).setCalldataCompat(data);
    }

    function testStackPlacePopBytes() public {
        testStackPlacePopBytes(type(uint256).max, 0, 1);
    }

    function testStackPlacePopBytes(uint256 r, uint256 aStackSlot, uint256 bStackSlot) public {
        bytes[] memory aValues = new bytes[]((r >> 8) & 0x7);
        bytes[] memory bValues = new bytes[]((r >> 16) & 0x7);
        if (aStackSlot == bStackSlot) {
            bStackSlot = aStackSlot ^ 1;
        }
        for (uint256 i; i < aValues.length; ++i) {
            aValues[i] = abi.encodePacked(keccak256(abi.encode(i, aStackSlot)), "hehe");
            LibTransient.tStack(aStackSlot).place().tBytes().set(aValues[i]);
        }
        for (uint256 i; i < bValues.length; ++i) {
            bValues[i] = abi.encodePacked(keccak256(abi.encode(i, bStackSlot)));
            LibTransient.tStack(bStackSlot).place().tBytes().set(bValues[i]);
        }
        if (aValues.length > 0) {
            bytes memory expected = aValues[aValues.length - 1];
            assertEq(LibTransient.tStack(aStackSlot).top().tBytes().get(), expected);
            assertEq(LibTransient.tStack(aStackSlot).peek().tBytes().get(), expected);
            assertGt(uint256(LibTransient.tStack(aStackSlot).peek()), 0);
        } else {
            assertEq(uint256(LibTransient.tStack(aStackSlot).peek()), 0);
            assertEq(LibTransient.tStack(aStackSlot).peek().tBytes().get(), "");
        }
        if (bValues.length > 0) {
            bytes memory expected = bValues[bValues.length - 1];
            assertEq(LibTransient.tStack(bStackSlot).top().tBytes().get(), expected);
            assertEq(LibTransient.tStack(bStackSlot).peek().tBytes().get(), expected);
            assertGt(uint256(LibTransient.tStack(bStackSlot).peek()), 0);
        } else {
            assertEq(uint256(LibTransient.tStack(bStackSlot).peek()), 0);
            assertEq(LibTransient.tStack(bStackSlot).peek().tBytes().get(), "");
        }
        for (uint256 i; i < aValues.length; ++i) {
            bytes memory expected = aValues[aValues.length - 1 - i];
            assertEq(LibTransient.tStack(aStackSlot).pop().tBytes().get(), expected);
        }
        for (uint256 i; i < bValues.length; ++i) {
            bytes memory expected = bValues[bValues.length - 1 - i];
            assertEq(LibTransient.tStack(bStackSlot).pop().tBytes().get(), expected);
        }
    }

    function testStackPlacePopClear(bytes32 stackSlot) public {
        uint256 n = _randomUniform() & 7;
        for (uint256 i; i < n; ++i) {
            assertEq(LibTransient.tStack(stackSlot).length(), i);
            bytes32 x = keccak256(abi.encode(i));
            LibTransient.tStack(stackSlot).place().tBytes32().set(x);
            assertEq(LibTransient.tStack(stackSlot).top().tBytes32().get(), x);
            assertEq(LibTransient.tStack(stackSlot).peek().tBytes32().get(), x);
        }
        assertEq(LibTransient.tStack(stackSlot).length(), n);

        LibTransient.tStack(stackSlot).clear();
        assertEq(LibTransient.tStack(stackSlot).peek(), 0);
        if (stackSlot != 0) {
            assertEq(LibTransient.tStack(stackSlot).peek().tBytes32().get(), 0);
        }

        assertEq(LibTransient.tStack(stackSlot).length(), 0);
        for (uint256 i; i < n; ++i) {
            assertEq(LibTransient.tStack(stackSlot).length(), i);
            assertEq(LibTransient.tStack(stackSlot).place().tBytes32().get(), 0);
        }
    }

    function testStackPeekTrick(uint256 base, uint256 n, uint256 r) public pure {
        check_StackPeekTrick(base, n, r);
    }

    function check_StackPeekTrick(uint256 base, uint256 n, uint256 r) public pure {
        n = (n & 0xffffffffffffffff) | 1;
        unchecked {
            uint256 s = base * 0x9e076501211e1371b + ((n * 0x100000000) | (r << 128));
            assert(s != 0);
        }
    }

    function testEmptyStackTopReverts() public {
        vm.expectRevert(LibTransient.StackIsEmpty.selector);
        this.stackTop(0);
    }

    function testEmptyStackPopReverts() public {
        vm.expectRevert(LibTransient.StackIsEmpty.selector);
        this.stackPop(0);
    }

    function stackTop(uint256 stackSlot) public view returns (bytes32) {
        return LibTransient.tStack(stackSlot).top();
    }

    function stackPop(uint256 stackSlot) public returns (bytes32) {
        return LibTransient.tStack(stackSlot).pop();
    }

    function testRegistry(bytes32 key, bytes memory value) public {
        _etchTransientRegistry();
        if (_randomChance(2)) {
            vm.expectRevert(bytes4(keccak256("TransientRegistryUnauthorized()")));
            this.registryClear(key);
        }

        this.registrySet(key, value);
        assertEq(this.registryGet(key), value);
        assertEq(this.registryAdminOf(key), address(this));

        if (_randomChance(2)) {
            address newAdmin = _randomUniqueHashedAddress();
            vm.expectRevert(bytes4(keccak256("TransientRegistryUnauthorized()")));
            this.registrySet(newAdmin, key, value);
        }

        if (_randomChance(2)) {
            vm.expectRevert(bytes4(keccak256("TransientRegistryNewAdminIsZeroAddress()")));
            this.registryChangeAdmin(key, address(0));
        }

        if (_randomChance(2)) {
            address newAdmin = _randomUniqueHashedAddress();
            uint256 newAdminRaw = uint256(uint160(newAdmin));
            if (_randomChance(2)) newAdminRaw |= _random() << 160;

            bool success;
            if (newAdminRaw >> 160 == 0) {
                if (_randomChance(2)) {
                    (success,) = LibTransient.REGISTRY.call(
                        abi.encodeWithSignature("changeAdmin(bytes32,address)", key, newAdminRaw)
                    );
                    assertTrue(success);
                } else {
                    this.registryChangeAdmin(key, newAdmin);
                }
            } else {
                (success,) = LibTransient.REGISTRY.call(
                    abi.encodeWithSignature("changeAdmin(bytes32,address)", key, newAdminRaw)
                );
                assertFalse(success);
                newAdminRaw = (newAdminRaw << 96) >> 96;
                (success,) = LibTransient.REGISTRY.call(
                    abi.encodeWithSignature("changeAdmin(bytes32,address)", key, newAdminRaw)
                );
                assertTrue(success);
            }

            assertEq(this.registryAdminOf(key), newAdmin);
            if (_randomChance(2)) return;

            bytes memory anotherValue = _randomBytes();
            this.registrySet(newAdmin, key, anotherValue);
            assertEq(this.registryGet(key), anotherValue);
            assertEq(this.registryAdminOf(key), newAdmin);

            this.registryChangeAdmin(newAdmin, key, address(this));
        }

        if (_randomChance(2)) {
            if (_randomChance(2)) this.registryClear(key);
            bytes memory anotherValue = _randomBytes();
            this.registrySet(key, anotherValue);
            assertEq(this.registryGet(key), anotherValue);
            assertEq(this.registryAdminOf(key), address(this));
        }

        if (_randomChance(2)) {
            this.registryClear(key);
            vm.expectRevert(bytes4(keccak256("TransientRegistryKeyDoesNotExist()")));
            this.registryGet(key);
            assertEq(this.registryAdminOf(key), address(0));

            if (_randomChance(2)) return;

            address newAdmin = _randomUniqueHashedAddress();
            this.registrySet(newAdmin, key, value);
            assertEq(this.registryGet(key), value);
            assertEq(this.registryAdminOf(key), newAdmin);
        }
    }

    function testRegistryAB() public {
        _etchTransientRegistry();
        bytes32 aInitCodeHash = keccak256(type(A).creationCode);
        bytes32 bInitCodeHash = keccak256(type(B).creationCode);
        address aAddress = LibClone.predictDeterministicAddress(aInitCodeHash, 0, _NICKS_FACTORY);
        address bAddress = LibClone.predictDeterministicAddress(bInitCodeHash, 0, _NICKS_FACTORY);
        this.registrySet("a", abi.encode(aAddress));
        this.registrySet("b", abi.encode(bAddress));
        A a = new A();
        B b = new B();
        assertEq(a.b(), bAddress);
        assertEq(b.a(), aAddress);
    }

    function testRegistryNotDeployed() public {
        bytes memory value = _randomBytes();
        bytes memory empty;

        vm.expectRevert(empty);
        this.registrySet(bytes32(_randomUniform()), value);

        vm.expectRevert(empty);
        this.registryGet(bytes32(_randomUniform()));

        vm.expectRevert(empty);
        this.registryClear(bytes32(_randomUniform()));

        vm.expectRevert(empty);
        this.registryChangeAdmin(bytes32(_randomUniform()), _randomUniqueHashedAddress());

        vm.expectRevert(empty);
        this.registryAdminOf(bytes32(_randomUniform()));
    }

    function registrySet(bytes32 hash, bytes memory value) public {
        LibTransient.registrySet(hash, value);
        _checkMemory();
    }

    function registrySet(address pranker, bytes32 hash, bytes memory value) public {
        vm.prank(pranker);
        registrySet(hash, value);
    }

    function registryGet(bytes32 hash) public view returns (bytes memory result) {
        result = LibTransient.registryGet(hash);
        _checkMemory(result);
    }

    function registryClear(address pranker, bytes32 hash) public {
        vm.prank(pranker);
        registryClear(hash);
    }

    function registryClear(bytes32 hash) public {
        LibTransient.registryClear(hash);
        _checkMemory();
    }

    function registryChangeAdmin(address pranker, bytes32 hash, address newAdmin) public {
        vm.prank(pranker);
        registryChangeAdmin(hash, newAdmin);
    }

    function registryChangeAdmin(bytes32 hash, address newAdmin) public {
        LibTransient.registryChangeAdmin(hash, newAdmin);
        _checkMemory();
    }

    function registryAdminOf(bytes32 hash) public view returns (address) {
        return LibTransient.registryAdminOf(hash);
    }

    function _etchTransientRegistry() internal {
        bytes32 salt = 0x00000000000000000000000000000000000000001ef0fa4e834693009a3bcdbc;
        bytes memory initializationCode =
            hex"6080604052348015600e575f5ffd5b506104d48061001c5f395ff3fe608060405234801561000f575f5ffd5b5060043610610064575f3560e01c806397040a451161004d57806397040a45146100b0578063aac438c0146100c3578063c5344411146100d6575f5ffd5b8063053b1ca3146100685780638eaa6ac014610090575b5f5ffd5b61007b610076366004610395565b61010e565b60405190151581526020015b60405180910390f35b6100a361009e3660046103db565b61016e565b60405161008791906103f2565b61007b6100be3660046103db565b610227565b61007b6100d1366004610427565b61029f565b6100e96100e43660046103db565b610361565b60405173ffffffffffffffffffffffffffffffffffffffff9091168152602001610087565b5f8161012157634396ac1b5f526004601cfd5b825f527f2c96949beeb8aca2ef85b169c5bca920576b836c1cb3edaa443380aff09df99b60205260405f20805c33146101615763860170335f526004601cfd5b82815d5060015f5260205ff35b6060815f527f2c96949beeb8aca2ef85b169c5bca920576b836c1cb3edaa443380aff09df99b60205260405f205c6101ad57639bdc798f5f526004601cfd5b7fc8f6675aac5818d398110f4d0e7276685c19f1a74e66eed262c8a6aa9aabaedf60205260405f20604051602081015f8152825c601c8201528051806020830101601d821061021757845f528260205f2003603c84015b8082015c81526020018281106102045750505b5f81526020845283810360200184f35b5f815f527f2c96949beeb8aca2ef85b169c5bca920576b836c1cb3edaa443380aff09df99b60205260405f2033815c146102685763860170335f526004601cfd5b5f815d507fc8f6675aac5818d398110f4d0e7276685c19f1a74e66eed262c8a6aa9aabaedf6020525f60405f205d60015f5260205ff35b5f835f527f2c96949beeb8aca2ef85b169c5bca920576b836c1cb3edaa443380aff09df99b60205260405f20805c80156102e7573381146102e75763860170335f526004601cfd5b5033815d507fc8f6675aac5818d398110f4d0e7276685c19f1a74e66eed262c8a6aa9aabaedf60205260405f20833560201c8360e01b17815d601d831061035757805f528284016020858560201c5f036020175f200301601c86015b80358282015d602001828110610343575050505b5060015f5260205ff35b5f815f527f2c96949beeb8aca2ef85b169c5bca920576b836c1cb3edaa443380aff09df99b60205260405f205c5f5260205ff35b5f5f604083850312156103a6575f5ffd5b82359150602083013573ffffffffffffffffffffffffffffffffffffffff811681146103d0575f5ffd5b809150509250929050565b5f602082840312156103eb575f5ffd5b5035919050565b602081525f82518060208401528060208501604085015e5f604082850101526040601f19601f83011684010191505092915050565b5f5f5f60408486031215610439575f5ffd5b83359250602084013567ffffffffffffffff811115610456575f5ffd5b8401601f81018613610466575f5ffd5b803567ffffffffffffffff81111561047c575f5ffd5b86602082840101111561048d575f5ffd5b93966020919091019550929350505056fea2646970667358221220af8785b9665e5c7f00368ff4d9720b2d4f4b6d2d9eb7be97936fba46cc7e6dcd64736f6c634300081c0033";
        address deployment = _nicksCreate2(0, salt, initializationCode);
        assertEq(deployment, LibTransient.REGISTRY);
    }
}
