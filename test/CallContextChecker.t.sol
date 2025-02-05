// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {CallContextChecker} from "../src/utils/CallContextChecker.sol";
import {LibClone} from "../src/utils/LibClone.sol";
import {MockCallContextChecker} from "../test/utils/mocks/MockCallContextChecker.sol";

contract CallContextCheckerTest is SoladyTest {
    MockCallContextChecker impl1;

    address proxy;

    bytes32 internal constant _ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed implementation);

    function setUp() public {
        impl1 = new MockCallContextChecker();
        proxy = LibClone.deployERC1967(address(impl1));
        MockCallContextChecker(proxy).initialize(address(this));
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
        MockCallContextChecker(authority).setX(x);
        uint256 retrievedX = MockCallContextChecker(authority).x();
        assertEq(retrievedX, x);
        MockCallContextChecker(authority).checkOnlyEIP7702Authority();
        vm.expectRevert(CallContextChecker.UnauthorizedCallContext.selector);
        MockCallContextChecker(impl1).checkOnlyEIP7702Authority();
        vm.expectRevert(CallContextChecker.UnauthorizedCallContext.selector);
        MockCallContextChecker(proxy).checkOnlyEIP7702Authority();
    }

    function testCheckNotDelegated() public {
        vm.expectRevert(CallContextChecker.UnauthorizedCallContext.selector);
        MockCallContextChecker(proxy).checkNotDelegated();
        assertTrue(impl1.checkNotDelegated());
    }

    function testCheckOnlyProxy() public {
        vm.expectRevert(CallContextChecker.UnauthorizedCallContext.selector);
        impl1.checkOnlyProxy();
        assertTrue(MockCallContextChecker(proxy).checkOnlyProxy());
    }

    function testNotDelegatedGuard() public {
        assertEq(impl1.proxiableUUID(), _ERC1967_IMPLEMENTATION_SLOT);
        vm.expectRevert(CallContextChecker.UnauthorizedCallContext.selector);
        MockCallContextChecker(proxy).proxiableUUID();
    }

    function testOnlyProxyGuard() public {
        vm.expectRevert(CallContextChecker.UnauthorizedCallContext.selector);
        impl1.upgradeToAndCall(address(1), bytes(""));
    }
}
