// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {Lifebuoy, MockLifebuoy, MockLifebuoyOwned} from "./utils/mocks/MockLifebuoy.sol";
import {MockETHRecipient} from "./utils/mocks/MockETHRecipient.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";
import {LibRLP} from "../src/utils/LibRLP.sol";
import {LibClone} from "../src/utils/LibClone.sol";

contract LifebuoyTest is SoladyTest {
    MockERC20 erc20;
    MockERC721 erc721;

    function setUp() public {
        erc20 = new MockERC20("Name", "SYMBOL", 18);
        erc721 = new MockERC721();
    }

    function testLifebuoyCreateDeployment(address owner) public {
        address expected = LibRLP.computeAddress(address(this), vm.getNonce(address(this)));
        address deployment;
        if (_random() % 32 == 0) {
            deployment = address(new MockERC721());
        } else if (_random() % 2 == 0) {
            deployment = address(new MockLifebuoyOwned(owner));
        } else {
            deployment = address(new MockLifebuoy());
        }
        assertEq(deployment, expected);
    }

    struct _TestTemps {
        address deployer;
        address owner;
        address recipient;
        MockLifebuoy lifebuoy;
        MockLifebuoyOwned lifebuoyOwned;
        MockLifebuoyOwned lifebuoyOwnedClone;
        uint256 tokenId;
        uint256 erc20Amount;
    }

    function _testTemps() internal returns (_TestTemps memory t) {
        t.deployer = _randomHashedAddress();
        t.owner = _randomHashedAddress();
        while (true) {
            t.recipient = _randomHashedAddress();
            if (t.recipient != t.deployer && t.recipient != t.owner) break;
        }

        if (_random() % 32 == 0) t.owner = t.deployer;
        if (_random() % 2 == 0) vm.etch(t.deployer, " ");

        vm.startPrank(t.deployer);

        t.lifebuoy = new MockLifebuoy();
        vm.deal(address(t.lifebuoy), 1 ether);

        t.lifebuoyOwned = new MockLifebuoyOwned(t.owner);
        vm.deal(address(t.lifebuoyOwned), 1 ether);

        t.lifebuoyOwnedClone = MockLifebuoyOwned(LibClone.clone(address(t.lifebuoyOwned)));
        t.lifebuoyOwnedClone.initializeOwner(t.owner);
        vm.deal(address(t.lifebuoyOwnedClone), 1 ether);

        vm.stopPrank();

        t.erc20Amount = _random();
        erc20.mint(address(t.lifebuoyOwned), t.erc20Amount);

        t.tokenId = _random();
        erc721.mint(address(t.lifebuoyOwned), t.tokenId);
    }

    function _testLifebuoyRescuePermissions(_TestTemps memory t) internal {
        vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        t.lifebuoy.rescueETH(t.recipient, 1);

        vm.prank(t.deployer);
        if (t.deployer.code.length == 0) {
            t.lifebuoy.rescueETH(t.recipient, 1);
        } else {
            vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
            t.lifebuoy.rescueETH(t.recipient, 1);
        }

        vm.prank(t.owner);
        if (t.deployer != t.owner || t.deployer.code.length != 0) {
            vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        }
        t.lifebuoy.rescueETH(t.recipient, 1);

        if (_random() % 2 == 0 && t.deployer.code.length == 0) {
            vm.startPrank(t.deployer);
            if (_random() % 2 == 0) {
                t.lifebuoy.rescueETH(t.recipient, 1);
            }
            t.lifebuoy.lockRescueForDeployer();
            vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
            t.lifebuoy.rescueETH(t.recipient, 1);
            vm.stopPrank();
        }
    }

    function _testLifebuoyOwnedRescuePermissions(_TestTemps memory t) internal {
        vm.prank(t.deployer);
        if (t.deployer != t.owner && t.deployer.code.length != 0) {
            vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        }
        t.lifebuoyOwned.rescueETH(t.recipient, 1);

        vm.prank(t.owner);
        t.lifebuoyOwned.rescueETH(t.recipient, 1);

        if (_random() % 2 == 0 && t.deployer.code.length == 0) {
            if (_random() % 2 == 0) {
                vm.prank(t.deployer);
                t.lifebuoyOwned.rescueETH(t.recipient, 1);
            }
            if (_random() % 2 == 0) {
                vm.prank(t.owner);
                t.lifebuoyOwned.rescueETH(t.recipient, 1);
            }

            if (_random() % 2 == 0) {
                vm.prank(t.deployer);
                t.lifebuoyOwned.lockRescueForDeployer();
                vm.prank(t.deployer);
                if (t.deployer != t.owner) {
                    vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
                }
                t.lifebuoyOwned.rescueETH(t.recipient, 1);
            } else {
                vm.prank(t.deployer);
                t.lifebuoyOwned.lockRescueForOwner();

                vm.prank(t.owner);
                if (t.deployer != t.owner) {
                    vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
                }
                t.lifebuoyOwned.rescueETH(t.recipient, 1);
            }
        }
    }

    function _testLifebuoyOwnedCloneRescuePermissions(_TestTemps memory t) internal {
        vm.prank(t.deployer);
        if (t.deployer != t.owner) {
            vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        }
        t.lifebuoyOwnedClone.rescueETH(t.recipient, 1);

        vm.prank(t.owner);
        t.lifebuoyOwnedClone.rescueETH(t.recipient, 1);

        vm.prank(t.owner);
        t.lifebuoyOwnedClone.transferOwnership(t.recipient);
        vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        vm.prank(t.owner);
        t.lifebuoyOwnedClone.rescueETH(t.recipient, 1);
    }

    function testLifebuoyRescuePermissions(bytes32) public {
        _TestTemps memory t = _testTemps();
        _testLifebuoyRescuePermissions(t);
        _testLifebuoyOwnedRescuePermissions(t);
        _testLifebuoyOwnedCloneRescuePermissions(t);
    }

    function testRescueETH(uint256 amount) public {
        _TestTemps memory t = _testTemps();
        if (_random() % 2 == 0) {
            amount = _bound(amount, 0, address(t.lifebuoyOwned).balance);
            uint256 expectedRemaining = address(t.lifebuoyOwned).balance - amount;
            vm.prank(t.owner);
            t.lifebuoyOwned.rescueETH(t.recipient, amount);
            assertEq(address(t.lifebuoyOwned).balance, expectedRemaining);
            assertEq(t.recipient.balance, amount);
        } else if (amount > address(t.lifebuoyOwned).balance) {
            vm.prank(t.owner);
            vm.expectRevert(Lifebuoy.RescueFailed.selector);
            t.lifebuoyOwned.rescueETH(t.recipient, amount);
        } else {
            vm.prank(t.owner);
            t.lifebuoyOwned.rescueETH(t.recipient, amount);
        }
    }

    function testRescueERC20(uint256 amount) public {
        _TestTemps memory t = _testTemps();
        if (_random() % 2 == 0) {
            amount = _bound(amount, 0, erc20.balanceOf(address(t.lifebuoyOwned)));
            uint256 expectedRemaining = erc20.balanceOf(address(t.lifebuoyOwned)) - amount;
            vm.prank(t.owner);
            t.lifebuoyOwned.rescueERC20(address(erc20), t.recipient, amount);
            assertEq(erc20.balanceOf(address(t.lifebuoyOwned)), expectedRemaining);
            assertEq(erc20.balanceOf(t.recipient), amount);
        } else if (amount > erc20.balanceOf(address(t.lifebuoyOwned))) {
            vm.prank(t.owner);
            vm.expectRevert(Lifebuoy.RescueFailed.selector);
            t.lifebuoyOwned.rescueERC20(address(erc20), t.recipient, amount);
        } else {
            vm.prank(t.owner);
            t.lifebuoyOwned.rescueERC20(address(erc20), t.recipient, amount);
        }
    }

    function testRescueERC721(bytes32) public {
        _TestTemps memory t = _testTemps();
        vm.prank(t.owner);
        t.lifebuoyOwned.rescueERC721(address(erc721), t.recipient, t.tokenId);
        assertEq(erc721.balanceOf(address(t.lifebuoyOwned)), 0);
        assertEq(erc721.balanceOf(t.recipient), 1);
        vm.prank(t.owner);
        vm.expectRevert(Lifebuoy.RescueFailed.selector);
        t.lifebuoyOwned.rescueERC721(address(erc721), t.recipient, t.tokenId);
    }
}
