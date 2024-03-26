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

    bytes internal constant _CREATION_CODE =
        hex"608060405261019d80380380610014816100f6565b9283398101906080818303126100f1578051602080830151909291906001600160401b03908181116100f1578561004c918501610131565b9260408101519560608201519283116100f157859261006b9201610131565b94604051958691843b156100b3575b50505050600091389184825192019034905af1156100a9578082523d908201523d6000604083013e3d60600190f35b503d6000823e3d90fd5b8460011883528382519201903d905af1156100e757808451036100d9578284388061007a565b63d1f6b8126000526004601cfd5b833d6000823e3d90fd5b600080fd5b6040519190601f01601f191682016001600160401b0381118382101761011b57604052565b634e487b7160e01b600052604160045260246000fd5b919080601f840112156100f15782516001600160401b03811161011b57602090610163601f8201601f191683016100f6565b928184528282870101116100f15760005b81811061018957508260009394955001015290565b858101830151848201840152820161017456fe";

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

    function _deployQuery(
        address target,
        bytes memory targetQueryCalldata,
        bytes memory factoryCalldata
    ) internal returns (address result) {
        if (_random() % 2 == 0) {
            return address(
                new DeploylessPredeployQueryer(
                    target, targetQueryCalldata, address(factory), factoryCalldata
                )
            );
        }
        bytes memory initcode = abi.encodePacked(
            _CREATION_CODE,
            abi.encode(target, targetQueryCalldata, address(factory), factoryCalldata)
        );
        /// @solidity memory-safe-assembly
        assembly {
            result := create(0, add(0x20, initcode), mload(initcode))
        }
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
            t.deployed = _deployQuery(wrongTarget, t.targetQueryCalldata, t.factoryCalldata);
        }
        if (_random() % 2 == 0) {
            t.targetQueryCalldata = abi.encodeWithSignature("generate(uint256)", t.seed);
            t.deployed = _deployQuery(t.target, t.targetQueryCalldata, t.factoryCalldata);
            assertEq(
                abi.decode(abi.decode(t.deployed.code, (bytes)), (bytes)),
                RandomBytesGeneratorLib.generate(t.seed)
            );
        }
        t.targetQueryCalldata = abi.encodeWithSignature("next(uint256)", t.seed);
        t.deployed = _deployQuery(t.target, t.targetQueryCalldata, t.factoryCalldata);
        assertEq(
            abi.decode(abi.decode(t.deployed.code, (bytes)), (uint256)),
            RandomBytesGeneratorLib.next(t.seed)
        );
    }
}
