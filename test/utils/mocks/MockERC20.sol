// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "../../../src/tokens/ERC20.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC20 is ERC20 {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 value) public virtual {
        _mint(_brutalized(to), value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(_brutalized(from), value);
    }

    function directTransfer(address from, address to, uint256 amount) public virtual {
        _transfer(_brutalized(from), _brutalized(to), amount);
    }

    function directSpendAllowance(address owner, address spender, uint256 amount) public virtual {
        _spendAllowance(_brutalized(owner), _brutalized(spender), amount);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        return super.transfer(_brutalized(to), amount);
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        return super.transferFrom(_brutalized(from), _brutalized(to), amount);
    }

    function _brutalized(address a) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(a, shl(160, gas()))
        }
    }
}
