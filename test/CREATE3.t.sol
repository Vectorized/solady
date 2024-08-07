// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {WETH} from "../src/tokens/WETH.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {MockCd} from "./utils/mocks/MockCd.sol";

import {CREATE3} from "../src/utils/CREATE3.sol";

import "./utils/SoladyTest.sol";

contract CREATE3Test is SoladyTest {
    function testDeployERC20() public {
        bytes32 salt = keccak256(bytes("A salt!"));

        MockERC20 deployed = MockERC20(
            this.deployDeterministic(
                abi.encodePacked(type(MockERC20).creationCode, abi.encode("Mock Token", "MOCK", 18)),
                salt
            )
        );

        assertEq(address(deployed), CREATE3.predictDeterministicAddress(salt));

        assertEq(deployed.name(), "Mock Token");
        assertEq(deployed.symbol(), "MOCK");
        assertEq(deployed.decimals(), 18);
    }

    function testDeployedUpperBitsSafeForPlainSolidity() public {
        bytes32 salt = keccak256(bytes("A salt!"));
        address deployed = CREATE3.predictDeterministicAddress(salt);
        uint256 someNumber = 123456789;
        uint256 packed = (someNumber << 160) | uint160(deployed);
        uint256 someNumberUnpacked = packed >> 160;
        assertEq(someNumber, someNumberUnpacked);
    }

    function testDoubleDeploySameBytecodeReverts() public {
        bytes32 salt = keccak256(bytes("Salty..."));

        this.deployDeterministic(type(MockCd).creationCode, salt);
        vm.expectRevert(CREATE3.DeploymentFailed.selector);
        this.deployDeterministic(type(MockCd).creationCode, salt);
    }

    function testDoubleDeployDifferentBytecodeReverts() public {
        bytes32 salt = keccak256(bytes("and sweet!"));

        this.deployDeterministic(type(WETH).creationCode, salt);
        vm.expectRevert(CREATE3.DeploymentFailed.selector);
        this.deployDeterministic(type(MockCd).creationCode, salt);
    }

    function testDeployERC20(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) public {
        MockERC20 deployed = MockERC20(
            this.deployDeterministic(
                abi.encodePacked(type(MockERC20).creationCode, abi.encode(name, symbol, decimals)),
                salt
            )
        );

        assertEq(address(deployed), CREATE3.predictDeterministicAddress(salt));

        assertEq(deployed.name(), name);
        assertEq(deployed.symbol(), symbol);
        assertEq(deployed.decimals(), decimals);
    }

    function testDoubleDeploySameBytecodeReverts(bytes32 salt, bytes calldata bytecode) public {
        bytes memory creationCode = _initCode(bytecode);
        this.deployDeterministic(creationCode, salt);
        vm.expectRevert(CREATE3.DeploymentFailed.selector);
        this.deployDeterministic(creationCode, salt);
    }

    function testDoubleDeployDifferentBytecodeReverts(
        bytes32 salt,
        bytes memory bytecode1,
        bytes memory bytecode2
    ) public {
        this.deployDeterministic(_initCode(bytecode1), salt);
        vm.expectRevert(CREATE3.DeploymentFailed.selector);
        this.deployDeterministic(_initCode(bytecode2), salt);
    }

    function deployDeterministic(uint256 value, bytes calldata creationCode, bytes32 salt)
        public
        returns (address)
    {
        return CREATE3.deployDeterministic(value, creationCode, salt);
    }

    function deployDeterministic(bytes calldata creationCode, bytes32 salt)
        public
        returns (address)
    {
        return deployDeterministic(0, creationCode, salt);
    }

    function _initCode(bytes memory bytecode) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Trim the length if needed.
            let length := mload(bytecode)
            let maxLength := 24566 // `24576 - 0xa`.
            if iszero(lt(length, maxLength)) { mstore(bytecode, maxLength) }
            // The following snippet is from SSTORE2.
            result := mload(0x40)
            length := mload(bytecode)
            let dataSize := add(length, 1)
            mstore(0x40, and(add(add(result, dataSize), 0x60), not(0x1f)))
            mstore(add(result, 0x0b), or(0x61000080600a3d393df300, shl(0x40, dataSize)))
            mstore(result, add(dataSize, 0xa)) // Store the length of result.
            // Copy the bytes over.
            for { let i := 0 } lt(i, length) { i := add(i, 0x20) } {
                mstore(add(add(bytecode, 0x20), i), mload(add(add(result, 0x2b), i)))
            }
        }
    }
}
