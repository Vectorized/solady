// Copyright (C) 2017, 2018, 2019, 2020 dbrock, rain, mrchico, d-xo
// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.6.12;

/*
    Provides two contracts:

    1. ProxiedToken: The underlying token, state modifications must be made through a proxy
    2. TokenProxy: Proxy contract, appends the original msg.sender to any calldata provided by the user

    The ProxiedToken can have many trusted frontends (TokenProxy's).
    The frontends should append the address of their caller to calldata when calling into the backend.
    Admin users of the ProxiedToken can add new delegators.
*/

contract ProxiedToken {
    // --- ERC20 Data ---
    string  public constant name = "Token";
    string  public constant symbol = "TKN";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    // --- Init ---
    constructor(uint _totalSupply) public {
        admin[msg.sender] = true;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // --- Access Control ---
    mapping(address => bool) public admin;
    function rely(address usr) external auth { admin[usr] = true; }
    function deny(address usr) external auth { admin[usr] = false; }
    modifier auth() { require(admin[msg.sender], "non-admin-call"); _; }

    mapping(address => bool) public delegators;
    modifier delegated() { require(delegators[msg.sender], "non-delegator-call"); _; }
    function setDelegator(address delegator, bool status) external {
        delegators[delegator] = status;
    }

    // --- Token ---
    function transfer(address dst, uint wad) delegated external returns (bool) {
        return _transferFrom(_getCaller(), _getCaller(), dst, wad);
    }
    function transferFrom(address src, address dst, uint wad) delegated external returns (bool) {
        return _transferFrom(_getCaller(), src, dst, wad);
    }
    function approve(address usr, uint wad) delegated external returns (bool) {
        return _approve(_getCaller(), usr, wad);
    }

    // --- Internals ---
    function _transferFrom(
        address caller, address src, address dst, uint wad
    ) internal returns (bool) {
        require(balanceOf[src] >= wad, "insufficient-balance");
        if (src != caller && allowance[src][caller] != type(uint).max) {
            require(allowance[src][caller] >= wad, "insufficient-allowance");
            allowance[src][caller] = sub(allowance[src][caller], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }
    function _approve(address caller, address usr, uint wad) internal returns (bool) {
        allowance[caller][usr] = wad;
        emit Approval(caller, usr, wad);
        return true;
    }
    // grabs the first word after the calldata and masks it with 20bytes of 1's
    // to turn it into an address
    function _getCaller() internal pure returns (address result) {
        bytes memory array = msg.data;
        uint256 index = msg.data.length;
        assembly {
            result := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function mint(address usr, uint wad) external {
        balanceOf[usr] = add(balanceOf[usr], wad);
        totalSupply    = add(totalSupply,    wad);
        emit Transfer(address(0), usr, wad);
    }
}

contract TokenProxy {
    address payable immutable public impl;
    constructor(address _impl) public {
        impl = payable(_impl);
    }

    receive() external payable { revert("don't send me ETH!"); }

    fallback() external payable {
        address _impl = impl; // pull impl onto the stack
        assembly {
            // get free data pointer
            let ptr := mload(0x40)

            // write calldata to ptr
            calldatacopy(ptr, 0, calldatasize())
            // store msg.sender after the calldata
            mstore(add(ptr, calldatasize()), caller())

            // call impl with the contents of ptr as caldata
            let result := call(gas(), _impl, callvalue(), ptr, add(calldatasize(), 32), 0, 0)

            // copy the returndata to ptr
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            // revert if the call failed
            case 0 { revert(ptr, size) }
            // return ptr otherwise
            default { return(ptr, size) }
        }
    }

}
