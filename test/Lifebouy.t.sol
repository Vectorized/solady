// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {
    MockLifebouy,
    MockLifebouyOwned,
    MockLifebouyDeployerFallback,
    MockLifebouyDeployerNoFallback
} from "./utils/mocks/MockLifebouy.sol";
import {MockETHRecipient} from "./utils/mocks/MockETHRecipient.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";

contract LifebouyTest is SoladyTest {
    error ETHTransferFailed();

    event RescueLocked();

    address deployer = address(0xdeadbeef);
    address owner = address(0xcafe);

    MockLifebouy mockLifebouy;
    MockLifebouyOwned mockLifebouyOwned;

    MockERC20 mockERC20;
    MockERC721 mockERC721;

    address erc20;
    address erc721;

    function setUp() public {
        vm.deal(deployer, 10 ether);

        vm.startPrank(deployer);

        mockERC20 = new MockERC20("Name", "SYMBOL", 18);
        mockERC721 = new MockERC721();

        erc20 = address(mockERC20);
        erc721 = address(mockERC721);

        mockLifebouy = _newMockLifebouy();
        mockLifebouyOwned = _newMockLifebouyOwned(owner);

        vm.stopPrank();
    }

    // CONSTRUCTOR

    function testConstructorSendsETHToEOACaller() public {
        uint256 balanceBefore = deployer.balance;

        vm.txGasPrice(0);
        vm.prank(deployer);

        MockLifebouy mock = new MockLifebouy{value: 0.5 ether}();

        // Expects ETH to end up on the deployer (msg.sender).
        assertEq(0, address(mock).balance);
        assertEq(balanceBefore, deployer.balance);
        assertEq(deployer, mock.deployer());
        assertEq(false, mock.rescueLocked());
    }

    function testConstructorSendsETHToContractCaller() public {
        uint256 balanceBefore = deployer.balance;

        vm.txGasPrice(0);
        vm.prank(deployer);

        MockLifebouyDeployerFallback mock = new MockLifebouyDeployerFallback{value: 0.5 ether}();
        MockLifebouy lifebouy = MockLifebouy(mock.mock());

        // Expects ETH to end up on the deployer contract (msg.sender).
        assertEq(0, address(lifebouy).balance);
        assertEq(balanceBefore - 0.5 ether, deployer.balance);
        assertEq(0.5 ether, address(mock).balance);
        assertEq(address(mock), lifebouy.deployer());
        assertEq(false, lifebouy.rescueLocked());
    }

    function testConstructorSendsETHToOrigin() public {
        uint256 balanceBefore = tx.origin.balance;

        MockLifebouyDeployerNoFallback mock = new MockLifebouyDeployerNoFallback();

        vm.prank(deployer);

        mock.deployMock{value: 0.5 ether}();

        MockLifebouy lifebouy = MockLifebouy(mock.mock());

        // Expects ETH to end up on the tx origin.
        assertEq(0, address(mock).balance);
        assertEq(0, address(lifebouy).balance);
        assertEq(balanceBefore + 0.5 ether, tx.origin.balance);
        assertEq(tx.origin, lifebouy.deployer());
        assertEq(false, lifebouy.rescueLocked());
    }

    // EXTERNAL

    function testLockRescue() public {
        assertEq(false, mockLifebouyOwned.rescueLocked());

        vm.startPrank(deployer);
        vm.expectEmit();

        emit RescueLocked();

        mockLifebouy.lockRescue();

        assertEq(true, mockLifebouy.rescueLocked());
        assertEq(deployer, mockLifebouy.deployer());

        vm.expectRevert(0x350c1e72);

        mockLifebouy.lockRescue();

        vm.stopPrank();
    }

    function testLockRescueOwned() public {
        assertEq(false, mockLifebouyOwned.rescueLocked());

        vm.startPrank(owner);
        vm.expectEmit();

        emit RescueLocked();

        mockLifebouyOwned.lockRescue();

        assertEq(true, mockLifebouyOwned.rescueLocked());
        assertEq(deployer, mockLifebouyOwned.deployer());

        vm.expectRevert(0x350c1e72);

        mockLifebouyOwned.lockRescue();

        vm.stopPrank();
        vm.startPrank(deployer);

        MockLifebouyOwned deployerCalled = new MockLifebouyOwned(owner);

        vm.expectEmit();

        emit RescueLocked();

        deployerCalled.lockRescue();

        assertEq(true, deployerCalled.rescueLocked());

        vm.stopPrank();
    }

    function testLockRescueNotDeployer(address caller) public {
        vm.assume(caller != deployer);

        vm.prank(caller);
        vm.expectRevert(0x3d693ada);

        mockLifebouy.lockRescue();
    }

    // ETH RESCUE

    function testRescueETH(uint256 amount) public {
        uint256 mockBalanceBefore = address(mockLifebouy).balance;

        vm.assume(amount <= mockBalanceBefore);

        uint256 balanceBefore = deployer.balance;

        vm.txGasPrice(0);
        vm.prank(deployer);

        mockLifebouy.rescueETH(deployer, amount);

        assertEq(mockBalanceBefore - amount, address(mockLifebouy).balance);
        assertEq(balanceBefore + amount, deployer.balance);
    }

    function testRescueETHOwned(uint256 amount) public {
        uint256 mockBalanceBefore = address(mockLifebouyOwned).balance;

        vm.assume(amount <= mockBalanceBefore / 2);

        uint256 balanceBefore = deployer.balance;

        vm.txGasPrice(0);
        vm.prank(deployer);

        mockLifebouyOwned.rescueETH(deployer, amount);

        assertEq(mockBalanceBefore - amount, address(mockLifebouyOwned).balance);
        assertEq(balanceBefore + amount, deployer.balance);

        uint256 secondAmount = mockBalanceBefore - amount;

        mockBalanceBefore = address(mockLifebouyOwned).balance;
        balanceBefore = owner.balance;

        vm.txGasPrice(0);
        vm.prank(owner);

        mockLifebouyOwned.rescueETH(owner, secondAmount);

        assertEq(mockBalanceBefore - secondAmount, address(mockLifebouyOwned).balance);
        assertEq(balanceBefore + secondAmount, owner.balance);
    }

    function testRescueETHNotAllowed(address caller, uint256 amount) public {
        vm.assume(caller != deployer);

        vm.prank(caller);
        vm.expectRevert(0x3d693ada);

        mockLifebouy.rescueETH(caller, amount);
    }

    function testRescueETHLockedRescue(uint256 amount) public {
        vm.assume(amount <= address(mockLifebouy).balance);

        vm.startPrank(deployer);

        mockLifebouy.lockRescue();

        vm.expectRevert(0x350c1e72);

        mockLifebouy.rescueETH(deployer, amount);

        vm.stopPrank();
    }

    // ERC20 RESCUE

    function testRescueERC20(uint256 amount) public {
        uint256 mockBalanceBefore = mockERC20.balanceOf(address(mockLifebouy));

        vm.assume(amount <= mockBalanceBefore);

        uint256 balanceBefore = mockERC20.balanceOf(deployer);

        vm.prank(deployer);

        mockLifebouy.rescueERC20(erc20, deployer, amount);

        assertEq(mockBalanceBefore - amount, mockERC20.balanceOf(address(mockLifebouy)));
        assertEq(balanceBefore + amount, mockERC20.balanceOf(deployer));
    }

    function testRescueERC20Owned(uint256 amount) public {
        uint256 mockBalanceBefore = mockERC20.balanceOf(address(mockLifebouyOwned));

        vm.assume(amount <= mockBalanceBefore / 2);

        uint256 balanceBefore = mockERC20.balanceOf(deployer);

        vm.prank(deployer);

        mockLifebouyOwned.rescueERC20(erc20, deployer, amount);

        assertEq(mockBalanceBefore - amount, mockERC20.balanceOf(address(mockLifebouyOwned)));
        assertEq(balanceBefore + amount, mockERC20.balanceOf(deployer));

        uint256 secondAmount = mockBalanceBefore - amount;

        mockBalanceBefore = mockERC20.balanceOf(address(mockLifebouyOwned));
        balanceBefore = mockERC20.balanceOf(owner);

        vm.prank(owner);

        mockLifebouyOwned.rescueERC20(erc20, owner, secondAmount);

        assertEq(mockBalanceBefore - secondAmount, mockERC20.balanceOf(address(mockLifebouyOwned)));
        assertEq(balanceBefore + secondAmount, mockERC20.balanceOf(owner));
    }

    function testRescueERC20NotAllowed(address caller, uint256 amount) public {
        vm.assume(caller != deployer);

        vm.prank(caller);
        vm.expectRevert(0x3d693ada);

        mockLifebouy.rescueERC20(erc20, caller, amount);
    }

    function testRescueERC20LockedRescue(uint256 amount) public {
        vm.assume(amount <= address(mockLifebouy).balance);

        vm.startPrank(deployer);

        mockLifebouy.lockRescue();

        vm.expectRevert(0x350c1e72);

        mockLifebouy.rescueERC20(erc20, deployer, amount);

        vm.stopPrank();
    }

    // ERC721 RESCUE

    function testRescueERC721(uint256 id) public {
        vm.assume(id < 99999);

        mockERC721.mint(address(mockLifebouy), id);

        vm.prank(deployer);

        mockLifebouy.rescueERC721(erc721, deployer, id);

        assertEq(deployer, mockERC721.ownerOf(id));
    }

    function testRescueERC721Owned(uint256 id) public {
        vm.assume(id < 99999);

        mockERC721.mint(address(mockLifebouyOwned), id);

        vm.prank(deployer);

        mockLifebouyOwned.rescueERC721(erc721, deployer, id);

        assertEq(deployer, mockERC721.ownerOf(id));

        mockERC721.mint(address(mockLifebouyOwned), id + 1);

        vm.prank(owner);

        mockLifebouyOwned.rescueERC721(erc721, owner, id + 1);

        assertEq(owner, mockERC721.ownerOf(id + 1));
    }

    function testRescueERC721NotAllowed(address caller, uint256 id) public {
        vm.assume(caller != deployer && id < 99999);

        mockERC721.mint(address(mockLifebouyOwned), id);

        vm.prank(caller);
        vm.expectRevert(0x3d693ada);

        mockLifebouy.rescueERC721(erc721, caller, id);
    }

    function testRescueERC721LockedRescue(uint256 id) public {
        vm.assume(id < 99999);

        vm.startPrank(deployer);

        mockLifebouy.lockRescue();

        vm.expectRevert(0x350c1e72);

        mockLifebouy.rescueERC721(erc20, deployer, id);

        vm.stopPrank();
    }

    // PRIVATE

    function _newMockLifebouy() private returns (MockLifebouy) {
        MockLifebouy mock = new MockLifebouy();
        address mockAddr = address(mock);

        mock.payMe{value: 0.5 ether}();
        mockERC20.mint(mockAddr, 100 ether);

        return mock;
    }

    function _newMockLifebouyOwned(address owner_) private returns (MockLifebouyOwned) {
        MockLifebouyOwned mock = new MockLifebouyOwned(owner_);
        address mockAddr = address(mock);

        mock.payMe{value: 0.5 ether}();
        mockERC20.mint(mockAddr, 100 ether);

        return mock;
    }
}
