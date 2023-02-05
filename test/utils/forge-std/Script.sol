// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./Vm.sol";
import "./console.sol";

abstract contract Script {
    bool public IS_SCRIPT = true;
    address private constant VM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));

    Vm public constant vm = Vm(VM_ADDRESS);
}
