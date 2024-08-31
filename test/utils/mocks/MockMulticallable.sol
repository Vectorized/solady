// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Multicallable} from "../../../src/utils/Multicallable.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockMulticallable is Multicallable, Brutalizer {
    error CustomError();

    struct Tuple {
        uint256 a;
        uint256 b;
    }

    function revertsWithString(string memory e) external pure {
        revert(e);
    }

    function revertsWithCustomError() external pure {
        revert CustomError();
    }

    function revertsWithNothing() external pure {
        revert();
    }

    function returnsTuple(uint256 a, uint256 b) external pure returns (Tuple memory tuple) {
        tuple = Tuple({a: a, b: b});
    }

    function returnsString(string calldata s) external pure returns (string memory) {
        return s;
    }

    function returnsRandomizedString(string calldata s) external pure returns (string memory) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := add(mload(0x40), 0x20)
            calldatacopy(m, s.offset, s.length)
            mstore(0x20, keccak256(m, s.length))
            let v := keccak256(m, add(s.length, 1))
            let n := and(mload(0x20), 0x1ff)
            mstore(0x00, 0)
            for { let i := 0 } lt(i, n) {} {
                mstore(add(m, i), v)
                mstore(0x00, add(1, mload(0x00)))
                i := add(i, and(keccak256(0x00, 0x40), 0x3f))
            }
            mstore(m, n)
            mstore(sub(m, 0x20), 0x20)
            return(sub(m, 0x20), add(n, 0x60))
        }
    }

    uint256 public paid;

    function pay() external payable {
        paid += msg.value;
    }

    function returnsSender() external view returns (address) {
        return msg.sender;
    }

    function multicallBrutalized(bytes[] calldata data) public returns (bytes[] memory results) {
        _brutalizeMemory();
        results = _multicallResultsToBytesArray(_multicall(data));
        _checkMemory();
    }

    function multicallOriginal(bytes[] calldata data)
        public
        payable
        returns (bytes[] memory results)
    {
        unchecked {
            results = new bytes[](data.length);
            for (uint256 i = 0; i < data.length; i++) {
                (bool success, bytes memory result) = address(this).delegatecall(data[i]);
                if (!success) {
                    // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                    if (result.length < 68) revert();
                    /// @solidity memory-safe-assembly
                    assembly {
                        result := add(result, 0x04)
                    }
                    revert(abi.decode(result, (string)));
                }
                results[i] = result;
            }
        }
    }
}
