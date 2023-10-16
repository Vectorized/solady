// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {MockERC4337} from "./utils/mocks/MockERC4337.sol";
import {ERC4337Factory} from "../src/accounts/ERC4337Factory.sol";
import {LibClone} from "../src/utils/LibClone.sol";

contract ERC4337FactoryTest is SoladyTest {
    ERC4337Factory factory;

    MockERC4337 implementation0;

    struct _TestTemps {
        uint256 key;
        uint256 value;
        uint256 msgValue;
        bytes32 salt;
        address predictedProxy;
        address proxy;
    }

    function _testTemps() internal returns (_TestTemps memory t) {
        t.key = _random();
        t.value = _random();
        t.msgValue = _bound(_random(), 0, uint256(type(uint96).max));
        t.salt = bytes32(_random() & uint256(type(uint96).max));
    }

    function setUp() public {
        implementation0 = new MockERC4337();
        factory = new ERC4337Factory(address(implementation0));
    }

    function testDeploy() public {
        vm.deal(address(this), 100 ether);
        address account = factory.deploy{value: 100 ether}(address(0xABCD));
        _checkImplementationSlot(account, address(implementation0));
        assertEq(MockERC4337(payable(account)).owner(), address(0xABCD));
        assertEq(account.balance, 100 ether);
    }

    function testDeployBrutalized(uint256) public {
        (address admin,) = _randomSigner();
        address implementation = address(implementation0);
        bool brutalized;
        bool success;
        address f = address(factory);
        /// @solidity memory-safe-assembly
        assembly {
            calldatacopy(0x00, 0x00, 0x40)
            brutalized := eq(and(mload(0x00), 1), 0)
            if brutalized {
                // Extremely unlikely that all 96 upper bits will be zero.
                admin := or(shl(160, keccak256(0x00, 0x20)), admin)
                implementation := or(shl(160, keccak256(0x00, 0x40)), implementation)
            }
            let m := mload(0x40)
            mstore(m, 0x4c96a389) // `deploy(address, address)`.
            mstore(add(m, 0x20), admin)
            mstore(0x00, 0)
            // Basically, we want to demonstrate that Solidity has checks
            // to reject dirty upper bits for addresses.
            success := call(gas(), f, 0, add(m, 0x1c), 0x24, 0x00, 0x20)
            // If the call is successful, there will be a deployment.
            if and(success, iszero(mload(0x00))) { revert(0, 0) }
        }
        assertEq(brutalized, !success);
    }

    function testDeployDeterministic(uint256) public {
        (address owner,) = _randomSigner();
        _TestTemps memory t = _testTemps();

        t.predictedProxy =
            LibClone.predictDeterministicAddress(factory.initCodeHash(), t.salt, address(factory));
        vm.deal(owner, type(uint128).max);
        vm.prank(owner);
        if (_random() % 8 == 0) {
            t.salt = keccak256(abi.encode(_random()));
            vm.expectRevert(LibClone.SaltDoesNotStartWith.selector);
            t.proxy = factory.deployDeterministic{value: t.msgValue}(owner, t.salt);
            return;
        } else {
            t.proxy = factory.deployDeterministic{value: t.msgValue}(owner, t.salt);
            assertEq(t.proxy, t.predictedProxy);
        }

        assertEq(MockERC4337(payable(t.proxy)).owner(), owner);
        assertTrue(t.proxy != address(0));
        assertTrue(t.proxy.code.length > 0);
        _checkImplementationSlot(t.proxy, address(implementation0));
        assertEq(t.proxy.balance, t.msgValue);
    }

    function testDeployDeterministicRevertWithDeploymentFailed() public {
        bytes32 salt = bytes32(_random() & uint256(type(uint96).max));
        factory.deployDeterministic(address(0xABCD), salt);
        vm.expectRevert(LibClone.DeploymentFailed.selector);
        factory.deployDeterministic(address(0xABCD), salt);
    }

    function _checkImplementationSlot(address proxy, address implementation_) internal {
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        assertEq(vm.load(proxy, slot), bytes32(uint256(uint160(implementation_))));
    }
}
