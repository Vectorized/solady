// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC6909} from "../../../src/tokens/ERC6909.sol";
import {LibString} from "../../../src/utils/LibString.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC6909 is ERC6909 {
    error TokenDoesNotExist();

    string name_;
    string symbol_;
    string baseURI_;

    constructor(string memory _name, string memory _symbol, string memory _baseURI) {
        name_ = _name;
        symbol_ = _symbol;
        baseURI_ = _baseURI;
    }

    function name() public view virtual override returns (string memory) {
        return name_;
    }

    function symbol() public view virtual override returns (string memory) {
        return symbol_;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        if (!_exists(id)) revert TokenDoesNotExist();
        return string(abi.encodePacked(baseURI_, LibString.toString(id)));
    }

    function mint(address to, uint256 id, uint256 amount) public virtual {
        _mint(_brutalized(to), id, amount);
    }

    function burn(address from, uint256 id, uint256 amount) public virtual {
        _burn(_brutalized(from), id, amount);
    }

    function approve(address spender, uint256 id, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        return super.approve(_brutalized(spender), id, amount);
    }

    function setOperator(address owner, bool approved) public virtual override returns (bool) {
        return super.setOperator(_brutalized(owner), approved);
    }

    function transfer(address to, uint256 id, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        return super.transfer(_brutalized(to), id, amount);
    }

    function transferFrom(address from, address to, uint256 id, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        return super.transferFrom(_brutalized(from), _brutalized(to), id, amount);
    }

    function _brutalized(address a) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(a, shl(160, gas()))
        }
    }
}

contract MockERC6909CustomDecimals is ERC6909 {
    function name() public view virtual override returns (string memory) {
        return "Solady";
    }

    function symbol() public view virtual override returns (string memory) {
        return "SLY";
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return string(abi.encodePacked("http://solady.org/", LibString.toString(id)));
    }

    function setDecimals(uint256 id, uint8 decimal) public virtual {
        _setDecimals(id, decimal);
    }

    function decimals(uint256 id) public view virtual override returns (uint8) {
        return _getDecimals(id);
    }
}
