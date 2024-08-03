// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {MockImplementation} from "./utils/mocks/MockImplementation.sol";
import {ERC1967Factory} from "../src/utils/ERC1967Factory.sol";
import {ERC1967FactoryConstants} from "../src/utils/ERC1967FactoryConstants.sol";

contract ERC1967FactoryTest is SoladyTest {
    event AdminChanged(address indexed proxy, address indexed admin);

    event Upgraded(address indexed proxy, address indexed implementation);

    event Deployed(address indexed proxy, address indexed implementation, address indexed admin);

    ERC1967Factory factory;
    address implementation0;
    address implementation1;

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
        factory = new ERC1967Factory();
        implementation0 = address(new MockImplementation());
        implementation1 = address(new MockImplementation());
    }

    modifier withFactories() {
        _;
        {
            address minedFactoryAddress = 0x0000000000001122334455667788990011223344;
            vm.etch(minedFactoryAddress, address(factory).code);
            factory = ERC1967Factory(minedFactoryAddress);
        }
        _;
    }

    function testDeploy() public withFactories {
        (address admin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implementation0, admin);
        _checkProxyBytecode(proxy);

        assertEq(factory.adminOf(proxy), admin);
        assertTrue(proxy != address(0));
        assertTrue(proxy.code.length > 0);
        _checkImplementationSlot(proxy, implementation0);
    }

    function testDeployBrutalized(uint256) public withFactories {
        (address admin,) = _randomSigner();
        admin = _cleaned(admin);
        address implementation = implementation0;
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
            mstore(m, 0x545e7c61) // `deploy(address, address)`.
            mstore(add(m, 0x20), implementation)
            mstore(add(m, 0x40), admin)
            mstore(0x00, 0)
            // Basically, we want to demonstrate that Solidity has checks
            // to reject dirty upper bits for addresses.
            success := call(gas(), f, 0, add(m, 0x1c), 0x44, 0x00, 0x20)
            // If the call is successful, there will be a deployment.
            if and(success, iszero(mload(0x00))) { revert(0, 0) }
        }
        assertEq(brutalized, !success);
    }

    function testDeployAndCall(uint256) public withFactories {
        (address admin,) = _randomSigner();
        _TestTemps memory t = _testTemps();

        bytes memory data = abi.encodeWithSignature("setValue(uint256,uint256)", t.key, t.value);
        vm.deal(admin, type(uint128).max);
        vm.prank(admin);
        address proxy = factory.deployAndCall{value: t.msgValue}(implementation0, admin, data);

        assertEq(factory.adminOf(proxy), admin);
        assertTrue(proxy != address(0));
        assertTrue(proxy.code.length > 0);
        _checkImplementationSlot(proxy, implementation0);
        assertEq(MockImplementation(proxy).getValue(t.key), t.value);
        assertEq(proxy.balance, t.msgValue);
    }

    function testDeployDeterministicAndCall(uint256) public withFactories {
        (address admin,) = _randomSigner();
        _TestTemps memory t = _testTemps();

        t.predictedProxy = factory.predictDeterministicAddress(t.salt);
        bytes memory data = abi.encodeWithSignature("setValue(uint256,uint256)", t.key, t.value);
        vm.deal(admin, type(uint128).max);
        vm.prank(admin);
        if (_randomChance(8)) {
            t.salt = keccak256(abi.encode(_random()));
            vm.expectRevert(ERC1967Factory.SaltDoesNotStartWithCaller.selector);
            t.proxy = factory.deployDeterministicAndCall{value: t.msgValue}(
                implementation0, admin, t.salt, data
            );
            return;
        } else {
            vm.expectEmit(true, true, true, true);
            emit Deployed(t.predictedProxy, implementation0, _cleaned(admin));
            t.proxy = factory.deployDeterministicAndCall{value: t.msgValue}(
                implementation0, admin, t.salt, data
            );
            assertEq(t.proxy, t.predictedProxy);
        }

        assertEq(factory.adminOf(t.proxy), admin);
        assertTrue(t.proxy != address(0));
        assertTrue(t.proxy.code.length > 0);
        _checkImplementationSlot(t.proxy, implementation0);
        assertEq(MockImplementation(t.proxy).getValue(t.key), t.value);
        assertEq(t.proxy.balance, t.msgValue);
    }

    function testDeployAndCallWithRevert() public withFactories {
        (address admin,) = _randomSigner();

        bytes memory data = abi.encodeWithSignature("fails()");
        vm.expectRevert(MockImplementation.Fail.selector);
        factory.deployAndCall(implementation0, admin, data);
    }

    function testProxySucceeds() public withFactories {
        (address admin,) = _randomSigner();
        uint256 a = 1;

        MockImplementation proxy = MockImplementation(factory.deploy(implementation0, admin));

        assertEq(proxy.succeeds(a), a);
    }

    function testProxyFails() public withFactories {
        (address admin,) = _randomSigner();

        address proxy = factory.deploy(implementation0, admin);

        vm.expectRevert(MockImplementation.Fail.selector);
        MockImplementation(proxy).fails();
    }

    function testChangeAdmin() public withFactories {
        (address admin, address newAdmin) = _randomAccounts();

        vm.prank(admin);
        address proxy = factory.deploy(implementation0, admin);

        vm.expectEmit(true, true, true, true, address(factory));
        emit AdminChanged(proxy, _cleaned(newAdmin));

        vm.prank(admin);
        factory.changeAdmin(proxy, newAdmin);

        assertEq(factory.adminOf(proxy), newAdmin);
    }

    function testChangeAdminUnauthorized() public withFactories {
        (address admin, address sussyAccount) = _randomAccounts();

        vm.prank(admin);
        address proxy = factory.deploy(implementation0, admin);

        vm.expectRevert(ERC1967Factory.Unauthorized.selector);

        vm.prank(sussyAccount);
        factory.changeAdmin(proxy, sussyAccount);
    }

    function testUpgrade() public withFactories {
        (address admin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implementation0, admin);

        vm.expectEmit(true, true, true, true, address(factory));
        emit Upgraded(proxy, implementation1);

        vm.prank(admin);
        factory.upgrade(proxy, implementation1);

        _checkImplementationSlot(proxy, implementation1);
    }

    function testUpgradeAndCall() public withFactories {
        (address admin,) = _randomSigner();
        _TestTemps memory t = _testTemps();

        vm.prank(admin);
        address proxy = factory.deploy(implementation0, admin);

        vm.expectEmit(true, true, true, true, address(factory));
        emit Upgraded(proxy, implementation1);

        vm.prank(admin);
        vm.deal(admin, type(uint128).max);
        bytes memory data = abi.encodeWithSignature("setValue(uint256,uint256)", t.key, t.value);
        factory.upgradeAndCall{value: t.msgValue}(proxy, implementation1, data);

        _checkImplementationSlot(proxy, implementation1);
        uint256 gasBefore = gasleft();
        uint256 storedValue = MockImplementation(proxy).getValue(t.key);
        unchecked {
            uint256 gasUsed = gasBefore - gasleft();
            emit LogUint("gasUsed", gasUsed);
        }
        assertEq(storedValue, t.value);
        assertEq(proxy.balance, t.msgValue);
    }

    function testUpgradeAndCallWithRevert() public withFactories {
        (address admin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implementation0, admin);

        vm.prank(admin);
        vm.expectRevert(MockImplementation.Fail.selector);
        factory.upgradeAndCall(proxy, implementation1, abi.encodeWithSignature("fails()"));
    }

    function testUpgradeUnauthorized() public withFactories {
        (address admin, address sussyAccount) = _randomAccounts();

        vm.prank(admin);
        address proxy = factory.deploy(implementation0, admin);

        vm.expectRevert(ERC1967Factory.Unauthorized.selector);
        vm.prank(sussyAccount);
        factory.upgrade(proxy, implementation1);

        vm.expectRevert(ERC1967Factory.Unauthorized.selector);
        vm.prank(address(uint160(admin) ^ 1));
        factory.upgrade(proxy, implementation1);

        vm.prank(admin);
        factory.upgrade(proxy, implementation1);
    }

    function testUpgradeWithCorruptedProxy() public withFactories {
        (address admin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implementation0, admin);

        vm.expectRevert(ERC1967Factory.Unauthorized.selector);
        vm.prank(admin);
        factory.upgrade(address(uint160(proxy) ^ 1), implementation1);

        _checkImplementationSlot(proxy, implementation0);
    }

    function testFactoryDeployment() public {
        address deployment =
            _safeCreate2(ERC1967FactoryConstants.SALT, ERC1967FactoryConstants.INITCODE);
        assertEq(deployment, ERC1967FactoryConstants.ADDRESS);
        assertEq(deployment.code, ERC1967FactoryConstants.BYTECODE);
    }

    function _randomAccounts() internal returns (address a, address b) {
        (a,) = _randomSigner();
        do {
            (b,) = _randomSigner();
        } while (a == b);
    }

    function _checkImplementationSlot(address proxy, address implementation) internal {
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        assertEq(vm.load(proxy, slot), bytes32(uint256(uint160(implementation))));
    }

    function _checkProxyBytecode(address proxy) internal {
        bytes memory code = address(proxy).code;
        assertEq(uint8(bytes1(code[code.length - 1])), 0xfd);
        assertTrue(code.length == 127 || code.length == 121);
    }
}
