// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20, ERC20Votes} from "../../../src/tokens/ERC20Votes.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC20Votes is ERC20Votes, Brutalizer {
    function name() public view virtual override returns (string memory) {
        return "name";
    }

    function symbol() public view virtual override returns (string memory) {
        return "symbol";
    }

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }

    function directTransfer(address from, address to, uint256 amount) public virtual {
        _transfer(from, to, amount);
    }

    function directSpendAllowance(address owner, address spender, uint256 amount) public virtual {
        _spendAllowance(owner, spender, amount);
    }

    function directDelegate(address delegator, address delegatee) public {
        _delegate(delegator, delegatee);
    }

    function directIncrementNonce(address owner) public {
        _incrementNonce(owner);
    }
}
