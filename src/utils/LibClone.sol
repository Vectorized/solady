// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Minimal proxy library using the 0age pattern.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibClone.sol)
/// @author 0age (https://github.com/0age)
/// @dev Although the sw0nt pattern saves 5 gas over the erc-1167 pattern during runtime,
/// it is not supported out-of-the-box on Etherscan. Hence, we choose to use the 0age pattern,
/// which saves 4 gas over the erc-1167 pattern during runtime, and has the smallest bytecode.
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
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x3d602c80600a3d3981f33d3d3d3d363d3d37363d73)
            instance := create(0, 0x0b, 0x36)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x21, 0)
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
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x3d602c80600a3d3981f33d3d3d3d363d3d37363d73)
            instance := create2(0, 0x0b, 0x36, salt)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x21, 0)
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
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            // prettier-ignore
            mstore(0x00, 0xff000000000000000000003d602c80600a3d3981f33d3d3d3d363d3d37363d73)
            // Compute and Store the bytecode hash.
            mstore(0x35, keccak256(0x0b, 0x36))
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)
        }
    }
}
