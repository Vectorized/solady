// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "../../../src/tokens/ERC20.sol";

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
        /// @solidity memory-safe-assembly
        assembly {
            to := or(to, shl(160, not(0)))
        }
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        /// @solidity memory-safe-assembly
        assembly {
            from := or(from, shl(160, not(0)))
        }
        _burn(from, value);
    }

    function directTransfer(address from, address to, uint256 amount) public virtual {
        /// @solidity memory-safe-assembly
        assembly {
            from := or(from, shl(160, not(0)))
            to := or(to, shl(160, not(0)))
        }
        _transfer(from, to, amount);
    }

    function directSpendAllowance(address owner, address spender, uint256 amount) public virtual {
        /// @solidity memory-safe-assembly
        assembly {
            owner := or(owner, shl(160, not(0)))
            spender := or(spender, shl(160, not(0)))
        }
        _spendAllowance(owner, spender, amount);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            to := or(to, shl(160, not(0)))
        }
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        /// @solidity memory-safe-assembly
        assembly {
            from := or(from, shl(160, not(0)))
            to := or(to, shl(160, not(0)))
        }
        return super.transferFrom(from, to, amount);
    }

    function increaseAllowance(address spender, uint256 difference)
        public
        virtual
        override
        returns (bool)
    {
        /// @solidity memory-safe-assembly
        assembly {
            spender := or(spender, shl(160, not(0)))
        }
        return super.increaseAllowance(spender, difference);
    }

    function decreaseAllowance(address spender, uint256 difference)
        public
        virtual
        override
        returns (bool)
    {
        /// @solidity memory-safe-assembly
        assembly {
            spender := or(spender, shl(160, not(0)))
        }
        return super.decreaseAllowance(spender, difference);
    }
}
