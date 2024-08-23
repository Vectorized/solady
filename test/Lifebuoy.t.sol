// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {Lifebuoy, MockLifebuoy, MockLifebuoyOwned} from "./utils/mocks/MockLifebuoy.sol";
import {MockETHRecipient} from "./utils/mocks/MockETHRecipient.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";
import {MockERC1155} from "./utils/mocks/MockERC1155.sol";
import {MockERC6909} from "./utils/mocks/MockERC6909.sol";
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
    MockERC1155 erc1155;
    MockERC6909 erc6909;

    function setUp() public {
        erc20 = new MockERC20("Name", "SYMBOL", 18);
        erc721 = new MockERC721();
        erc1155 = new MockERC1155();
        erc6909 = new MockERC6909();
    }

    function _deployViaCreate(address deployer, bytes memory initcode) internal returns (address) {
        (bool success, bytes memory result) = deployer.call(initcode);
        assertTrue(success);
        return abi.decode(result, (address));
    }

    function _testLifebuoyCreateDeployment(address deployer, bytes memory initcode) internal {
        address expected = LibRLP.computeAddress(deployer, vm.getNonce(deployer));
        assertEq(_deployViaCreate(deployer, initcode), expected);
    }

    function testLifebuoyCreateDeployment(address deployer, address owner, uint256 r) public {
        while (deployer.code.length != 0 || uint160(deployer) < 0xffffffffff) {
            deployer = _randomNonZeroAddress();
        }
        vm.etch(deployer, hex"3d3d363d3d37363d34f09052602081f3");
        for (uint256 i; i != 3; ++i) {
            r = r >> 32;
            if (r & 31 == 0) {
                _testLifebuoyCreateDeployment(deployer, type(MockERC721).creationCode);
                continue;
            }
            r = r >> 8;
            if (r & 1 == 0) {
                bytes memory initcode = type(MockLifebuoyOwned).creationCode;
                initcode = abi.encodePacked(initcode, abi.encode(owner));
                _testLifebuoyCreateDeployment(deployer, initcode);
                continue;
            }
            _testLifebuoyCreateDeployment(deployer, type(MockLifebuoy).creationCode);
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
        uint256 amount;
    }

    function _erc20BalanceOf(address holder) internal view returns (uint256) {
        return SafeTransferLib.balanceOf(address(erc20), holder);
    }

    function _erc1155BalanceOf(address holder, uint256 tokenId) internal view returns (uint256) {
        return erc1155.balanceOf(holder, tokenId);
    }

    function _erc6909BalanceOf(address holder, uint256 tokenId) internal view returns (uint256) {
        return erc6909.balanceOf(holder, tokenId);
    }

    function _testTempsBase() internal returns (_TestTemps memory t) {
        t.deployer = _randomHashedAddress();
        t.owner = _randomHashedAddress();
        do {
            t.recipient = _randomHashedAddress();
        } while (t.recipient == t.deployer || t.recipient == t.owner);

        if (_randomChance(32)) t.owner = t.deployer;
        if (_randomChance(2)) vm.etch(t.deployer, " ");

        vm.prank(t.deployer);
        t.lifebuoyOwned = new MockLifebuoyOwned(t.owner);
        vm.deal(address(t.lifebuoyOwned), 1 ether);
    }

    function _testTempsForRescue() internal returns (_TestTemps memory t) {
        t = _testTempsBase();
        t.amount = _random();
        t.tokenId = _random();

        erc20.mint(address(t.lifebuoyOwned), t.amount);
        erc721.mint(address(t.lifebuoyOwned), t.tokenId);
        erc1155.mint(address(t.lifebuoyOwned), t.tokenId, t.amount, "");
        erc6909.mint(address(t.lifebuoyOwned), t.tokenId, t.amount);
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

        if (_randomChance(2) && t.deployer.code.length == 0) {
            vm.startPrank(t.deployer);
            if (_randomChance(2)) {
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

        if (_randomChance(2) && t.deployer.code.length == 0) {
            if (_randomChance(2)) {
                vm.prank(t.deployer);
                t.lifebuoyOwned.rescueETH(t.recipient, 1);
            }
            if (_randomChance(2)) {
                vm.prank(t.owner);
                t.lifebuoyOwned.rescueETH(t.recipient, 1);
            }

            if (_randomChance(2)) {
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

    function testRescueAll(bytes32) public {
        _TestTemps memory t = _testTempsForRescue();
        if (_randomChance(2)) _testRescueETH(t);
        if (_randomChance(2)) _testRescueERC20(t);
        if (_randomChance(2)) _testRescueERC721(t);
        if (_randomChance(2)) _testRescueERC1155(t);
        if (_randomChance(2)) _testRescueERC6909(t);
    }

    function _testRescueETH(_TestTemps memory t) internal {
        uint256 amount = _random();
        if (_randomChance(2)) {
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

    function _testRescueERC20(_TestTemps memory t) internal {
        uint256 amount = _random();
        if (_randomChance(2)) {
            amount = _bound(amount, 0, t.amount);
            vm.prank(t.owner);
            t.lifebuoyOwned.rescueERC20(address(erc20), t.recipient, amount);
            assertEq(_erc20BalanceOf(address(t.lifebuoyOwned)), t.amount - amount);
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

    function _testRescueERC721(_TestTemps memory t) internal {
        vm.prank(t.owner);
        t.lifebuoyOwned.rescueERC721(address(erc721), t.recipient, t.tokenId);
        assertEq(erc721.balanceOf(address(t.lifebuoyOwned)), 0);
        assertEq(erc721.balanceOf(t.recipient), 1);
        vm.prank(t.owner);
        vm.expectRevert(Lifebuoy.RescueTransferFailed.selector);
        t.lifebuoyOwned.rescueERC721(address(erc721), t.recipient, t.tokenId);

        address eoa = _randomHashedAddress();
        vm.prank(t.owner);
        vm.expectRevert(Lifebuoy.RescueTransferFailed.selector);
        t.lifebuoyOwned.rescueERC721(eoa, t.recipient, t.tokenId);
    }

    function _testRescueERC1155(_TestTemps memory t) public {
        uint256 amount = _random();
        if (_randomChance(2)) {
            amount = _bound(amount, 0, t.amount);
            vm.prank(t.owner);
            t.lifebuoyOwned.rescueERC1155(address(erc1155), t.recipient, t.tokenId, amount, "");
            assertEq(_erc1155BalanceOf(address(t.lifebuoyOwned), t.tokenId), t.amount - amount);
            assertEq(_erc1155BalanceOf(t.recipient, t.tokenId), amount);
        } else if (amount > _erc1155BalanceOf(address(t.lifebuoyOwned), t.tokenId)) {
            vm.prank(t.owner);
            vm.expectRevert(Lifebuoy.RescueTransferFailed.selector);
            t.lifebuoyOwned.rescueERC1155(address(erc1155), t.recipient, t.tokenId, amount, "");
        } else {
            bytes memory data = _randomBytes();
            vm.prank(t.owner);
            t.lifebuoyOwned.rescueERC1155(address(erc1155), t.recipient, t.tokenId, amount, data);
            assertEq(erc1155.lastDataHash(), keccak256(data));
        }
    }

    function _testRescueERC6909(_TestTemps memory t) public {
        uint256 amount = _random();
        if (_randomChance(2)) {
            amount = _bound(amount, 0, t.amount);
            vm.prank(t.owner);
            t.lifebuoyOwned.rescueERC6909(address(erc6909), t.recipient, t.tokenId, amount);
            assertEq(_erc6909BalanceOf(address(t.lifebuoyOwned), t.tokenId), t.amount - amount);
            assertEq(_erc6909BalanceOf(t.recipient, t.tokenId), amount);
        } else if (amount > _erc6909BalanceOf(address(t.lifebuoyOwned), t.tokenId)) {
            vm.prank(t.owner);
            vm.expectRevert(Lifebuoy.RescueTransferFailed.selector);
            t.lifebuoyOwned.rescueERC6909(address(erc6909), t.recipient, t.tokenId, amount);
        } else {
            vm.prank(t.owner);
            t.lifebuoyOwned.rescueERC6909(address(erc6909), t.recipient, t.tokenId, amount);
        }
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
        t.lifebuoyOwned.rescueERC6909(address(erc6909), t.recipient, t.tokenId, _random());
        vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        t.lifebuoyOwned.rescueERC1155(address(erc1155), t.recipient, t.tokenId, _random(), "");
        vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        t.lifebuoyOwned.rescueERC721(address(erc721), t.recipient, t.tokenId);
        vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        t.lifebuoyOwned.rescueERC20(address(erc20), t.recipient, _random());
        vm.expectRevert(Lifebuoy.RescueUnauthorizedOrLocked.selector);
        t.lifebuoyOwned.rescueETH(t.recipient, _random());
    }
}
