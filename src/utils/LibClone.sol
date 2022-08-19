// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Minimal proxy library using the sw0nt pattern.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibClone.sol)
/// @author Saw-mon-and-Natalie (https://github.com/Saw-mon-and-Natalie)
library LibClone {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error DeploymentFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function clone(address implementation) internal returns (address instance) {
        assembly {
            mstore(0x00, or(0x3d603180600a3d3981f3363d3d373d3d363d7300000000000000, shr(200, shl(96, implementation))))
            mstore(0x20, or(0x5af43d6000803e602b573d6000fd5b3d6000f3, shl(152, implementation)))
            instance := create(0, 0x06, 0x3b)

            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            mstore(0x00, or(0x3d603180600a3d3981f3363d3d373d3d363d7300000000000000, shr(200, shl(96, implementation))))
            mstore(0x20, or(0x5af43d6000803e602b573d6000fd5b3d6000f3, shl(152, implementation)))
            instance := create2(0, 0x06, 0x3b, salt)

            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            // Cache the free memory pointer for restoring later.
            let freeMemoryPointer := mload(0x40)

            mstore(0x00, or(0x3d603180600a3d3981f3363d3d373d3d363d7300000000000000, shr(200, shl(96, implementation))))
            mstore(0x20, or(0x5af43d6000803e602b573d6000fd5b3d6000f3, shl(152, implementation)))

            // Compute and Store the bytecode hash.
            mstore(0x40, keccak256(0x06, 0x3b))
            mstore(0x00, deployer)
            // Store the prefix.
            mstore8(0x0b, 0xff)
            mstore(0x20, salt)

            predicted := keccak256(0x0b, 0x55)

            // Restore the free memory pointer.
            mstore(0x40, freeMemoryPointer)
        }
    }
}
