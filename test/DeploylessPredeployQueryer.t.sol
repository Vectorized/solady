// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibClone} from "../src/utils/LibClone.sol";
import {DeploylessPredeployQueryer} from "../src/utils/DeploylessPredeployQueryer.sol";

library RandomBytesGeneratorLib {
    function generate(bytes memory seed) internal pure returns (bytes memory result) {
        result = generate(uint256(keccak256(seed)));
    }

    function generate(uint256 seed) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := add(0x20, mload(0x40))
            mstore(0x00, seed)
            let n := mod(keccak256(0x00, 0x20), 300)
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
    function generate(bytes memory seed) public pure returns (bytes memory result) {
        result = RandomBytesGeneratorLib.generate(seed);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(sub(result, 0x20), 0x20)
            return(sub(result, 0x20), add(add(0x40, mod(seed, 50)), mload(result)))
        }
    }

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
        hex"3860b63d393d516020805190606051833b15607e575b5059926040908285528351938460051b9459523d604087015260005b858103603e578680590390f35b6000828683820101510138908688820151910147875af115607457603f19875903018482890101523d59523d6000593e84016031565b3d6000803e3d6000fd5b816000828193519083479101906040515af11560ad5783815114601f3d111660155763d1f6b81290526004601cfd5b3d81803e3d90fdfe";

    function setUp() public {
        factory = new Factory();
    }

    struct _TestTemps {
        address target;
        uint256 n;
        uint256[] seeds;
        bytes[] bytesSeeds;
        address deployed;
        bytes factoryCalldata;
        bytes[] targetQueryCalldata;
        bytes[] decoded;
    }

    function _deployQuery(
        address target,
        bytes[] memory targetQueryCalldata,
        bytes memory factoryCalldata
    ) internal returns (address result) {
        if (_random() % 2 == 0) {
            return address(
                new DeploylessPredeployQueryer(
                    target, targetQueryCalldata, address(factory), factoryCalldata
                )
            );
        }
        bytes memory args =
            abi.encode(target, targetQueryCalldata, address(factory), factoryCalldata);
        bytes memory initcode;
        if (false && _random() % 2 == 0) {
            initcode = _CREATION_CODE;
        } else {
            initcode = type(DeploylessPredeployQueryer).creationCode;
        }
        initcode = abi.encodePacked(initcode, args);
        /// @solidity memory-safe-assembly
        assembly {
            result := create(0, add(0x20, initcode), mload(initcode))
        }
    }

    function testTargetGenerate() public {
        Target target = new Target();
        for (uint256 i; i < 16; ++i) {
            bytes memory seed = _randomBytes();
            assertEq(target.generate(seed), RandomBytesGeneratorLib.generate(seed));
        }
    }

    function testPredeployQueryer(bytes32 salt) public {
        unchecked {
            _TestTemps memory t;
            t.target = factory.predictDeployment(salt);
            if (_random() % 2 == 0) {
                assertEq(factory.deploy(salt), t.target);
            }
            t.factoryCalldata = abi.encodeWithSignature("deploy(bytes32)", salt);
            t.n = _random() % 3;
            t.targetQueryCalldata = new bytes[](t.n);
            t.seeds = new uint256[](t.n);
            t.bytesSeeds = new bytes[](t.n);
            if (_random() % 2 == 0) {
                vm.expectRevert(DeploylessPredeployQueryer.ReturnedAddressMismatch.selector);
                address wrongTarget = address(uint160(t.target) ^ 1);
                t.deployed = _deployQuery(wrongTarget, t.targetQueryCalldata, t.factoryCalldata);
            }
            if (_random() % 2 == 0) {
                for (uint256 i; i < t.n; ++i) {
                    t.bytesSeeds[i] = _randomBytes();
                    t.targetQueryCalldata[i] =
                        abi.encodeWithSignature("generate(bytes)", t.bytesSeeds[i]);
                }
                t.deployed = _deployQuery(t.target, t.targetQueryCalldata, t.factoryCalldata);
                t.decoded = abi.decode(t.deployed.code, (bytes[]));
                assertEq(t.decoded.length, t.n);
                for (uint256 i; i < t.n; ++i) {
                    assertEq(
                        abi.decode(t.decoded[i], (bytes)),
                        RandomBytesGeneratorLib.generate(t.bytesSeeds[i])
                    );
                }
            }
            for (uint256 i; i < t.n; ++i) {
                t.seeds[i] = _random();
                t.targetQueryCalldata[i] = abi.encodeWithSignature("next(uint256)", t.seeds[i]);
            }
            t.deployed = _deployQuery(t.target, t.targetQueryCalldata, t.factoryCalldata);
            t.decoded = abi.decode(t.deployed.code, (bytes[]));
            for (uint256 i; i < t.n; ++i) {
                assertEq(
                    abi.decode(t.decoded[i], (uint256)), RandomBytesGeneratorLib.next(t.seeds[i])
                );
            }
        }
    }

    function _randomBytes() internal returns (bytes memory result) {
        uint256 r = _random();
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(0x00, r)
            let n := mod(r, 300)
            codecopy(add(result, 0x20), and(keccak256(0x00, 0x20), 0xff), codesize())
            mstore(0x40, add(n, add(0x40, result)))
            mstore(result, n)
        }
    }
}
