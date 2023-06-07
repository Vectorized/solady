// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "./ERC20.sol";

/// @notice Simple Wrapped Ether implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/WETH.sol)
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when `amount` is deposited from `from`.
    event Deposit(address indexed from, uint256 amount);

    /// @dev Emitted when `amount` is withdrawn to `to`.
    event Withdrawal(address indexed to, uint256 amount);

    /// @dev `keccak256(bytes("Deposit(address,uint256)"))`.
    uint256 private constant _DEPOSIT_EVENT_SIGNATURE =
        0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c;

    /// @dev `keccak256(bytes("Withdrawal(address,uint256)"))`.
    uint256 private constant _WITHDRAWAL_EVENT_SIGNATURE =
        0x7fcf532c15f0a6db0bd6d0e038bea71d30d808c7d98cb3bf7268a95bf5081b65;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    EIP-2612 IMMUTABLES                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    address private immutable _cachedThis;
    uint256 private immutable _cachedChainId;
    bytes32 private immutable _cachedDomainSeparator;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Cache the hashes for cheaper runtime gas costs.
    /// In the case of upgradeable contracts (i.e. proxies),
    /// or if the chain id changes due to a hard fork,
    /// the domain separator will be seamlessly calculated on-the-fly.
    constructor() payable {
        _cachedThis = address(this);
        _cachedChainId = block.chainid;
        _cachedDomainSeparator = ERC20.DOMAIN_SEPARATOR();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERC20 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the name of the token.
    function name() public pure virtual override returns (string memory) {
        return "Wrapped Ether";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public pure virtual override returns (string memory) {
        return "WETH";
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                            WETH                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deposits `amount` ETH of the caller and mints `amount` WETH to the caller.
    ///
    /// Emits a {Deposit} event.
    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the {Deposit} event.
            mstore(0x00, callvalue())
            log2(0x00, 0x20, _DEPOSIT_EVENT_SIGNATURE, caller())
        }
    }

    /// @dev Deposits `amount` ETH of the caller and mints `amount` WETH to the `to`.
    ///
    /// Emits a {Deposit} event.
    function depositTo(address to) public payable virtual {
        _mint(to, msg.value);
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the {Deposit} event.
            mstore(0x00, callvalue())
            log2(0x00, 0x20, _DEPOSIT_EVENT_SIGNATURE, shr(96, shl(96, to)))
        }
    }

    /// @dev Burns `amount` WETH of the caller and sends `amount` ETH to the caller.
    ///
    /// Emits a {Withdrawal} event.
    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the {Withdrawal} event.
            mstore(0x00, amount)
            log2(0x00, 0x20, _WITHDRAWAL_EVENT_SIGNATURE, caller())
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), caller(), amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Burns `amount` WETH of the caller and sends `amount` ETH to the `to`.
    ///
    /// Emits a {Withdrawal} event.
    function withdrawTo(address to, uint256 amount) public virtual {
        _burn(msg.sender, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the {Withdrawal} event.
            mstore(0x00, amount)
            log2(0x00, 0x20, _WITHDRAWAL_EVENT_SIGNATURE, shr(96, shl(96, to)))
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Equivalent to `deposit()`.
    receive() external payable virtual {
        deposit();
    }

    /// @dev Returns the EIP-2612 domains separator.
    function DOMAIN_SEPARATOR() public view virtual override returns (bytes32 result) {
        result = _cachedDomainSeparator;
        if (_cachedDomainSeparatorInvalidated()) {
            result = ERC20.DOMAIN_SEPARATOR();
        }
    }

    /// @dev Returns if the cached EIP-2612 domain separator has been invalidated.
    function _cachedDomainSeparatorInvalidated() private view returns (bool result) {
        uint256 cachedChainId = _cachedChainId;
        address cachedThis = _cachedThis;
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(and(eq(chainid(), cachedChainId), eq(address(), cachedThis)))
        }
    }
}
