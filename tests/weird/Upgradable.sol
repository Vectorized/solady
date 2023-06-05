// Copyright (C) 2020 d-xo
// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.6.12;

import {ERC20} from "./ERC20.sol";

contract Proxy {
    bytes32 constant ADMIN_KEY = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
    bytes32 constant IMPLEMENTATION_KEY = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);

    // --- init ---

    constructor(uint totalSupply) public {

        // Manual give()
        bytes32 slot = ADMIN_KEY;
        address usr = msg.sender;
        assembly { sstore(slot, usr) }

        upgrade(address(new ERC20(totalSupply)));

    }

    // --- auth ---

    modifier auth() { require(msg.sender == owner(), "unauthorised"); _; }

    function owner() public view returns (address usr) {
        bytes32 slot = ADMIN_KEY;
        assembly { usr := sload(slot) }
    }

    function give(address usr) public auth {
        bytes32 slot = ADMIN_KEY;
        assembly { sstore(slot, usr) }
    }

    // --- upgrade ---

    function implementation() public view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_KEY;
        assembly { impl := sload(slot) }
    }

    function upgrade(address impl) public auth {
        bytes32 slot = IMPLEMENTATION_KEY;
        assembly { sstore(slot, impl) }
    }

    // --- proxy ---

    fallback() external payable {
        address impl = implementation();
        (bool success, bytes memory returndata) = impl.delegatecall{gas: gasleft()}(msg.data);
        require(success);
        assembly { return(add(returndata, 0x20), mload(returndata)) }
    }

    receive() external payable { revert("don't send me ETH!"); }
}
