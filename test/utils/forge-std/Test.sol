// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./Script.sol";
import "ds-test/test.sol";

// Wrappers around Cheatcodes to avoid footguns
abstract contract Test is DSTest, Script {
    uint256 internal constant UINT256_MAX =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    /*//////////////////////////////////////////////////////////////////////////
                                    STD-LOGS
    //////////////////////////////////////////////////////////////////////////*/

    event log_array(uint256[] val);
    event log_array(int256[] val);
    event log_array(address[] val);
    event log_named_array(string key, uint256[] val);
    event log_named_array(string key, int256[] val);
    event log_named_array(string key, address[] val);

    /*//////////////////////////////////////////////////////////////////////////
                                    STD-ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function fail(string memory err) internal virtual {
        emit log_named_string("Error", err);
        fail();
    }

    function assertFalse(bool data) internal virtual {
        assertTrue(!data);
    }

    function assertFalse(bool data, string memory err) internal virtual {
        assertTrue(!data, err);
    }

    function assertEq(bool a, bool b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [bool]");
            emit log_named_string("  Expected", b ? "true" : "false");
            emit log_named_string("    Actual", a ? "true" : "false");
            fail();
        }
    }

    function assertEq(bool a, bool b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(bytes memory a, bytes memory b) internal {
        assertEq0(a, b);
    }

    function assertEq(bytes memory a, bytes memory b, string memory err) internal {
        assertEq0(a, b, err);
    }

    function assertEq(uint256[] memory a, uint256[] memory b) internal {
        bool inputsEq;
        /// @solidity memory-safe-assembly
        assembly {
            inputsEq :=
                eq(keccak256(a, shl(5, add(mload(a), 1))), keccak256(b, shl(5, add(mload(b), 1))))
        }
        if (!inputsEq) {
            emit log("Error: a == b not satisfied [uint[]]");
            emit log_named_array("  Expected", b);
            emit log_named_array("    Actual", a);
            fail();
        }
    }

    function assertEq(int256[] memory a, int256[] memory b) internal {
        bool inputsEq;
        /// @solidity memory-safe-assembly
        assembly {
            inputsEq :=
                eq(keccak256(a, shl(5, add(mload(a), 1))), keccak256(b, shl(5, add(mload(b), 1))))
        }
        if (!inputsEq) {
            emit log("Error: a == b not satisfied [int[]]");
            emit log_named_array("  Expected", b);
            emit log_named_array("    Actual", a);
            fail();
        }
    }

    function assertEq(address[] memory a, address[] memory b) internal {
        bool inputsEq;
        /// @solidity memory-safe-assembly
        assembly {
            inputsEq :=
                eq(keccak256(a, shl(5, add(mload(a), 1))), keccak256(b, shl(5, add(mload(b), 1))))
        }
        if (!inputsEq) {
            emit log("Error: a == b not satisfied [address[]]");
            emit log_named_array("  Expected", b);
            emit log_named_array("    Actual", a);
            fail();
        }
    }

    function assertEq(uint256[] memory a, uint256[] memory b, string memory err) internal {
        bool inputsEq;
        /// @solidity memory-safe-assembly
        assembly {
            inputsEq :=
                eq(keccak256(a, shl(5, add(mload(a), 1))), keccak256(b, shl(5, add(mload(b), 1))))
        }
        if (!inputsEq) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(int256[] memory a, int256[] memory b, string memory err) internal {
        bool inputsEq;
        /// @solidity memory-safe-assembly
        assembly {
            inputsEq :=
                eq(keccak256(a, shl(5, add(mload(a), 1))), keccak256(b, shl(5, add(mload(b), 1))))
        }
        if (!inputsEq) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(address[] memory a, address[] memory b, string memory err) internal {
        bool inputsEq;
        /// @solidity memory-safe-assembly
        assembly {
            inputsEq :=
                eq(keccak256(a, shl(5, add(mload(a), 1))), keccak256(b, shl(5, add(mload(b), 1))))
        }
        if (!inputsEq) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                STD-ERRORS
//////////////////////////////////////////////////////////////////////////*/

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
