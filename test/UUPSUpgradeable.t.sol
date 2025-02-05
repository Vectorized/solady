// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {CallContextChecker, UUPSUpgradeable} from "../src/utils/UUPSUpgradeable.sol";
import {LibClone} from "../src/utils/LibClone.sol";
import {MockUUPSImplementation} from "../test/utils/mocks/MockUUPSImplementation.sol";

contract UUPSUpgradeableTest is SoladyTest {
    MockUUPSImplementation impl1;

    address proxy;

    bytes32 internal constant _ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed implementation);

    function setUp() public {
        impl1 = new MockUUPSImplementation();
        proxy = LibClone.deployERC1967(address(impl1));
        MockUUPSImplementation(proxy).initialize(address(this));
    }

    function testCheckOnlyEIP7702Authority() public {
        address authority = _randomHashedAddress();
        vm.etch(authority, abi.encodePacked(hex"ef0100", impl1));
        // Runtime REVM detection.
        // If this check fails, then we are not ready to test it in CI.
        // The exact length is 23 at the time of writing as of the EIP7702 spec,
        // but we give our heuristic some leeway.
        if (authority.code.length > 0x20) return;

        uint256 x = _random();
        MockUUPSImplementation(authority).setX(x);
        uint256 retrievedX = MockUUPSImplementation(authority).x();
        assertEq(retrievedX, x);
        MockUUPSImplementation(authority).checkOnlyEIP7702Authority();
        vm.expectRevert(CallContextChecker.UnauthorizedCallContext.selector);
        MockUUPSImplementation(impl1).checkOnlyEIP7702Authority();
        vm.expectRevert(CallContextChecker.UnauthorizedCallContext.selector);
        MockUUPSImplementation(proxy).checkOnlyEIP7702Authority();
    }

    function testCheckNotDelegated() public {
        vm.expectRevert(CallContextChecker.UnauthorizedCallContext.selector);
        MockUUPSImplementation(proxy).checkNotDelegated();
        assertTrue(impl1.checkNotDelegated());
    }

    function testCheckOnlyProxy() public {
        vm.expectRevert(CallContextChecker.UnauthorizedCallContext.selector);
        impl1.checkOnlyProxy();
        assertTrue(MockUUPSImplementation(proxy).checkOnlyProxy());
    }

    function testNotDelegatedGuard() public {
        assertEq(impl1.proxiableUUID(), _ERC1967_IMPLEMENTATION_SLOT);
        vm.expectRevert(CallContextChecker.UnauthorizedCallContext.selector);
        MockUUPSImplementation(proxy).proxiableUUID();
    }

    function testOnlyProxyGuard() public {
        vm.expectRevert(CallContextChecker.UnauthorizedCallContext.selector);
        impl1.upgradeToAndCall(address(1), bytes(""));
    }

    function testUpgradeTo() public {
        MockUUPSImplementation impl2 = new MockUUPSImplementation();
        vm.expectEmit(true, true, true, true);
        emit Upgraded(address(impl2));
        MockUUPSImplementation(proxy).upgradeToAndCall(address(impl2), bytes(""));
        bytes32 v = vm.load(proxy, _ERC1967_IMPLEMENTATION_SLOT);
        assertEq(address(uint160(uint256(v))), address(impl2));
    }

    function testUpgradeToRevertWithUnauthorized() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert(MockUUPSImplementation.Unauthorized.selector);
        MockUUPSImplementation(proxy).upgradeToAndCall(address(0xABCD), bytes(""));
    }

    function testUpgradeToRevertWithUpgradeFailed() public {
        vm.expectRevert(UUPSUpgradeable.UpgradeFailed.selector);
        MockUUPSImplementation(proxy).upgradeToAndCall(address(0xABCD), bytes(""));
    }

    function testUpgradeToAndCall() public {
        MockUUPSImplementation impl2 = new MockUUPSImplementation();
        bytes memory data = abi.encodeWithSignature("setValue(uint256)", 5);
        MockUUPSImplementation(proxy).upgradeToAndCall(address(impl2), data);
        bytes32 v = vm.load(proxy, _ERC1967_IMPLEMENTATION_SLOT);
        assertEq(address(uint160(uint256(v))), address(impl2));
        assertEq(MockUUPSImplementation(proxy).value(), 5);
    }

    function testUpgradeToAndCallRevertWithUpgradeFailed() public {
        vm.expectRevert(UUPSUpgradeable.UpgradeFailed.selector);
        MockUUPSImplementation(proxy).upgradeToAndCall(address(0xABCD), "");
    }

    function testUpgradeToAndCallRevertWithCustomError() public {
        MockUUPSImplementation impl2 = new MockUUPSImplementation();
        bytes memory data = abi.encodeWithSignature("revertWithError()");
        vm.expectRevert(
            abi.encodeWithSelector(MockUUPSImplementation.CustomError.selector, address(this))
        );
        MockUUPSImplementation(proxy).upgradeToAndCall(address(impl2), data);
    }

    function testUpgradeToAndCallRevertWithUnauthorized() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert(MockUUPSImplementation.Unauthorized.selector);
        MockUUPSImplementation(proxy).upgradeToAndCall(address(0xABCD), "");
    }
}
