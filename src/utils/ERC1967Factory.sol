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

    /// @dev Sets the admin of the caller.
    function setAdmin(address admin) external {
        // TODO: add non-zero code check?
        // if (msg.sender.codehash != bytes32(0)) revert NonContract();
        adminOf[msg.sender] = admin;
        emit AdminSet(msg.sender, admin);
    }

    /// @dev Sets the admin of the proxy if authorized.
    function setAdminFor(address proxy, address admin) external {
        if (adminOf[proxy] != msg.sender) revert Unauthorized();
        adminOf[proxy] = admin;
        emit AdminSet(proxy, admin);
    }

    /// @dev Deploys a proxy contract, sets the implementation, and sets the admin.
    function deployProxy(address implementation, address admin) external returns (address proxy) {
        // TODO: plug in huff proxy once tested
        // TODO: use assembly once huff proxy is plugged
        bytes memory initcode = new bytes(0);
        bytes memory initcodeWithArg = abi.encodePacked(initcode, implementation);
        assembly {
            proxy := create(0x00, add(initcodeWithArg, 0x20), mload(initcodeWithArg))
        }
        adminOf[proxy] = admin;
        emit AdminSet(proxy, admin);
    }

    /// @dev Upgrades the proxy if authorized.
    function upgradeProxyFor(address proxy, address implementation) external {
        if (proxy != msg.sender || adminOf[proxy] != msg.sender) revert Unauthorized();
        assembly {
            mstore(0x00, implementation)
            if iszero(call(gas(), proxy, 0x00, 0x00, 0x20, 0x00, 0x00)) {
                mstore(0x00, _UPGRADE_FAILED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
        }
        emit ProxyUpgraded(proxy, implementation);
    }
}
