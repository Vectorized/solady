// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./Script.sol";

abstract contract Test is Script {
    bool private __failed;

    function failed() public view returns (bool) {
        if (__failed) {
            return __failed;
        } else {
            return vm.load(address(vm), bytes32("failed")) != bytes32(0);
        }
    }

    function fail() internal virtual {
        vm.store(address(vm), bytes32("failed"), bytes32(uint256(1)));
        __failed = true;
    }

    // We intentionally do NOT mark these functions as pure,
    // so that importing this file into codebases built with old forge-std
    // won't trigger the compiler warning 2018.
    //
    // For performance, wherever possible, we do Solidity comparisons and
    // only make vm call if we know know the assert fails,
    // as preparing calls definitely costs more compute than doing
    // just the Solidity comparisons.

    function assertTrue(bool data) internal virtual {
        if (!data) vm.assertTrue(data);
    }

    function assertTrue(bool data, string memory err) internal virtual {
        if (!data) vm.assertTrue(data, err);
    }

    function assertFalse(bool data) internal virtual {
        if (data) vm.assertFalse(data);
    }

    function assertFalse(bool data, string memory err) internal virtual {
        if (data) vm.assertFalse(data, err);
    }

    function assertEq(bool left, bool right) internal virtual {
        if (left != right) vm.assertEq(left, right);
    }

    function assertEq(bool left, bool right, string memory err) internal virtual {
        if (left != right) vm.assertEq(left, right, err);
    }

    function assertEq(uint256 left, uint256 right) internal virtual {
        if (left != right) vm.assertEq(left, right);
    }

    function assertEq(uint256 left, uint256 right, string memory err) internal virtual {
        if (left != right) vm.assertEq(left, right, err);
    }

    function assertEqDecimal(uint256 left, uint256 right, uint256 decimals) internal virtual {
        if (left != right) vm.assertEqDecimal(left, right, decimals);
    }

    function assertEqDecimal(uint256 left, uint256 right, uint256 decimals, string memory err)
        internal
        virtual
    {
        if (left != right) vm.assertEqDecimal(left, right, decimals, err);
    }

    function assertEq(int256 left, int256 right) internal virtual {
        if (left != right) vm.assertEq(left, right);
    }

    function assertEq(int256 left, int256 right, string memory err) internal virtual {
        if (left != right) vm.assertEq(left, right, err);
    }

    function assertEqDecimal(int256 left, int256 right, uint256 decimals) internal virtual {
        if (left != right) vm.assertEqDecimal(left, right, decimals);
    }

    function assertEqDecimal(int256 left, int256 right, uint256 decimals, string memory err)
        internal
        virtual
    {
        if (left != right) vm.assertEqDecimal(left, right, decimals, err);
    }

    function assertEq(address left, address right) internal virtual {
        if (left != right) vm.assertEq(left, right);
    }

    function assertEq(address left, address right, string memory err) internal virtual {
        if (left != right) vm.assertEq(left, right, err);
    }

    function assertEq(bytes32 left, bytes32 right) internal virtual {
        if (left != right) vm.assertEq(left, right);
    }

    function assertEq(bytes32 left, bytes32 right, string memory err) internal virtual {
        if (left != right) vm.assertEq(left, right, err);
    }

    function assertEq(string memory left, string memory right) internal virtual {
        if (!__eq(left, right)) vm.assertEq(left, right);
    }

    function assertEq(string memory left, string memory right, string memory err)
        internal
        virtual
    {
        if (!__eq(left, right)) vm.assertEq(left, right, err);
    }

    function assertEq(bytes memory left, bytes memory right) internal virtual {
        if (!__eq(left, right)) vm.assertEq(left, right);
    }

    function assertEq(bytes memory left, bytes memory right, string memory err) internal virtual {
        if (!__eq(left, right)) vm.assertEq(left, right, err);
    }

    function assertEq(bool[] memory left, bool[] memory right) internal virtual {
        if (!__eq(left, right)) vm.assertEq(left, right);
    }

    function assertEq(bool[] memory left, bool[] memory right, string memory err)
        internal
        virtual
    {
        if (!__eq(left, right)) vm.assertEq(left, right, err);
    }

    function assertEq(uint256[] memory left, uint256[] memory right) internal virtual {
        if (!__eq(left, right)) vm.assertEq(left, right);
    }

    function assertEq(uint256[] memory left, uint256[] memory right, string memory err)
        internal
        virtual
    {
        if (!__eq(left, right)) vm.assertEq(left, right, err);
    }

    function assertEq(int256[] memory left, int256[] memory right) internal virtual {
        if (!__eq(left, right)) vm.assertEq(left, right);
    }

    function assertEq(int256[] memory left, int256[] memory right, string memory err)
        internal
        virtual
    {
        if (!__eq(left, right)) vm.assertEq(left, right, err);
    }

    function assertEq(address[] memory left, address[] memory right) internal virtual {
        if (!__eq(left, right)) vm.assertEq(left, right);
    }

    function assertEq(address[] memory left, address[] memory right, string memory err)
        internal
        virtual
    {
        if (!__eq(left, right)) vm.assertEq(left, right, err);
    }

    function assertEq(bytes32[] memory left, bytes32[] memory right) internal virtual {
        if (!__eq(left, right)) vm.assertEq(left, right);
    }

    function assertEq(bytes32[] memory left, bytes32[] memory right, string memory err)
        internal
        virtual
    {
        if (!__eq(left, right)) vm.assertEq(left, right, err);
    }

    function assertEq(string[] memory left, string[] memory right) internal virtual {
        if (!__eq(left, right)) vm.assertEq(left, right);
    }

    function assertEq(string[] memory left, string[] memory right, string memory err)
        internal
        virtual
    {
        if (!__eq(left, right)) vm.assertEq(left, right, err);
    }

    function assertEq(bytes[] memory left, bytes[] memory right) internal virtual {
        if (!__eq(left, right)) vm.assertEq(left, right);
    }

    function assertEq(bytes[] memory left, bytes[] memory right, string memory err)
        internal
        virtual
    {
        if (!__eq(left, right)) vm.assertEq(left, right, err);
    }

    function assertNotEq(bool left, bool right) internal virtual {
        if (left == right) vm.assertNotEq(left, right);
    }

    function assertNotEq(bool left, bool right, string memory err) internal virtual {
        if (left == right) vm.assertNotEq(left, right, err);
    }

    function assertNotEq(uint256 left, uint256 right) internal virtual {
        if (left == right) vm.assertNotEq(left, right);
    }

    function assertNotEq(uint256 left, uint256 right, string memory err) internal virtual {
        if (left == right) vm.assertNotEq(left, right, err);
    }

    function assertNotEqDecimal(uint256 left, uint256 right, uint256 decimals) internal virtual {
        if (left == right) vm.assertNotEqDecimal(left, right, decimals);
    }

    function assertNotEqDecimal(uint256 left, uint256 right, uint256 decimals, string memory err)
        internal
        virtual
    {
        if (left == right) vm.assertNotEqDecimal(left, right, decimals, err);
    }

    function assertNotEq(int256 left, int256 right) internal virtual {
        if (left == right) vm.assertNotEq(left, right);
    }

    function assertNotEq(int256 left, int256 right, string memory err) internal virtual {
        if (left == right) vm.assertNotEq(left, right, err);
    }

    function assertNotEqDecimal(int256 left, int256 right, uint256 decimals) internal virtual {
        if (left == right) vm.assertNotEqDecimal(left, right, decimals);
    }

    function assertNotEqDecimal(int256 left, int256 right, uint256 decimals, string memory err)
        internal
        virtual
    {
        if (left == right) vm.assertNotEqDecimal(left, right, decimals, err);
    }

    function assertNotEq(address left, address right) internal virtual {
        if (left == right) vm.assertNotEq(left, right);
    }

    function assertNotEq(address left, address right, string memory err) internal virtual {
        if (left == right) vm.assertNotEq(left, right, err);
    }

    function assertNotEq(bytes32 left, bytes32 right) internal virtual {
        if (left == right) vm.assertNotEq(left, right);
    }

    function assertNotEq(bytes32 left, bytes32 right, string memory err) internal virtual {
        if (left == right) vm.assertNotEq(left, right, err);
    }

    function assertNotEq(string memory left, string memory right) internal virtual {
        if (__eq(left, right)) vm.assertNotEq(left, right);
    }

    function assertNotEq(string memory left, string memory right, string memory err)
        internal
        virtual
    {
        if (__eq(left, right)) vm.assertNotEq(left, right, err);
    }

    function assertNotEq(bytes memory left, bytes memory right) internal virtual {
        if (__eq(left, right)) vm.assertNotEq(left, right);
    }

    function assertNotEq(bytes memory left, bytes memory right, string memory err)
        internal
        virtual
    {
        if (__eq(left, right)) vm.assertNotEq(left, right, err);
    }

    function assertNotEq(bool[] memory left, bool[] memory right) internal virtual {
        if (__eq(left, right)) vm.assertNotEq(left, right);
    }

    function assertNotEq(bool[] memory left, bool[] memory right, string memory err)
        internal
        virtual
    {
        if (__eq(left, right)) vm.assertNotEq(left, right, err);
    }

    function assertNotEq(uint256[] memory left, uint256[] memory right) internal virtual {
        if (__eq(left, right)) vm.assertNotEq(left, right);
    }

    function assertNotEq(uint256[] memory left, uint256[] memory right, string memory err)
        internal
        virtual
    {
        if (__eq(left, right)) vm.assertNotEq(left, right, err);
    }

    function assertNotEq(int256[] memory left, int256[] memory right) internal virtual {
        if (__eq(left, right)) vm.assertNotEq(left, right);
    }

    function assertNotEq(int256[] memory left, int256[] memory right, string memory err)
        internal
        virtual
    {
        if (__eq(left, right)) vm.assertNotEq(left, right, err);
    }

    function assertNotEq(address[] memory left, address[] memory right) internal virtual {
        if (__eq(left, right)) vm.assertNotEq(left, right);
    }

    function assertNotEq(address[] memory left, address[] memory right, string memory err)
        internal
        virtual
    {
        if (__eq(left, right)) vm.assertNotEq(left, right, err);
    }

    function assertNotEq(bytes32[] memory left, bytes32[] memory right) internal virtual {
        if (__eq(left, right)) vm.assertNotEq(left, right);
    }

    function assertNotEq(bytes32[] memory left, bytes32[] memory right, string memory err)
        internal
        virtual
    {
        if (__eq(left, right)) vm.assertNotEq(left, right, err);
    }

    function assertNotEq(string[] memory left, string[] memory right) internal virtual {
        if (__eq(left, right)) vm.assertNotEq(left, right);
    }

    function assertNotEq(string[] memory left, string[] memory right, string memory err)
        internal
        virtual
    {
        if (__eq(left, right)) vm.assertNotEq(left, right, err);
    }

    function assertNotEq(bytes[] memory left, bytes[] memory right) internal virtual {
        if (__eq(left, right)) vm.assertNotEq(left, right);
    }

    function assertNotEq(bytes[] memory left, bytes[] memory right, string memory err)
        internal
        virtual
    {
        if (__eq(left, right)) vm.assertNotEq(left, right, err);
    }

    function assertLt(uint256 left, uint256 right) internal virtual {
        if (left >= right) vm.assertLt(left, right);
    }

    function assertLt(uint256 left, uint256 right, string memory err) internal virtual {
        if (left >= right) vm.assertLt(left, right, err);
    }

    function assertLtDecimal(uint256 left, uint256 right, uint256 decimals) internal virtual {
        if (left >= right) vm.assertLtDecimal(left, right, decimals);
    }

    function assertLtDecimal(uint256 left, uint256 right, uint256 decimals, string memory err)
        internal
        virtual
    {
        if (left >= right) vm.assertLtDecimal(left, right, decimals, err);
    }

    function assertLt(int256 left, int256 right) internal virtual {
        if (left >= right) vm.assertLt(left, right);
    }

    function assertLt(int256 left, int256 right, string memory err) internal virtual {
        if (left >= right) vm.assertLt(left, right, err);
    }

    function assertLtDecimal(int256 left, int256 right, uint256 decimals) internal virtual {
        if (left >= right) vm.assertLtDecimal(left, right, decimals);
    }

    function assertLtDecimal(int256 left, int256 right, uint256 decimals, string memory err)
        internal
        virtual
    {
        if (left >= right) vm.assertLtDecimal(left, right, decimals, err);
    }

    function assertGt(uint256 left, uint256 right) internal virtual {
        if (left <= right) vm.assertGt(left, right);
    }

    function assertGt(uint256 left, uint256 right, string memory err) internal virtual {
        if (left <= right) vm.assertGt(left, right, err);
    }

    function assertGtDecimal(uint256 left, uint256 right, uint256 decimals) internal virtual {
        if (left <= right) vm.assertGtDecimal(left, right, decimals);
    }

    function assertGtDecimal(uint256 left, uint256 right, uint256 decimals, string memory err)
        internal
        virtual
    {
        if (left <= right) vm.assertGtDecimal(left, right, decimals, err);
    }

    function assertGt(int256 left, int256 right) internal virtual {
        if (left <= right) vm.assertGt(left, right);
    }

    function assertGt(int256 left, int256 right, string memory err) internal virtual {
        if (left <= right) vm.assertGt(left, right, err);
    }

    function assertGtDecimal(int256 left, int256 right, uint256 decimals) internal virtual {
        if (left <= right) vm.assertGtDecimal(left, right, decimals);
    }

    function assertGtDecimal(int256 left, int256 right, uint256 decimals, string memory err)
        internal
        virtual
    {
        if (left <= right) vm.assertGtDecimal(left, right, decimals, err);
    }

    function assertLe(uint256 left, uint256 right) internal virtual {
        if (left > right) vm.assertLe(left, right);
    }

    function assertLe(uint256 left, uint256 right, string memory err) internal virtual {
        if (left > right) vm.assertLe(left, right, err);
    }

    function assertLeDecimal(uint256 left, uint256 right, uint256 decimals) internal virtual {
        if (left > right) vm.assertLeDecimal(left, right, decimals);
    }

    function assertLeDecimal(uint256 left, uint256 right, uint256 decimals, string memory err)
        internal
        virtual
    {
        if (left > right) vm.assertLeDecimal(left, right, decimals, err);
    }

    function assertLe(int256 left, int256 right) internal virtual {
        if (left > right) vm.assertLe(left, right);
    }

    function assertLe(int256 left, int256 right, string memory err) internal virtual {
        if (left > right) vm.assertLe(left, right, err);
    }

    function assertLeDecimal(int256 left, int256 right, uint256 decimals) internal virtual {
        if (left > right) vm.assertLeDecimal(left, right, decimals);
    }

    function assertLeDecimal(int256 left, int256 right, uint256 decimals, string memory err)
        internal
        virtual
    {
        if (left > right) vm.assertLeDecimal(left, right, decimals, err);
    }

    function assertGe(uint256 left, uint256 right) internal virtual {
        if (left < right) vm.assertGe(left, right);
    }

    function assertGe(uint256 left, uint256 right, string memory err) internal virtual {
        if (left < right) vm.assertGe(left, right, err);
    }

    function assertGeDecimal(uint256 left, uint256 right, uint256 decimals) internal virtual {
        if (left < right) vm.assertGeDecimal(left, right, decimals);
    }

    function assertGeDecimal(uint256 left, uint256 right, uint256 decimals, string memory err)
        internal
        virtual
    {
        if (left < right) vm.assertGeDecimal(left, right, decimals, err);
    }

    function assertGe(int256 left, int256 right) internal virtual {
        if (left < right) vm.assertGe(left, right);
    }

    function assertGe(int256 left, int256 right, string memory err) internal virtual {
        if (left < right) vm.assertGe(left, right, err);
    }

    function assertGeDecimal(int256 left, int256 right, uint256 decimals) internal virtual {
        if (left < right) vm.assertGeDecimal(left, right, decimals);
    }

    function assertGeDecimal(int256 left, int256 right, uint256 decimals, string memory err)
        internal
        virtual
    {
        if (left < right) vm.assertGeDecimal(left, right, decimals, err);
    }

    function assertApproxEqAbs(uint256 left, uint256 right, uint256 maxDelta) internal virtual {
        vm.assertApproxEqAbs(left, right, maxDelta);
    }

    function assertApproxEqAbs(uint256 left, uint256 right, uint256 maxDelta, string memory err)
        internal
        virtual
    {
        vm.assertApproxEqAbs(left, right, maxDelta, err);
    }

    function assertApproxEqAbsDecimal(
        uint256 left,
        uint256 right,
        uint256 maxDelta,
        uint256 decimals
    ) internal virtual {
        vm.assertApproxEqAbsDecimal(left, right, maxDelta, decimals);
    }

    function assertApproxEqAbsDecimal(
        uint256 left,
        uint256 right,
        uint256 maxDelta,
        uint256 decimals,
        string memory err
    ) internal virtual {
        vm.assertApproxEqAbsDecimal(left, right, maxDelta, decimals, err);
    }

    function assertApproxEqAbs(int256 left, int256 right, uint256 maxDelta) internal virtual {
        vm.assertApproxEqAbs(left, right, maxDelta);
    }

    function assertApproxEqAbs(int256 left, int256 right, uint256 maxDelta, string memory err)
        internal
        virtual
    {
        vm.assertApproxEqAbs(left, right, maxDelta, err);
    }

    function assertApproxEqAbsDecimal(int256 left, int256 right, uint256 maxDelta, uint256 decimals)
        internal
        virtual
    {
        vm.assertApproxEqAbsDecimal(left, right, maxDelta, decimals);
    }

    function assertApproxEqAbsDecimal(
        int256 left,
        int256 right,
        uint256 maxDelta,
        uint256 decimals,
        string memory err
    ) internal virtual {
        vm.assertApproxEqAbsDecimal(left, right, maxDelta, decimals, err);
    }

    function assertApproxEqRel(
        uint256 left,
        uint256 right,
        uint256 maxPercentDelta // An 18 decimal fixed point number, where 1e18 == 100%
    ) internal virtual {
        vm.assertApproxEqRel(left, right, maxPercentDelta);
    }

    function assertApproxEqRel(
        uint256 left,
        uint256 right,
        uint256 maxPercentDelta, // An 18 decimal fixed point number, where 1e18 == 100%
        string memory err
    ) internal virtual {
        vm.assertApproxEqRel(left, right, maxPercentDelta, err);
    }

    function assertApproxEqRelDecimal(
        uint256 left,
        uint256 right,
        uint256 maxPercentDelta, // An 18 decimal fixed point number, where 1e18 == 100%
        uint256 decimals
    ) internal virtual {
        vm.assertApproxEqRelDecimal(left, right, maxPercentDelta, decimals);
    }

    function assertApproxEqRelDecimal(
        uint256 left,
        uint256 right,
        uint256 maxPercentDelta, // An 18 decimal fixed point number, where 1e18 == 100%
        uint256 decimals,
        string memory err
    ) internal virtual {
        vm.assertApproxEqRelDecimal(left, right, maxPercentDelta, decimals, err);
    }

    function assertApproxEqRel(int256 left, int256 right, uint256 maxPercentDelta)
        internal
        virtual
    {
        vm.assertApproxEqRel(left, right, maxPercentDelta);
    }

    function assertApproxEqRel(
        int256 left,
        int256 right,
        uint256 maxPercentDelta, // An 18 decimal fixed point number, where 1e18 == 100%
        string memory err
    ) internal virtual {
        vm.assertApproxEqRel(left, right, maxPercentDelta, err);
    }

    function assertApproxEqRelDecimal(
        int256 left,
        int256 right,
        uint256 maxPercentDelta, // An 18 decimal fixed point number, where 1e18 == 100%
        uint256 decimals
    ) internal virtual {
        vm.assertApproxEqRelDecimal(left, right, maxPercentDelta, decimals);
    }

    function assertApproxEqRelDecimal(
        int256 left,
        int256 right,
        uint256 maxPercentDelta, // An 18 decimal fixed point number, where 1e18 == 100%
        uint256 decimals,
        string memory err
    ) internal virtual {
        vm.assertApproxEqRelDecimal(left, right, maxPercentDelta, decimals, err);
    }

    function __eq(bool[] memory left, bool[] memory right) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(left)
            if eq(n, mload(right)) {
                returndatacopy(returndatasize(), returndatasize(), shr(128, n))
                result := 1
                let d := sub(right, left)
                for { n := add(left, shl(5, n)) } iszero(eq(left, n)) {} {
                    left := add(left, 0x20)
                    result := and(result, eq(iszero(mload(left)), iszero(mload(add(left, d)))))
                }
            }
        }
    }

    function __eq(address[] memory left, address[] memory right)
        internal
        pure
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(left)
            if eq(n, mload(right)) {
                returndatacopy(returndatasize(), returndatasize(), shr(128, n))
                result := 1
                let d := sub(right, left)
                for { n := add(left, shl(5, n)) } iszero(eq(left, n)) {} {
                    left := add(left, 0x20)
                    result := and(result, eq(shl(96, mload(left)), shl(96, mload(add(left, d)))))
                }
            }
        }
    }

    function __eq(bytes32[] memory left, bytes32[] memory right)
        internal
        pure
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(left, shl(5, add(1, mload(left))))
            result := eq(keccak256(right, shl(5, add(1, mload(right)))), result)
        }
    }

    function __eq(int256[] memory left, int256[] memory right)
        internal
        pure
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(left, shl(5, add(1, mload(left))))
            result := eq(keccak256(right, shl(5, add(1, mload(right)))), result)
        }
    }

    function __eq(uint256[] memory left, uint256[] memory right)
        internal
        pure
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(left, shl(5, add(1, mload(left))))
            result := eq(keccak256(right, shl(5, add(1, mload(right)))), result)
        }
    }

    function __eq(string[] memory left, string[] memory right)
        internal
        pure
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(left)
            if eq(n, mload(right)) {
                returndatacopy(returndatasize(), returndatasize(), shr(128, n))
                result := 1
                let d := sub(right, left)
                for { n := add(left, shl(5, n)) } iszero(eq(left, n)) {} {
                    left := add(left, 0x20)
                    let l := mload(left)
                    l := keccak256(l, add(0x20, mload(l)))
                    let r := mload(add(left, d))
                    r := keccak256(r, add(0x20, mload(r)))
                    result := and(result, eq(l, r))
                }
            }
        }
    }

    function __eq(bytes[] memory left, bytes[] memory right) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(left)
            if eq(n, mload(right)) {
                returndatacopy(returndatasize(), returndatasize(), shr(128, n))
                result := 1
                let d := sub(right, left)
                for { n := add(left, shl(5, n)) } iszero(eq(left, n)) {} {
                    left := add(left, 0x20)
                    let l := mload(left)
                    l := keccak256(l, add(0x20, mload(l)))
                    let r := mload(add(left, d))
                    r := keccak256(r, add(0x20, mload(r)))
                    result := and(result, eq(l, r))
                }
            }
        }
    }

    function __eq(string memory left, string memory right) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(left, add(0x20, mload(left)))
            result := eq(keccak256(right, add(0x20, mload(right))), result)
        }
    }

    function __eq(bytes memory left, bytes memory right) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(left, add(0x20, mload(left)))
            result := eq(keccak256(right, add(0x20, mload(right))), result)
        }
    }
}

library stdError {
    bytes public constant assertionError = abi.encodeWithSignature("Panic(uint256)", 0x01);
    bytes public constant arithmeticError = abi.encodeWithSignature("Panic(uint256)", 0x11);
    bytes public constant divisionError = abi.encodeWithSignature("Panic(uint256)", 0x12);
    bytes public constant enumConversionError = abi.encodeWithSignature("Panic(uint256)", 0x21);
    bytes public constant encodeStorageError = abi.encodeWithSignature("Panic(uint256)", 0x22);
    bytes public constant popError = abi.encodeWithSignature("Panic(uint256)", 0x31);
    bytes public constant indexOOBError = abi.encodeWithSignature("Panic(uint256)", 0x32);
    bytes public constant memOverflowError = abi.encodeWithSignature("Panic(uint256)", 0x41);
    bytes public constant zeroVarError = abi.encodeWithSignature("Panic(uint256)", 0x51);
    // DEPRECATED: Use Vm's `expectRevert` without any arguments instead
    bytes public constant lowLevelError = bytes(""); // `0x`
}
