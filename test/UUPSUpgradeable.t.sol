// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {UUPSUpgradeable} from "../src/utils/UUPSUpgradeable.sol";
import {LibClone} from "../src/utils/LibClone.sol";
import {MockUUPSImplementation} from "../test/utils/mocks/MockUUPSImplementation.sol";

contract UUPSUpgradeableTest is SoladyTest {
    error UpgradeFailed();

    MockUUPSImplementation impl1;

    address proxy;

    function setUp() public {
        impl1 = new MockUUPSImplementation();
        proxy = LibClone.deployERC1967(address(impl1));
        MockUUPSImplementation(proxy).initialize(address(this));
    }

    function testUpgradeTo() public {
        MockUUPSImplementation impl2 = new MockUUPSImplementation();
        MockUUPSImplementation(proxy).upgradeTo(address(impl2));
        assertEq(
            address(
                uint160(
                    uint256(
                        vm.load(
                            proxy,
                            0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
                        )
                    )
                )
            ),
            address(impl2)
        );
    }

    function testUpgradeToRevertWithUnauthorized() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert(MockUUPSImplementation.Unauthorized.selector);
        MockUUPSImplementation(proxy).upgradeTo(address(0xABCD));
    }

    function testUpgradeToRevertWithUpgradeFailed() public {
        vm.expectRevert(UpgradeFailed.selector);
        MockUUPSImplementation(proxy).upgradeTo(address(0xABCD));
    }

    function testUpgradeToAndCall() public {
        MockUUPSImplementation impl2 = new MockUUPSImplementation();
        bytes memory data = abi.encodeWithSignature("setValue(uint256)", 5);
        MockUUPSImplementation(proxy).upgradeToAndCall(address(impl2), data);
        assertEq(
            address(
                uint160(
                    uint256(
                        vm.load(
                            proxy,
                            0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
                        )
                    )
                )
            ),
            address(impl2)
        );
        assertEq(MockUUPSImplementation(proxy).value(), 5);
    }

    function testUpgradeToAndCallRevertWithUpgradeFailed() public {
        vm.expectRevert(UpgradeFailed.selector);
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
