// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for interacting with ERC6551 accounts.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/LibERC6551.sol)
/// @author ERC6551 team (https://github.com/erc6551/reference/blob/main/src/lib/ERC6551AccountLib.sol)
library LibERC6551 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Failed to create a ERC6551 account via the registry.
    error AccountCreationFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The canonical ERC6551 registry address for EVM chains.
    address internal constant REGISTRY = 0x000000006551c19487814612e58FE06813775758;

    /// @dev The canonical ERC6551 registry bytecode for EVM chains.
    /// Useful for forge tests:
    /// `vm.etch(REGISTRY, REGISTRY_BYTECODE)`.
    bytes internal constant REGISTRY_BYTECODE =
        hex"608060405234801561001057600080fd5b50600436106100365760003560e01c8063246a00211461003b5780638a54c52f1461006a575b600080fd5b61004e6100493660046101b7565b61007d565b6040516001600160a01b03909116815260200160405180910390f35b61004e6100783660046101b7565b6100e1565b600060806024608c376e5af43d82803e903d91602b57fd5bf3606c5285605d52733d60ad80600a3d3981f3363d3d373d3d3d363d7360495260ff60005360b76055206035523060601b60015284601552605560002060601b60601c60005260206000f35b600060806024608c376e5af43d82803e903d91602b57fd5bf3606c5285605d52733d60ad80600a3d3981f3363d3d373d3d3d363d7360495260ff60005360b76055206035523060601b600152846015526055600020803b61018b578560b760556000f580610157576320188a596000526004601cfd5b80606c52508284887f79f19b3655ee38b1ce526556b7731a20c8f218fbda4a3990b6cc4172fdf887226060606ca46020606cf35b8060601b60601c60005260206000f35b80356001600160a01b03811681146101b257600080fd5b919050565b600080600080600060a086880312156101cf57600080fd5b6101d88661019b565b945060208601359350604086013592506101f46060870161019b565b94979396509194608001359291505056fea2646970667358221220ea2fe53af507453c64dd7c1db05549fa47a298dfb825d6d11e1689856135f16764736f6c63430008110033";

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                ACCOUNT BYTECODE OPERATIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the initialization code of the ERC6551 account.
    function initCode(
        address implementation_,
        bytes32 salt_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_
    ) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40) // Grab the free memory pointer..
            // Layout the variables and bytecode backwards.
            mstore(add(result, 0xb7), tokenId_)
            mstore(add(result, 0x97), shr(96, shl(96, tokenContract_)))
            mstore(add(result, 0x77), chainId_)
            mstore(add(result, 0x57), salt_)
            mstore(add(result, 0x37), 0x5af43d82803e903d91602b57fd5bf3)
            mstore(add(result, 0x28), implementation_)
            mstore(add(result, 0x14), 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73)
            mstore(result, 0xb7) // Store the length.
            mstore(0x40, add(result, 0xd7)) // Allocate the memory.
        }
    }

    /// @dev Returns the initialization code hash of the ERC6551 account.
    function initCodeHash(
        address implementation_,
        bytes32 salt_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40) // Grab the free memory pointer.
            // Layout the variables and bytecode backwards.
            mstore(add(result, 0xa3), tokenId_)
            mstore(add(result, 0x83), shr(96, shl(96, tokenContract_)))
            mstore(add(result, 0x63), chainId_)
            mstore(add(result, 0x43), salt_)
            mstore(add(result, 0x23), 0x5af43d82803e903d91602b57fd5bf3)
            mstore(add(result, 0x14), implementation_)
            mstore(result, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73)
            result := keccak256(add(result, 0x0c), 0xb7)
        }
    }

    /// @dev Creates an account via the ERC6551 registry.
    function createAccount(
        address implementation_,
        bytes32 salt_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_
    ) internal returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(add(m, 0x14), implementation_)
            mstore(add(m, 0x34), salt_)
            mstore(add(m, 0x54), chainId_)
            mstore(add(m, 0x74), shr(96, shl(96, tokenContract_)))
            mstore(add(m, 0x94), tokenId_)
            // `createAccount(address,bytes32,uint256,address,uint256)`.
            mstore(m, 0x8a54c52f000000000000000000000000)
            if iszero(
                and(
                    gt(returndatasize(), 0x1f),
                    call(gas(), REGISTRY, 0, add(m, 0x10), 0xa4, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x20188a59) // `AccountCreationFailed()`.
                revert(0x1c, 0x04)
            }
            result := mload(0x00)
        }
    }

    /// @dev Returns the address of the ERC6551 account.
    function account(
        address implementation_,
        bytes32 salt_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_
    ) internal pure returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40) // Grab the free memory pointer.
            // Layout the variables and bytecode backwards.
            mstore(add(result, 0xa3), tokenId_)
            mstore(add(result, 0x83), shr(96, shl(96, tokenContract_)))
            mstore(add(result, 0x63), chainId_)
            mstore(add(result, 0x43), salt_)
            mstore(add(result, 0x23), 0x5af43d82803e903d91602b57fd5bf3)
            mstore(add(result, 0x14), implementation_)
            mstore(result, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73)
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, keccak256(add(result, 0x0c), 0xb7))
            mstore(0x01, shl(96, REGISTRY))
            mstore(0x15, salt_)
            result := keccak256(0x00, 0x55)
            mstore(0x35, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns if `a` is an ERC6551 account with `expectedImplementation`.
    function isERC6551Account(address a, address expectedImplementation)
        internal
        view
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Grab the free memory pointer..
            extcodecopy(a, add(m, 0x20), 0x0a, 0xa3)
            let implementation_ := shr(96, mload(add(m, 0x20)))
            if mul(
                extcodesize(implementation_),
                gt(eq(extcodesize(a), 0xad), shl(96, xor(expectedImplementation, implementation_)))
            ) {
                // Layout the variables and bytecode backwards.
                mstore(add(m, 0x23), 0x5af43d82803e903d91602b57fd5bf3)
                mstore(add(m, 0x14), implementation_)
                mstore(m, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73)
                // Compute and store the bytecode hash.
                mstore8(0x00, 0xff) // Write the prefix.
                mstore(0x35, keccak256(add(m, 0x0c), 0xb7))
                mstore(0x01, shl(96, REGISTRY))
                mstore(0x15, mload(add(m, 0x43)))
                result := iszero(shl(96, xor(a, keccak256(0x00, 0x55))))
                mstore(0x35, 0) // Restore the overwritten part of the free memory pointer.
            }
        }
    }

    /// @dev Returns the implementation of the ERC6551 account `a`.
    function implementation(address a) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            extcodecopy(a, 0x00, 0x0a, 0x14)
            result := shr(96, mload(0x00))
        }
    }

    /// @dev Returns the static variables of the ERC6551 account `a`.
    function context(address a)
        internal
        view
        returns (bytes32 salt_, uint256 chainId_, address tokenContract_, uint256 tokenId_)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            extcodecopy(a, 0x00, 0x2d, 0x80)
            salt_ := mload(0x00)
            chainId_ := mload(0x20)
            tokenContract_ := mload(0x40)
            tokenId_ := mload(0x60)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero pointer.
        }
    }

    /// @dev Returns the salt of the ERC6551 account `a`.
    function salt(address a) internal view returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            extcodecopy(a, 0x00, 0x2d, 0x20)
            result := mload(0x00)
        }
    }

    /// @dev Returns the chain ID of the ERC6551 account `a`.
    function chainId(address a) internal view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            extcodecopy(a, 0x00, 0x4d, 0x20)
            result := mload(0x00)
        }
    }

    /// @dev Returns the token contract of the ERC6551 account `a`.
    function tokenContract(address a) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            extcodecopy(a, 0x00, 0x6d, 0x20)
            result := mload(0x00)
        }
    }

    /// @dev Returns the token ID of the ERC6551 account `a`.
    function tokenId(address a) internal view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            extcodecopy(a, 0x00, 0x8d, 0x20)
            result := mload(0x00)
        }
    }
}
