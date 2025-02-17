// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {EIP7702Proxy} from "../src/accounts/EIP7702Proxy.sol";
import {LibEIP7702} from "../src/accounts/LibEIP7702.sol";

interface IEIP7702ProxyWithAdminABI {
    function implementation() external view returns (address);
    function admin() external view returns (address);
    function changeAdmin(address) external returns (bool);
    function upgrade(address) external returns (bool);
    function bad() external;
}

contract Implementation2 {
    function version() external pure returns (uint256) {
        return 2;
    }
}

contract EIP7702ProxyTest is SoladyTest {
    error CustomError(uint256 currentValue);

    uint256 public value;

    bytes32 internal constant _ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    bytes32 internal constant _ERC1967_ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    function setValue(uint256 value_) public {
        value = value_;
        LibEIP7702.requestProxyDelegationInitialization();
    }

    function revertWithError() public view {
        revert CustomError(value);
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function upgradeToLatestProxyDelegation() public {
        LibEIP7702.upgradeToLatestProxyDelegation();
    }

    function _checkBehavesLikeProxy(address instance) internal {
        assertTrue(instance != address(0));

        assertEq(EIP7702ProxyTest(instance).version(), 1);

        uint256 v = _random();
        uint256 thisValue = this.value();
        if (thisValue == v) {
            v ^= 1;
        }
        EIP7702ProxyTest(instance).setValue(v);
        assertEq(v, EIP7702ProxyTest(instance).value());
        // assertEq(thisValue, this.value());
        // vm.expectRevert(abi.encodeWithSelector(CustomError.selector, v));
        // EIP7702ProxyTest(instance).revertWithError();
    }

    function testEIP7702Proxy(bytes32, bool f) public {
        vm.pauseGasMetering();

        address admin = _randomUniqueHashedAddress();
        IEIP7702ProxyWithAdminABI eip7702Proxy =
            IEIP7702ProxyWithAdminABI(address(new EIP7702Proxy(address(this), admin)));
        assertEq(eip7702Proxy.admin(), admin);
        assertEq(LibEIP7702.proxyAdmin(address(eip7702Proxy)), admin);
        assertEq(eip7702Proxy.implementation(), address(this));
        assertEq(LibEIP7702.proxyImplementation(address(eip7702Proxy)), address(this));

        if (!f && _randomChance(16)) {
            address newAdmin = _randomUniqueHashedAddress();
            vm.startPrank(admin);
            if (_randomChance(2)) {
                eip7702Proxy.changeAdmin(newAdmin);
            } else {
                LibEIP7702.changeProxyAdmin(address(eip7702Proxy), newAdmin);
            }
            assertEq(eip7702Proxy.admin(), newAdmin);
            vm.stopPrank();
            admin = newAdmin;
            vm.startPrank(_randomUniqueHashedAddress());
            vm.expectRevert();
            eip7702Proxy.changeAdmin(newAdmin);
            vm.stopPrank();
        }

        if (!f && _randomChance(16)) {
            address newImplementation = _randomUniqueHashedAddress();
            vm.startPrank(admin);
            if (_randomChance(2)) {
                eip7702Proxy.upgrade(newImplementation);
            } else {
                LibEIP7702.upgradeProxy(address(eip7702Proxy), newImplementation);
            }
            assertEq(eip7702Proxy.implementation(), newImplementation);
            eip7702Proxy.upgrade(address(this));
            assertEq(eip7702Proxy.implementation(), address(this));
            vm.stopPrank();
        }

        if (!f && _randomChance(16)) {
            vm.startPrank(admin);
            vm.expectRevert();
            eip7702Proxy.bad();
            vm.stopPrank();
        }

        address authority = _randomUniqueHashedAddress();
        assertEq(LibEIP7702.delegation(authority), address(0));
        vm.etch(authority, abi.encodePacked(hex"ef0100", address(eip7702Proxy)));

        emit LogAddress("authority", authority);
        emit LogAddress("proxy", address(eip7702Proxy));
        emit LogAddress("address(this)", address(this));

        vm.resumeGasMetering();

        // Runtime REVM detection.
        // If this check fails, then we are not ready to test it in CI.
        // The exact length is 23 at the time of writing as of the EIP7702 spec,
        // but we give our heuristic some leeway.
        if (authority.code.length > 0x20) return;

        assertEq(LibEIP7702.delegation(authority), address(eip7702Proxy));

        _checkBehavesLikeProxy(authority);

        // Check that upgrading the proxy won't cause the authority's implementation to change.
        if (!f && _randomChance(2)) {
            vm.startPrank(admin);
            eip7702Proxy.upgrade(address(1));
        }

        _checkBehavesLikeProxy(authority);

        if (!f && _randomChance(2)) {
            vm.startPrank(admin);
            eip7702Proxy.upgrade(address(new Implementation2()));

            EIP7702ProxyTest(authority).upgradeToLatestProxyDelegation();

            assertEq(Implementation2(authority).version(), 2);
        }
    }

    function testEIP7702Proxy() public {
        this.testEIP7702Proxy(0, true);
    }
}
