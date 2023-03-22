// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Factory for deploying and managing ERC1967 proxy contracts.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ERC1967Factory.sol)
/// @author jtriley-eth (https://github.com/jtriley-eth/minimum-viable-proxy)
contract ERC1967Factory {
    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

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
        if (proxy != msg.sender || adminOf[proxy] != msg.sender)
            revert Unauthorized();
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
    function deployProxy(
        address implementation,
        address admin
    ) external returns (address proxy) {
        // TODO: plug in huff proxy once tested
        // TODO: use assembly once huff proxy is plugged
        assembly {
            // TODO: that big mf table describing the bytecode once the proxy is tested

            // get the free memory pointer, set it to the end of the memory allocation
            let memPtr := mload(0x40)
            mstore(0x40, add(memPtr, memoryAllocation))

            // store the code pointer and length
            mstore(memPtr, 0x20)
            mstore(add(memPtr, 0x20), codeSize)

            // store the bytecode
            mstore(add(memPtr, 0x40), chunk0)
            mstore(add(memPtr, 0x60), chunk1)
            mstore(add(memPtr, 0x80), chunk2)
            mstore(add(memPtr, 0xa0), chunk3)
            mstore(add(memPtr, 0xc0), chunk4)
            mstore(add(memPtr, 0xe0), chunk5)

            // write the factory and imlementation addresses to memory
            mstore(implementationOffset, implementation)
            mstore(factoryOffset, address())

            // proxy := create(
            //     0x00,
            //     add(initcodeWithArg, 0x20),
            //     mload(initcodeWithArg)
            // )
        }
        adminOf[proxy] = admin;
        emit AdminSet(proxy, admin);
    }
}

// pointers
uint256 constant memoryAllocation = 0x0127;
uint256 constant codeSize = 0xe7;
uint256 constant implementationOffset = 0xc7;
uint256 constant factoryOffset = 0x35;

// bytecode chunks
uint256 constant chunk0 = 0x3860103d396020590380517f360894a13ba1a3210667c828492db98dca3e2076;
uint256 constant chunk1 = 0xcc3735a920a3ca505d382bbc553df373ffffffffffffffffffffffffffffffff;
uint256 constant chunk2 = 0xffffffff331461005957363d3d373d3d363d7f360894a13ba1a3210667c82849;
uint256 constant chunk3 = 0x2db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e610054573d;
uint256 constant chunk4 = 0x6000fd5b3d6000f35b3d357f360894a13ba1a3210667c828492db98dca3e2076;
uint256 constant chunk5 = 0xcc3735a920a3ca505d382bbc5500000000000000000000000000000000000000;
