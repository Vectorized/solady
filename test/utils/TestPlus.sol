// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Brutalizer} from "./Brutalizer.sol";

contract TestPlus is Brutalizer {
    event LogString(string name, string value);
    event LogString(string value);
    event LogBytes(string name, bytes value);
    event LogBytes(bytes value);
    event LogUint(string name, uint256 value);
    event LogUint(uint256 value);
    event LogBytes32(string name, bytes32 value);
    event LogBytes32(bytes32 value);
    event LogInt(string name, int256 value);
    event LogInt(int256 value);
    event LogAddress(string name, address value);
    event LogAddress(address value);
    event LogBool(string name, bool value);
    event LogBool(bool value);

    event LogStringArray(string name, string[] value);
    event LogStringArray(string[] value);
    event LogBytesArray(string name, bytes[] value);
    event LogBytesArray(bytes[] value);
    event LogUintArray(string name, uint256[] value);
    event LogUintArray(uint256[] value);
    event LogBytes32Array(string name, bytes32[] value);
    event LogBytes32Array(bytes32[] value);
    event LogIntArray(string name, int256[] value);
    event LogIntArray(int256[] value);
    event LogAddressArray(string name, address[] value);
    event LogAddressArray(address[] value);
    event LogBoolArray(string name, bool[] value);
    event LogBoolArray(bool[] value);

    /// @dev `address(bytes20(uint160(uint256(keccak256("hevm cheat code")))))`.
    address private constant _VM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    /// @dev This is the keccak256 of a very long string I randomly mashed on my keyboard.
    uint256 private constant _TESTPLUS_RANDOMNESS_SLOT =
        0xd715531fe383f818c5f158c342925dcf01b954d24678ada4d07c36af0f20e1ee;

    /// @dev The maximum private key.
    uint256 private constant _PRIVATE_KEY_MAX =
        0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140;

    /// @dev Some constant to brutalize the upper bits of addresses.
    uint256 private constant _ADDRESS_BRUTALIZER = 0xc0618c2bfd481dcf3e31738f;

    /// @dev Multiplier for a mulmod Lehmer psuedorandom number generator.
    /// Prime, and a primitive root of `_LPRNG_MODULO`.
    uint256 private constant _LPRNG_MULTIPLIER = 0x100000000000000000000000000000051;

    /// @dev Modulo for a mulmod Lehmer psuedorandom number generator. (prime)
    uint256 private constant _LPRNG_MODULO =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff43;

    /// @dev Returns whether the `value` has been generated for `typeId` and `groupId` before.
    function __markAsGenerated(bytes32 typeId, bytes32 groupId, uint256 value)
        private
        returns (bool isSet)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, value)
            mstore(0x20, groupId)
            mstore(0x40, typeId)
            mstore(0x60, _TESTPLUS_RANDOMNESS_SLOT)
            let s := keccak256(0x00, 0x80)
            isSet := sload(s)
            sstore(s, 1)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero pointer.
        }
    }

    /// @dev Returns a pseudorandom random number from [0 .. 2**256 - 1] (inclusive).
    /// For usage in fuzz tests, please ensure that the function has an unnamed uint256 argument.
    /// e.g. `testSomething(uint256) public`.
    /// This function may return a previously returned result.
    function _random() internal returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := _TESTPLUS_RANDOMNESS_SLOT
            let sValue := sload(result)
            mstore(0x20, sValue)
            let r := keccak256(0x20, 0x40)
            // If the storage is uninitialized, initialize it to the keccak256 of the calldata.
            if iszero(sValue) {
                sValue := result
                calldatacopy(mload(0x40), 0x00, calldatasize())
                r := keccak256(mload(0x40), calldatasize())
            }
            sstore(result, add(r, 1))

            // Do some biased sampling for more robust tests.
            // prettier-ignore
            for {} 1 {} {
                let y := mulmod(r, _LPRNG_MULTIPLIER, _LPRNG_MODULO)
                // With a 1/256 chance, randomly set `r` to any of 0,1,2,3.
                if iszero(byte(19, y)) {
                    r := and(byte(11, y), 3)
                    break
                }
                let d := byte(17, y)
                // With a 1/2 chance, set `r` to near a random power of 2.
                if iszero(and(2, d)) {
                    // Set `t` either `not(0)` or `xor(sValue, r)`.
                    let t := or(xor(sValue, r), sub(0, and(1, d)))
                    // Set `r` to `t` shifted left or right.
                    // prettier-ignore
                    for {} 1 {} {
                        if iszero(and(8, d)) {
                            if iszero(and(16, d)) { t := 1 }
                            if iszero(and(32, d)) {
                                r := add(shl(shl(3, and(byte(7, y), 31)), t), sub(3, and(7, r)))
                                break
                            }
                            r := add(shl(byte(7, y), t), sub(511, and(1023, r)))
                            break
                        }
                        if iszero(and(16, d)) { t := shl(255, 1) }
                        if iszero(and(32, d)) {
                            r := add(shr(shl(3, and(byte(7, y), 31)), t), sub(3, and(7, r)))
                            break
                        }
                        r := add(shr(byte(7, y), t), sub(511, and(1023, r)))
                        break
                    }
                    // With a 1/2 chance, negate `r`.
                    r := xor(sub(0, shr(7, d)), r)
                    break
                }
                // Otherwise, just set `r` to `xor(sValue, r)`.
                r := xor(sValue, r)
                break
            }
            result := r
        }
    }

    /// @dev Returns a pseudorandom random number from [0 .. 2**256 - 1] (inclusive).
    /// For usage in fuzz tests, please ensure that the function has an unnamed uint256 argument.
    /// e.g. `testSomething(uint256) public`.
    function _randomUnique(uint256 groupId) internal returns (uint256 result) {
        result = _randomUnique(bytes32(groupId));
    }

    /// @dev Returns a pseudorandom random number from [0 .. 2**256 - 1] (inclusive).
    /// For usage in fuzz tests, please ensure that the function has an unnamed uint256 argument.
    /// e.g. `testSomething(uint256) public`.
    function _randomUnique(bytes32 groupId) internal returns (uint256 result) {
        do {
            result = _random();
        } while (__markAsGenerated("uint256", groupId, result));
    }

    /// @dev Returns a pseudorandom random number from [0 .. 2**256 - 1] (inclusive).
    /// For usage in fuzz tests, please ensure that the function has an unnamed uint256 argument.
    /// e.g. `testSomething(uint256) public`.
    function _randomUnique() internal returns (uint256 result) {
        result = _randomUnique("");
    }

    /// @dev Returns a pseudorandom number, uniformly distributed in [0 .. 2**256 - 1] (inclusive).
    function _randomUniform() internal returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := _TESTPLUS_RANDOMNESS_SLOT
            // prettier-ignore
            for { let sValue := sload(result) } 1 {} {
                // If the storage is uninitialized, initialize it to the keccak256 of the calldata.
                if iszero(sValue) {
                    calldatacopy(mload(0x40), 0x00, calldatasize())
                    sValue := keccak256(mload(0x40), calldatasize())
                    sstore(result, sValue)
                    result := sValue
                    break
                }
                mstore(0x1f, sValue)
                sValue := keccak256(0x20, 0x40)
                sstore(result, sValue)
                result := sValue
                break
            }
        }
    }

    /// @dev Returns a boolean with an approximately 1/n chance of being true.
    /// This function may return a previously returned result.
    function _randomChance(uint256 n) internal returns (bool result) {
        uint256 r = _randomUniform();
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(mod(r, n))
        }
    }

    /// @dev Returns a random private key that can be used for ECDSA signing.
    /// This function may return a previously returned result.
    function _randomPrivateKey() internal returns (uint256 result) {
        result = _randomUniform();
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                if iszero(and(result, 0x10)) {
                    if iszero(and(result, 0x20)) {
                        result := add(and(result, 0xf), 1)
                        break
                    }
                    result := sub(_PRIVATE_KEY_MAX, and(result, 0xf))
                    break
                }
                result := shr(1, result)
                break
            }
        }
    }

    /// @dev Returns a random private key that can be used for ECDSA signing.
    function _randomUniquePrivateKey(uint256 groupId) internal returns (uint256 result) {
        result = _randomUniquePrivateKey(bytes32(groupId));
    }

    /// @dev Returns a random private key that can be used for ECDSA signing.
    function _randomUniquePrivateKey(bytes32 groupId) internal returns (uint256 result) {
        do {
            result = _randomPrivateKey();
        } while (__markAsGenerated("uint256", groupId, result));
    }

    /// @dev Returns a random private key that can be used for ECDSA signing.
    function _randomUniquePrivateKey() internal returns (uint256 result) {
        result = _randomUniquePrivateKey("");
    }

    /// @dev Private helper function to get the signer from a private key.
    function __getSigner(uint256 privateKey) private view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0xffa18649) // `addr(uint256)`.
            mstore(0x20, privateKey)
            result := mload(staticcall(gas(), _VM_ADDRESS, 0x1c, 0x24, 0x01, 0x20))
        }
    }

    /// @dev Private helper to ensure an address is brutalized.
    function __toBrutalizedAddress(address a) private pure returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(0x00, 0x88)
            result := xor(shl(160, xor(result, _ADDRESS_BRUTALIZER)), a)
            mstore(0x10, result)
        }
    }

    /// @dev Private helper to ensure an address is brutalized.
    function __toBrutalizedAddress(uint256 a) private pure returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(0x00, 0x88)
            result := xor(shl(160, xor(result, _ADDRESS_BRUTALIZER)), a)
            mstore(0x10, result)
        }
    }

    /// @dev Returns a pseudorandom signer and its private key.
    /// This function may return a previously returned result.
    /// The signer may have dirty upper 96 bits.
    function _randomSigner() internal returns (address signer, uint256 privateKey) {
        privateKey = _randomPrivateKey();
        signer = __toBrutalizedAddress(__getSigner(privateKey));
    }

    /// @dev Returns a pseudorandom signer and its private key.
    /// The signer may have dirty upper 96 bits.
    function _randomUniqueSigner(uint256 groupId)
        internal
        returns (address signer, uint256 privateKey)
    {
        (signer, privateKey) = _randomUniqueSigner(bytes32(groupId));
    }

    /// @dev Returns a pseudorandom signer and its private key.
    /// The signer may have dirty upper 96 bits.
    function _randomUniqueSigner(bytes32 groupId)
        internal
        returns (address signer, uint256 privateKey)
    {
        privateKey = _randomUniquePrivateKey(groupId);
        signer = __toBrutalizedAddress(__getSigner(privateKey));
    }

    /// @dev Returns a pseudorandom signer and its private key.
    /// The signer may have dirty upper 96 bits.
    function _randomUniqueSigner() internal returns (address signer, uint256 privateKey) {
        (signer, privateKey) = _randomUniqueSigner("");
    }

    /// @dev Returns a pseudorandom address.
    /// The result may have dirty upper 96 bits.
    /// This function will not return an existing contract.
    /// This function may return a previously returned result.
    function _randomAddress() internal returns (address result) {
        uint256 r = _randomUniform();
        /// @solidity memory-safe-assembly
        assembly {
            result := xor(shl(158, r), and(sub(7, shr(252, r)), r))
        }
    }

    /// @dev Returns a pseudorandom address.
    /// The result may have dirty upper 96 bits.
    /// This function will not return an existing contract.
    function _randomUniqueAddress(uint256 groupId) internal returns (address result) {
        result = _randomUniqueAddress(bytes32(groupId));
    }

    /// @dev Returns a pseudorandom address.
    /// The result may have dirty upper 96 bits.
    /// This function will not return an existing contract.
    function _randomUniqueAddress(bytes32 groupId) internal returns (address result) {
        do {
            result = _randomAddress();
        } while (__markAsGenerated("address", groupId, uint160(result)));
    }

    /// @dev Returns a pseudorandom address.
    /// The result may have dirty upper 96 bits.
    /// This function will not return an existing contract.
    function _randomUniqueAddress() internal returns (address result) {
        result = _randomUniqueAddress("");
    }

    /// @dev Returns a pseudorandom non-zero address.
    /// The result may have dirty upper 96 bits.
    /// This function will not return an existing contract.
    /// This function may return a previously returned result.
    function _randomNonZeroAddress() internal returns (address result) {
        uint256 r = _randomUniform();
        /// @solidity memory-safe-assembly
        assembly {
            result := xor(shl(158, r), and(sub(7, shr(252, r)), r))
            if iszero(shl(96, result)) {
                mstore(0x00, result)
                result := keccak256(0x00, 0x30)
            }
        }
    }

    /// @dev Returns a pseudorandom non-zero address.
    /// The result may have dirty upper 96 bits.
    /// This function will not return an existing contract.
    function _randomUniqueNonZeroAddress(uint256 groupId) internal returns (address result) {
        result = _randomUniqueNonZeroAddress(bytes32(groupId));
    }

    /// @dev Returns a pseudorandom non-zero address.
    /// The result may have dirty upper 96 bits.
    /// This function will not return an existing contract.
    function _randomUniqueNonZeroAddress(bytes32 groupId) internal returns (address result) {
        do {
            result = _randomNonZeroAddress();
        } while (__markAsGenerated("address", groupId, uint160(result)));
    }

    /// @dev Returns a pseudorandom non-zero address.
    /// The result may have dirty upper 96 bits.
    /// This function will not return an existing contract.
    function _randomUniqueNonZeroAddress() internal returns (address result) {
        result = _randomUniqueNonZeroAddress("");
    }

    /// @dev Cleans the upper 96 bits of the address.
    /// This is included so that CI passes for older solc versions with --via-ir.
    function _cleaned(address a) internal pure returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := shr(96, shl(96, a))
        }
    }

    /// @dev Returns a pseudorandom address.
    /// The result may have dirty upper 96 bits.
    /// This function may return a previously returned result.
    function _randomAddressWithVmVars() internal returns (address result) {
        if (_randomChance(8)) result = __toBrutalizedAddress(_randomVmVar());
        else result = _randomAddress();
    }

    /// @dev Returns a pseudorandom non-zero address.
    /// The result may have dirty upper 96 bits.
    /// This function may return a previously returned result.
    function _randomNonZeroAddressWithVmVars() internal returns (address result) {
        do {
            if (_randomChance(8)) result = __toBrutalizedAddress(_randomVmVar());
            else result = _randomAddress();
        } while (result == address(0));
    }

    /// @dev Returns a random variable in the virtual machine.
    function _randomVmVar() internal returns (uint256 result) {
        uint256 r = _randomUniform();
        uint256 t = r % 11;
        if (t <= 4) {
            if (t == 0) return uint160(address(this));
            if (t == 1) return uint160(tx.origin);
            if (t == 2) return uint160(msg.sender);
            if (t == 3) return uint160(_VM_ADDRESS);
            if (t == 4) return uint160(0x000000000000000000636F6e736F6c652e6c6f67);
        }
        uint256 y = r >> 32;
        if (t == 5) {
            /// @solidity memory-safe-assembly
            assembly {
                mstore(0x00, r)
                codecopy(0x00, mod(and(y, 0xffff), add(codesize(), 0x20)), 0x20)
                result := mload(0x00)
            }
            return result;
        }
        if (t == 6) {
            /// @solidity memory-safe-assembly
            assembly {
                calldatacopy(0x00, mod(and(y, 0xffff), add(calldatasize(), 0x20)), 0x20)
                result := mload(0x00)
            }
            return result;
        }
        if (t == 7) {
            /// @solidity memory-safe-assembly
            assembly {
                let m := mload(0x40)
                returndatacopy(m, 0x00, returndatasize())
                result := mload(add(m, mod(and(y, 0xffff), add(returndatasize(), 0x20))))
            }
            return result;
        }
        if (t == 8) {
            /// @solidity memory-safe-assembly
            assembly {
                result := sload(and(y, 0xff))
            }
            return result;
        }
        if (t == 9) {
            /// @solidity memory-safe-assembly
            assembly {
                result := mload(mod(y, add(mload(0x40), 0x40)))
            }
            return result;
        }
        result = __getSigner(_randomPrivateKey());
    }

    /// @dev Returns a pseudorandom hashed address.
    /// The result may have dirty upper 96 bits.
    /// This function will not return an existing contract.
    /// This function will not return a precompile address.
    /// This function will not return a zero address.
    /// This function may return a previously returned result.
    function _randomHashedAddress() internal returns (address result) {
        uint256 r = _randomUniform();
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x1f, and(sub(7, shr(252, r)), r))
            calldatacopy(0x00, 0x00, 0x24)
            result := keccak256(0x00, 0x3f)
        }
    }

    /// @dev Returns a pseudorandom address.
    function _randomUniqueHashedAddress(uint256 groupId) internal returns (address result) {
        result = _randomUniqueHashedAddress(bytes32(groupId));
    }

    /// @dev Returns a pseudorandom address.
    function _randomUniqueHashedAddress(bytes32 groupId) internal returns (address result) {
        do {
            result = _randomHashedAddress();
        } while (__markAsGenerated("address", groupId, uint160(result)));
    }

    /// @dev Returns a pseudorandom address.
    function _randomUniqueHashedAddress() internal returns (address result) {
        result = _randomUniqueHashedAddress("");
    }

    /// @dev Private helper function for returning random bytes.
    function __randomBytes(bool zeroRightPad) private returns (bytes memory result) {
        uint256 r = _randomUniform();
        /// @solidity memory-safe-assembly
        assembly {
            let n := and(r, 0x1ffff)
            let t := shr(24, r)
            for {} 1 {} {
                // With a 1/256 chance, just return the zero pointer as the result.
                if iszero(and(t, 0xff0)) {
                    result := 0x60
                    break
                }
                result := mload(0x40)
                // With a 15/16 chance, set the length to be
                // exponentially distributed in the range [0,255] (inclusive).
                if shr(252, r) { n := shr(and(t, 0x7), byte(5, r)) }
                // Store some fixed word at the start of the string.
                // We want this function to sometimes return duplicates.
                mstore(add(result, 0x20), xor(calldataload(0x00), _TESTPLUS_RANDOMNESS_SLOT))
                // With a 1/2 chance, copy the contract code to the start and end.
                if iszero(and(t, 0x1000)) {
                    // Copy to the start.
                    if iszero(and(t, 0x2000)) { codecopy(result, byte(1, r), codesize()) }
                    // Copy to the end.
                    codecopy(add(result, n), byte(2, r), 0x40)
                }
                // With a 1/16 chance, randomize the start and end.
                if iszero(and(t, 0xf0000)) {
                    let y := mulmod(r, _LPRNG_MULTIPLIER, _LPRNG_MODULO)
                    mstore(add(result, 0x20), y)
                    mstore(add(result, n), xor(r, y))
                }
                // With a 1/256 chance, make the result entirely zero bytes.
                if iszero(byte(4, r)) { codecopy(result, codesize(), add(n, 0x20)) }
                // Skip the zero-right-padding if not required.
                if iszero(zeroRightPad) {
                    mstore(0x40, add(n, add(0x40, result))) // Allocate memory.
                    mstore(result, n) // Store the length.
                    break
                }
                mstore(add(add(result, 0x20), n), 0) // Zeroize the word after the result.
                mstore(0x40, add(n, add(0x60, result))) // Allocate memory.
                mstore(result, n) // Store the length.
                break
            }
        }
    }

    /// @dev Returns a random bytes string from 0 to 131071 bytes long.
    /// This random bytes string may NOT be zero-right-padded.
    /// This is intentional for memory robustness testing.
    /// This function may return a previously returned result.
    function _randomBytes() internal returns (bytes memory result) {
        result = __randomBytes(false);
    }

    /// @dev Returns a random bytes string from 0 to 131071 bytes long.
    /// This function may return a previously returned result.
    function _randomBytesZeroRightPadded() internal returns (bytes memory result) {
        result = __randomBytes(true);
    }

    /// @dev Truncate the bytes to `n` bytes.
    /// Returns the result for function chaining.
    function _truncateBytes(bytes memory b, uint256 n)
        internal
        pure
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if gt(mload(b), n) { mstore(b, n) }
            result := b
        }
    }

    /// @dev Returns the free memory pointer.
    function _freeMemoryPointer() internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
        }
    }

    /// @dev Increments the free memory pointer by a world.
    function _incrementFreeMemoryPointer() internal pure {
        uint256 word = 0x20;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, add(mload(0x40), word))
        }
    }

    /// @dev Adapted from `bound`:
    /// https://github.com/foundry-rs/forge-std/blob/ff4bf7db008d096ea5a657f2c20516182252a3ed/src/StdUtils.sol#L10
    /// Differentially fuzzed tested against the original implementation.
    function _hem(uint256 x, uint256 min, uint256 max)
        internal
        pure
        virtual
        returns (uint256 result)
    {
        require(min <= max, "Max is less than min.");
        /// @solidity memory-safe-assembly
        assembly {
            // prettier-ignore
            for {} 1 {} {
                // If `x` is between `min` and `max`, return `x` directly.
                // This is to ensure that dictionary values
                // do not get shifted if the min is nonzero.
                // More info: https://github.com/foundry-rs/forge-std/issues/188
                if iszero(or(lt(x, min), gt(x, max))) {
                    result := x
                    break
                }
                let size := add(sub(max, min), 1)
                if lt(gt(x, 3), gt(size, x)) {
                    result := add(min, x)
                    break
                }
                if lt(lt(x, not(3)), gt(size, not(x))) {
                    result := sub(max, not(x))
                    break
                }
                // Otherwise, wrap x into the range [min, max],
                // i.e. the range is inclusive.
                if iszero(lt(x, max)) {
                    let d := sub(x, max)
                    let r := mod(d, size)
                    if iszero(r) {
                        result := max
                        break
                    }
                    result := sub(add(min, r), 1)
                    break
                }
                let d := sub(min, x)
                let r := mod(d, size)
                if iszero(r) {
                    result := min
                    break
                }
                result := add(sub(max, r), 1)
                break
            }
        }
    }

    /// @dev Deploys a contract via 0age's immutable create 2 factory for testing.
    function _safeCreate2(uint256 payableAmount, bytes32 salt, bytes memory initializationCode)
        internal
        returns (address deploymentAddress)
    {
        // Canonical address of 0age's immutable create 2 factory.
        address c2f = 0x0000000000FFe8B47B3e2130213B802212439497;
        uint256 c2fCodeLength;
        /// @solidity memory-safe-assembly
        assembly {
            c2fCodeLength := extcodesize(c2f)
        }
        if (c2fCodeLength == 0) {
            bytes memory ic2fBytecode =
                hex"60806040526004361061003f5760003560e01c806308508b8f1461004457806364e030871461009857806385cf97ab14610138578063a49a7c90146101bc575b600080fd5b34801561005057600080fd5b506100846004803603602081101561006757600080fd5b503573ffffffffffffffffffffffffffffffffffffffff166101ec565b604080519115158252519081900360200190f35b61010f600480360360408110156100ae57600080fd5b813591908101906040810160208201356401000000008111156100d057600080fd5b8201836020820111156100e257600080fd5b8035906020019184600183028401116401000000008311171561010457600080fd5b509092509050610217565b6040805173ffffffffffffffffffffffffffffffffffffffff9092168252519081900360200190f35b34801561014457600080fd5b5061010f6004803603604081101561015b57600080fd5b8135919081019060408101602082013564010000000081111561017d57600080fd5b82018360208201111561018f57600080fd5b803590602001918460018302840111640100000000831117156101b157600080fd5b509092509050610592565b3480156101c857600080fd5b5061010f600480360360408110156101df57600080fd5b508035906020013561069e565b73ffffffffffffffffffffffffffffffffffffffff1660009081526020819052604090205460ff1690565b600083606081901c33148061024c57507fffffffffffffffffffffffffffffffffffffffff0000000000000000000000008116155b6102a1576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260458152602001806107746045913960600191505060405180910390fd5b606084848080601f0160208091040260200160405190810160405280939291908181526020018383808284376000920182905250604051855195965090943094508b93508692506020918201918291908401908083835b6020831061033557805182527fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe090920191602091820191016102f8565b51815160209384036101000a7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff018019909216911617905260408051929094018281037fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe00183528085528251928201929092207fff000000000000000000000000000000000000000000000000000000000000008383015260609890981b7fffffffffffffffffffffffffffffffffffffffff00000000000000000000000016602183015260358201969096526055808201979097528251808203909701875260750182525084519484019490942073ffffffffffffffffffffffffffffffffffffffff81166000908152938490529390922054929350505060ff16156104a7576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252603f815260200180610735603f913960400191505060405180910390fd5b81602001825188818334f5955050508073ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff161461053a576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260468152602001806107b96046913960600191505060405180910390fd5b50505073ffffffffffffffffffffffffffffffffffffffff8116600090815260208190526040902080547fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff001660011790559392505050565b6000308484846040516020018083838082843760408051919093018181037fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe001825280845281516020928301207fff000000000000000000000000000000000000000000000000000000000000008383015260609990991b7fffffffffffffffffffffffffffffffffffffffff000000000000000000000000166021820152603581019790975260558088019890985282518088039098018852607590960182525085519585019590952073ffffffffffffffffffffffffffffffffffffffff81166000908152948590529490932054939450505060ff909116159050610697575060005b9392505050565b604080517fff000000000000000000000000000000000000000000000000000000000000006020808301919091523060601b6021830152603582018590526055808301859052835180840390910181526075909201835281519181019190912073ffffffffffffffffffffffffffffffffffffffff81166000908152918290529190205460ff161561072e575060005b9291505056fe496e76616c696420636f6e7472616374206372656174696f6e202d20636f6e74726163742068617320616c7265616479206265656e206465706c6f7965642e496e76616c69642073616c74202d206669727374203230206279746573206f66207468652073616c74206d757374206d617463682063616c6c696e6720616464726573732e4661696c656420746f206465706c6f7920636f6e7472616374207573696e672070726f76696465642073616c7420616e6420696e697469616c697a6174696f6e20636f64652ea265627a7a723058202bdc55310d97c4088f18acf04253db593f0914059f0c781a9df3624dcef0d1cf64736f6c634300050a0032";
            /// @solidity memory-safe-assembly
            assembly {
                let m := mload(0x40)
                mstore(m, 0xb4d6c782) // `etch(address,bytes)`.
                mstore(add(m, 0x20), c2f)
                mstore(add(m, 0x40), 0x40)
                let n := mload(ic2fBytecode)
                mstore(add(m, 0x60), n)
                for { let i := 0 } lt(i, n) { i := add(0x20, i) } {
                    mstore(add(add(m, 0x80), i), mload(add(add(ic2fBytecode, 0x20), i)))
                }
                pop(call(gas(), _VM_ADDRESS, 0, add(m, 0x1c), add(n, 0x64), 0x00, 0x00))
            }
        }
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mload(initializationCode)
            mstore(m, 0x64e03087) // `safeCreate2(bytes32,bytes)`.
            mstore(add(m, 0x20), salt)
            mstore(add(m, 0x40), 0x40)
            mstore(add(m, 0x60), n)
            // prettier-ignore
            for { let i := 0 } lt(i, n) { i := add(i, 0x20) } {
                mstore(add(add(m, 0x80), i), mload(add(add(initializationCode, 0x20), i)))
            }
            if iszero(call(gas(), c2f, payableAmount, add(m, 0x1c), add(n, 0x64), m, 0x20)) {
                returndatacopy(m, m, returndatasize())
                revert(m, returndatasize())
            }
            deploymentAddress := mload(m)
        }
    }

    /// @dev Deploys a contract via 0age's immutable create 2 factory for testing.
    function _safeCreate2(bytes32 salt, bytes memory initializationCode)
        internal
        returns (address deploymentAddress)
    {
        deploymentAddress = _safeCreate2(0, salt, initializationCode);
    }

    /// @dev This function will make forge's gas output display the approximate codesize of
    /// the test contract as the amount of gas burnt. Useful for quick guess checking if
    /// certain optimizations actually compiles to similar bytecode.
    function test__codesize() external view {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is the contract itself (i.e. recursive call), burn all the gas.
            if eq(caller(), address()) { invalid() }
            mstore(0x00, 0xf09ff470) // Store the function selector of `test__codesize()`.
            pop(staticcall(codesize(), address(), 0x1c, 0x04, 0x00, 0x00))
        }
    }
}
