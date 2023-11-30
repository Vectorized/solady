// Copyright (C) 2020 d-xo
// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.6.12;

import {ERC20} from "./ERC20.sol";

contract ReentrantToken is ERC20 {
    // --- Init ---
    constructor(uint _totalSupply) ERC20(_totalSupply) public {}

    // --- Call Targets ---
    mapping (address => Target) public targets;
    struct Target {
        bytes   data;
        address addr;
    }
    function setTarget(address addr, bytes calldata data) external {
        targets[msg.sender] = Target(data, addr);
    }

    // --- Token ---
    function transferFrom(address src, address dst, uint wad) override public returns (bool res) {
        res = super.transferFrom(src, dst, wad);
        Target memory target = targets[src];
        if (target.addr != address(0)) {
            (bool status,) = target.addr.call{gas: gasleft()}(target.data);
            require(status, "call failed");
        }
    }
}
