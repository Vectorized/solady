// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Factory for deploying and managing ERC1967 proxy contracts.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ERC1967Factory.sol)
/// @author jtriley-eth (https://github.com/jtriley-eth/minimum-viable-proxy)
contract ERC1967Factory {
    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The proxy deployment failed.
    error DeploymentFailed();

    /// @dev The upgrade failed.
    error UpgradeFailed();

    /// @dev `bytes4(keccak256(bytes("UpgradeFailed()")))`.
    uint256 private constant _UPGRADE_FAILED_ERROR_SELECTOR = 0x55299b49;

    /// @dev The admin of a proxy contract has been set.
    event AdminSet(address indexed proxy, address indexed admin);

    /// @dev The implementation for a proxy has been upgraded.
    event ProxyUpgraded(address indexed proxy, address indexed implementation);

    /// @dev Proxy admin registry.
    mapping(address proxy => address admin) public adminOf;

    /// @dev Sets the admin of the proxy if authorized.
    function setAdminFor(address proxy, address admin) external {
        if (adminOf[proxy] != msg.sender) revert Unauthorized();
        adminOf[proxy] = admin;
        emit AdminSet(proxy, admin);
    }

    /// @dev Upgrades the proxy if authorized.
    function upgradeProxyFor(address proxy, address implementation) external {
        if (adminOf[proxy] != msg.sender) revert Unauthorized();

        assembly {
            mstore(0x00, implementation)
            if iszero(call(gas(), proxy, 0x00, 0x00, 0x20, 0x00, 0x00)) {
                mstore(0x00, _UPGRADE_FAILED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
        }

        emit ProxyUpgraded(proxy, implementation);
    }

    /// @dev Deploys a proxy contract, sets the implementation, and sets the admin.
    function deployProxy(address implementation, address admin) external returns (address proxy) {
        assembly {
            // TODO: that big mf table describing the bytecode once the proxy is tested.

            // get the free memory pointer,
            // set it to the end of the memory allocation.
            let memPtr := mload(0x40)
            mstore(0x40, add(memPtr, mallocSize))

            // store the bytecode in chunks starting at the free memory pointer.
            mstore(memPtr, chunk0)
            mstore(add(memPtr, 0x20), chunk1)
            mstore(add(memPtr, 0x40), chunk2)
            mstore(add(memPtr, 0x60), chunk3)
            mstore(add(memPtr, 0x80), chunk4)
            mstore(add(memPtr, 0xa0), chunk5)

            // write implementation address to the end of the bytecode.
            // this is treated as a constructor argument in the proxy initcode.
            mstore(add(memPtr, codeSize), implementation)

            // write the factory address to the bytecode.
            // we mask to avoid overwriting bytes.
            let factoryCodePtr := add(memPtr, factoryOffset)
            mstore(factoryCodePtr, or(address(), mload(factoryCodePtr)))

            // create the proxy.
            proxy := create(0x00, memPtr, mallocSize)
        }

        if (proxy == address(0)) revert DeploymentFailed();
        adminOf[proxy] = admin;
        emit AdminSet(proxy, admin);
    }
}

// pointers
uint256 constant mallocSize = 0xcd;
uint256 constant codeSize = 0xad;
uint256 constant factoryOffset = 0x25;

// bytecode chunks
uint256 constant chunk0 = 0x6030803803903d39607d80517f360894a13ba1a3210667c828492db98dca3e20;
uint256 constant chunk1 = 0x76cc3735a920a3ca505d382bbc553df373000000000000000000000000000000;
uint256 constant chunk2 = 0x0000000000331461005757363d3d373d3d3d363d7f360894a13ba1a3210667c8;
uint256 constant chunk3 = 0x28492db98dca3e2076cc3735a920a3ca505d382bbc545af43d82803e61005357;
uint256 constant chunk4 = 0x3d90fd5b3d90f35b3d357f360894a13ba1a3210667c828492db98dca3e2076cc;
uint256 constant chunk5 = 0x3735a920a3ca505d382bbc550000000000000000000000000000000000000000;
