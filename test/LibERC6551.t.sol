// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibERC6551} from "../src/accounts/LibERC6551.sol";

interface IERC6551Registry {
    event ERC6551AccountCreated(
        address account,
        address indexed implementation,
        bytes32 salt,
        uint256 chainId,
        address indexed tokenContract,
        uint256 indexed tokenId
    );

    error AccountCreationFailed();

    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address account);

    function account(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external view returns (address account);
}

contract LibERC6551Test is SoladyTest {
    function setUp() public {
        vm.etch(LibERC6551.REGISTRY, LibERC6551.REGISTRY_BYTECODE);
    }

    function testInitCodeHash(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) public {
        bytes memory initCode =
            LibERC6551.initCode(implementation, salt, chainId, tokenContract, tokenId);
        if (_random() % 8 == 0) _brutalizeMemory();
        bytes32 initCodeHash =
            LibERC6551.initCodeHash(implementation, salt, chainId, tokenContract, tokenId);
        if (_random() % 8 == 0) _brutalizeMemory();
        assertEq(initCodeHash, keccak256(initCode));
    }

    function testComputeAccountAddress(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) public {
        IERC6551Registry registry = IERC6551Registry(LibERC6551.REGISTRY);
        address a = registry.account(
            _brutalized(implementation), salt, chainId, _brutalized(tokenContract), tokenId
        );
        if (_random() % 8 == 0) _brutalizeMemory();
        if (_random() % 8 == 0) {
            address deployed = _createAccount(
                _brutalized(implementation), salt, chainId, _brutalized(tokenContract), tokenId
            );
            assertEq(deployed, a);
        }
        if (_random() % 8 == 0) _brutalizeMemory();
        address computed = LibERC6551.account(
            _brutalized(implementation), salt, chainId, _brutalized(tokenContract), tokenId
        );
        assertEq(computed, a);
        _checkMemory();
    }

    function testIsERC6551Account(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) public {
        if (_random() % 8 == 0) implementation = address(this);

        address a = _account(implementation, salt, chainId, tokenContract, tokenId);
        assertEq(LibERC6551.isERC6551Account(_brutalized(a), _brutalized(implementation)), false);

        _createAccount(implementation, salt, chainId, tokenContract, tokenId);
        assertEq(_createAccount(implementation, salt, chainId, tokenContract, tokenId), a);

        assertEq(LibERC6551.implementation(_brutalized(a)), _brutalized(implementation));
        assertEq(
            LibERC6551.isERC6551Account(_brutalized(a), _brutalized(implementation)),
            implementation.code.length != 0
        );
        _checkMemory();

        /// @solidity memory-safe-assembly
        assembly {
            implementation := xor(1, implementation)
        }
        assertEq(LibERC6551.isERC6551Account(_brutalized(a), _brutalized(implementation)), false);
        _checkMemory();
    }

    function _account(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) internal returns (address) {
        if (_random() % 2 == 0) {
            return LibERC6551.account(
                _brutalized(implementation), salt, chainId, _brutalized(tokenContract), tokenId
            );
        } else {
            IERC6551Registry registry = IERC6551Registry(LibERC6551.REGISTRY);
            return registry.account(
                _brutalized(implementation), salt, chainId, _brutalized(tokenContract), tokenId
            );
        }
    }

    function _createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) internal returns (address) {
        if (_random() % 2 == 0) {
            return LibERC6551.createAccount(
                _brutalized(implementation), salt, chainId, _brutalized(tokenContract), tokenId
            );
        } else {
            IERC6551Registry registry = IERC6551Registry(LibERC6551.REGISTRY);
            return registry.createAccount(
                _brutalized(implementation), salt, chainId, _brutalized(tokenContract), tokenId
            );
        }
    }

    struct _TestTemps {
        bytes32 salt;
        uint256 chainId;
        address tokenContract;
        uint256 tokenId;
    }

    function testContext(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) public {
        address a = _createAccount(implementation, salt, chainId, tokenContract, tokenId);
        assertEq(LibERC6551.salt(_brutalized(a)), salt);
        assertEq(LibERC6551.chainId(_brutalized(a)), chainId);
        assertEq(LibERC6551.tokenContract(_brutalized(a)), tokenContract);
        assertEq(LibERC6551.tokenId(_brutalized(a)), tokenId);
        _checkMemory();

        assertEq(LibERC6551.implementation(a), implementation);
        _checkMemory();

        _TestTemps memory t;
        (t.salt, t.chainId, t.tokenContract, t.tokenId) = LibERC6551.context(a);
        assertEq(t.chainId, chainId);
        assertEq(t.salt, salt);
        assertEq(t.tokenContract, tokenContract);
        assertEq(t.tokenId, tokenId);
        _checkMemory();
    }

    function _brutalized(address a) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, gas())
            result := or(shl(160, keccak256(0x00, 0x20)), a)
            mstore(0x00, result)
            mstore(0x20, result)
        }
    }
}
