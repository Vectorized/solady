// Copyright (C) 2017, 2018, 2019, 2020 dbrock, rain, mrchico, d-xo
// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.6.12;

contract Uint96ERC20 {
    // --- ERC20 Data ---
    string  public constant name = "Token";
    string  public constant symbol = "TKN";
    uint8   public decimals = 18;
    uint96  internal supply;

    mapping (address => uint96)                      internal balances;
    mapping (address => mapping (address => uint96)) internal allowances;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    // --- Math ---
    function add(uint96 x, uint96 y) internal pure returns (uint96 z) {
        require((z = x + y) >= x);
    }
    function sub(uint96 x, uint96 y) internal pure returns (uint96 z) {
        require((z = x - y) <= x);
    }
    function safe96(uint256 n) internal pure returns (uint96) {
        require(n < 2**96);
        return uint96(n);
    }

    // --- Init ---
    constructor(uint96 _supply) public {
        supply = _supply;
        balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    // --- Getters ---
    function totalSupply() external view returns (uint) {
        return supply;
    }
    function balanceOf(address usr) external view returns (uint) {
        return balances[usr];
    }
    function allowance(address src, address dst) external view returns (uint) {
        return allowances[src][dst];
    }

    // --- Token ---
    function transfer(address dst, uint wad) virtual public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    function transferFrom(address src, address dst, uint wad) virtual public returns (bool) {
        uint96 amt = safe96(wad);

        if (src != msg.sender && allowances[src][msg.sender] != type(uint96).max) {
            allowances[src][msg.sender] = sub(allowances[src][msg.sender], amt);
        }

        balances[src] = sub(balances[src], amt);
        balances[dst] = add(balances[dst], amt);
        emit Transfer(src, dst, wad);
        return true;
    }
    function approve(address usr, uint wad) virtual public returns (bool) {
        uint96 amt;
        if (wad == type(uint).max) {
            amt = type(uint96).max;
        } else {
            amt = safe96(wad);
        }

        allowances[msg.sender][usr] = amt;

        emit Approval(msg.sender, usr, amt);
        return true;
    }

    function mint(address usr, uint wad) virtual public {
        uint96 amt = safe96(wad);

        balances[usr] = add(balances[usr], amt);
        supply        = add(supply, amt);

        emit Transfer(address(0), usr, wad);
    }
}
