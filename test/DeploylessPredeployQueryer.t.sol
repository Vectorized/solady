// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibClone} from "../src/utils/LibClone.sol";
import {DeploylessPredeployQueryer} from "../src/utils/DeploylessPredeployQueryer.sol";

library RandomBytesGeneratorLib {
    function generate(uint256 seed) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := add(0x20, mload(0x40))
            mstore(0x00, seed)
            let n := mod(keccak256(0x00, 0x20), 50)
            mstore(result, n)
            for { let i := 0 } lt(i, n) { i := add(i, 0x20) } {
                mstore(0x20, i)
                mstore(add(i, add(result, 0x20)), keccak256(0x00, 0x40))
            }
            mstore(0x40, add(n, add(result, 0x20)))
        }
    }

    function next(uint256 seed) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, seed)
            result := keccak256(0x00, 0x20)
        }
    }
}

contract Target {
    function generate(uint256 seed) public pure returns (bytes memory result) {
        result = RandomBytesGeneratorLib.generate(seed);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(sub(result, 0x20), 0x20)
            return(sub(result, 0x20), add(add(0x40, mod(seed, 50)), mload(result)))
        }
    }

    function next(uint256 seed) public pure returns (uint256 result) {
        result = RandomBytesGeneratorLib.next(seed);
    }
}

contract Factory {
    address public implementation;

    constructor() {
        implementation = address(new Target());
    }

    function deploy(bytes32 salt) public returns (address) {
        if (predictDeployment(salt).code.length != 0) return predictDeployment(salt);
        return LibClone.cloneDeterministic(implementation, salt);
    }

    function predictDeployment(bytes32 salt) public view returns (address) {
        return LibClone.predictDeterministicAddress(implementation, salt, address(this));
    }
}

contract DeploylessPredeployQueryerTest is SoladyTest {
    Factory factory;

    function setUp() public {
        factory = new Factory();
    }

    struct _TestTemps {
        address target;
        uint256 seed;
        address deployed;
        bytes factoryCalldata;
        bytes targetQueryCalldata;
    }

    function testPredeployQueryer(bytes32 salt) public {
        _TestTemps memory t;
        t.target = factory.predictDeployment(salt);
        if (_random() % 2 == 0) {
            assertEq(factory.deploy(salt), t.target);
        }
        t.factoryCalldata = abi.encodeWithSignature("deploy(bytes32)", salt);
        t.seed = _random();
        if (_random() % 2 == 0) {
            vm.expectRevert(DeploylessPredeployQueryer.ReturnedAddressMismatch.selector);
            address wrongTarget = address(uint160(t.target) ^ 1);
            t.deployed = address(
                new DeploylessPredeployQueryer(
                    wrongTarget, t.targetQueryCalldata, address(factory), t.factoryCalldata
                )
            );
        }
        if (_random() % 2 == 0) {
            t.targetQueryCalldata = abi.encodeWithSignature("generate(uint256)", t.seed);
            t.deployed = address(
                new DeploylessPredeployQueryer(
                    t.target, t.targetQueryCalldata, address(factory), t.factoryCalldata
                )
            );
            assertEq(
                abi.decode(abi.decode(t.deployed.code, (bytes)), (bytes)),
                RandomBytesGeneratorLib.generate(t.seed)
            );
        }
        t.targetQueryCalldata = abi.encodeWithSignature("next(uint256)", t.seed);
        t.deployed = address(
            new DeploylessPredeployQueryer(
                t.target, t.targetQueryCalldata, address(factory), t.factoryCalldata
            )
        );
        assertEq(
            abi.decode(abi.decode(t.deployed.code, (bytes)), (uint256)),
            RandomBytesGeneratorLib.next(t.seed)
        );
    }
}
