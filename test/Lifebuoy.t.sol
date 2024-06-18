// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {Lifebuoy, MockLifebuoy, MockLifebuoyOwned} from "./utils/mocks/MockLifebuoy.sol";
import {MockETHRecipient} from "./utils/mocks/MockETHRecipient.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";
import {LibRLP} from "../src/utils/LibRLP.sol";
import {LibClone} from "../src/utils/LibClone.sol";
import {SafeTransferLib} from "../src/utils/SafeTransferLib.sol";

contract LifebuoyTest is SoladyTest {
    /// @dev Flag to denote that the deployer's access is locked.
    uint256 internal constant _LIFEBUOY_DEPLOYER_ACCESS_LOCK = 1 << 0;

    /// @dev Flag to denote that the `owner()`'s access is locked.
    uint256 internal constant _LIFEBUOY_OWNER_ACCESS_LOCK = 1 << 1;

    /// @dev Flag to denote that the `lockRescue` function is locked.
    uint256 internal constant _LIFEBUOY_LOCK_RESCUE_LOCK = 1 << 2;

    /// @dev Flag to denote that the `rescueETH` function is locked.
    uint256 internal constant _LIFEBUOY_RESCUE_ETH_LOCK = 1 << 3;

    /// @dev Flag to denote that the `rescueERC20` function is locked.
    uint256 internal constant _LIFEBUOY_RESCUE_ERC20_LOCK = 1 << 4;

    /// @dev Flag to denote that the `rescueERC721` function is locked.
    uint256 internal constant _LIFEBUOY_RESCUE_ERC721_LOCK = 1 << 5;

    MockERC20 erc20;
    MockERC721 erc721;

    function setUp() public {
        erc20 = new MockERC20("Name", "SYMBOL", 18);
        erc721 = new MockERC721();
    }

    function testLifebuoyCreateDeployment(address owner) public {
        address expected = LibRLP.computeAddress(address(this), vm.getNonce(address(this)));
        if (_random() % 32 == 0) {
            assertEq(address(new MockERC721()), expected);
        } else if (_random() % 2 == 0) {
            assertEq(address(new MockLifebuoyOwned(owner)), expected);
        } else {
            assertEq(address(new MockLifebuoy()), expected);
        }
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

    function _erc20BalanceOf(address holder) internal view returns (uint256) {
        return SafeTransferLib.balanceOf(address(erc20), holder);
    }

    function _testTempsBase() internal returns (_TestTemps memory t) {
        t.deployer = _randomHashedAddress();
        t.owner = _randomHashedAddress();
        do {
            t.recipient = _randomHashedAddress();
        } while (t.recipient == t.deployer || t.recipient == t.owner);

        if (_random() % 32 == 0) t.owner = t.deployer;
        if (_random() % 2 == 0) vm.etch(t.deployer, " ");

        vm.prank(t.deployer);
        t.lifebuoyOwned = new MockLifebuoyOwned(t.owner);
        vm.deal(address(t.lifebuoyOwned), 1 ether);
    }

    function _testTempsForRescue() internal returns (_TestTemps memory t) {
        t = _testTempsBase();

        t.erc20Amount = _random();
        erc20.mint(address(t.lifebuoyOwned), t.erc20Amount);

        t.tokenId = _random();
        erc721.mint(address(t.lifebuoyOwned), t.tokenId);
    }

    function _testTempsForRescuePermissions() internal returns (_TestTemps memory t) {
        t = _testTempsBase();

        vm.prank(t.deployer);
        t.lifebuoy = new MockLifebuoy();
        vm.deal(address(t.lifebuoy), 1 ether);

        vm.prank(t.deployer);
        t.lifebuoyOwnedClone = MockLifebuoyOwned(LibClone.clone(address(t.lifebuoyOwned)));
        t.lifebuoyOwnedClone.initializeOwner(t.owner);
        vm.deal(address(t.lifebuoyOwnedClone), 1 ether);
    }

    function testLifebuoyRescuePermissions(bytes32) public {
        _TestTemps memory t = _testTempsForRescuePermissions();
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
            t.lifebuoy.lockRescue(_LIFEBUOY_DEPLOYER_ACCESS_LOCK);
            vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
            t.lifebuoy.rescueETH(t.recipient, 1);
            vm.stopPrank();
        }
    }

    function testLifebuoyOwnedRescuePermissions(bytes32) public {
        _TestTemps memory t = _testTempsForRescuePermissions();
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
                t.lifebuoyOwned.lockRescue(_LIFEBUOY_DEPLOYER_ACCESS_LOCK);
                vm.prank(t.deployer);
                if (t.deployer != t.owner) {
                    vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
                }
                t.lifebuoyOwned.rescueETH(t.recipient, 1);
            } else {
                vm.prank(t.deployer);
                t.lifebuoyOwned.lockRescue(_LIFEBUOY_OWNER_ACCESS_LOCK);

                vm.prank(t.owner);
                if (t.deployer != t.owner) {
                    vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
                }
                t.lifebuoyOwned.rescueETH(t.recipient, 1);
            }
        }
    }

    function testLifebuoyOwnedCloneRescuePermissions(bytes32) public {
        _TestTemps memory t = _testTempsForRescuePermissions();
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

    function testRescueETH(uint256 amount) public {
        _TestTemps memory t = _testTempsForRescue();
        if (_random() % 2 == 0) {
            amount = _bound(amount, 0, address(t.lifebuoyOwned).balance);
            uint256 expectedRemaining = address(t.lifebuoyOwned).balance - amount;
            vm.prank(t.owner);
            t.lifebuoyOwned.rescueETH(t.recipient, amount);
            assertEq(address(t.lifebuoyOwned).balance, expectedRemaining);
            assertEq(t.recipient.balance, amount);
        } else if (amount > address(t.lifebuoyOwned).balance) {
            vm.prank(t.owner);
            vm.expectRevert(Lifebuoy.RescueTransferFailed.selector);
            t.lifebuoyOwned.rescueETH(t.recipient, amount);
        } else {
            vm.prank(t.owner);
            t.lifebuoyOwned.rescueETH(t.recipient, amount);
        }
    }

    function testRescueERC20(uint256 amount) public {
        _TestTemps memory t = _testTempsForRescue();
        if (_random() % 2 == 0) {
            amount = _bound(amount, 0, t.erc20Amount);
            vm.prank(t.owner);
            t.lifebuoyOwned.rescueERC20(address(erc20), t.recipient, amount);
            assertEq(_erc20BalanceOf(address(t.lifebuoyOwned)), t.erc20Amount - amount);
            assertEq(_erc20BalanceOf(t.recipient), amount);
        } else if (amount > _erc20BalanceOf(address(t.lifebuoyOwned))) {
            vm.prank(t.owner);
            vm.expectRevert(Lifebuoy.RescueTransferFailed.selector);
            t.lifebuoyOwned.rescueERC20(address(erc20), t.recipient, amount);
        } else {
            vm.prank(t.owner);
            t.lifebuoyOwned.rescueERC20(address(erc20), t.recipient, amount);
        }
    }

    function testRescueERC721(bytes32) public {
        _TestTemps memory t = _testTempsForRescue();
        vm.prank(t.owner);
        t.lifebuoyOwned.rescueERC721(address(erc721), t.recipient, t.tokenId);
        assertEq(erc721.balanceOf(address(t.lifebuoyOwned)), 0);
        assertEq(erc721.balanceOf(t.recipient), 1);
        vm.prank(t.owner);
        vm.expectRevert(Lifebuoy.RescueTransferFailed.selector);
        t.lifebuoyOwned.rescueERC721(address(erc721), t.recipient, t.tokenId);

        (address eoa,) = _randomSigner();
        vm.prank(t.owner);
        vm.expectRevert(Lifebuoy.RescueTransferFailed.selector);
        t.lifebuoyOwned.rescueERC721(eoa, t.recipient, t.tokenId);
    }

    function testLockRescueETH() public {
        _TestTemps memory t = _testTempsForRescue();
        vm.startPrank(t.owner);
        t.lifebuoyOwned.rescueETH(t.recipient, 1);
        t.lifebuoyOwned.lockRescue(_LIFEBUOY_RESCUE_ETH_LOCK);
        vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        t.lifebuoyOwned.rescueETH(t.recipient, 1);
        t.lifebuoyOwned.rescueERC721(address(erc721), t.recipient, t.tokenId);
    }

    function testLockRescue() public {
        _TestTemps memory t = _testTempsForRescue();
        vm.startPrank(t.owner);
        t.lifebuoyOwned.rescueETH(t.recipient, 1);
        t.lifebuoyOwned.lockRescue(_LIFEBUOY_LOCK_RESCUE_LOCK);
        vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        t.lifebuoyOwned.lockRescue(_LIFEBUOY_LOCK_RESCUE_LOCK);
    }

    function testLockEverything() public {
        _TestTemps memory t = _testTempsForRescue();
        vm.startPrank(t.owner);
        t.lifebuoyOwned.lockRescue(type(uint256).max);
        vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        t.lifebuoyOwned.lockRescue(_LIFEBUOY_LOCK_RESCUE_LOCK);
        vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        t.lifebuoyOwned.rescueETH(t.recipient, 1);
        vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        t.lifebuoyOwned.rescueERC721(address(erc721), t.recipient, t.tokenId);
        vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        t.lifebuoyOwned.rescueERC20(address(erc20), t.recipient, _random());
        vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        t.lifebuoyOwned.rescueETH(t.recipient, _random());
    }
}
