// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "./ERC20.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Simple ERC4626 tokenized Vault implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC4626.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The default underlying decimals.
    uint8 internal constant _DEFAULT_UNDERLYING_DECIMALS = 18;

    /// @dev The default decimals offset.
    uint8 internal constant _DEFAULT_DECIMALS_OFFSET = 0;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Cannot deposit more than the max limit.
    error DepositMoreThanMax();

    /// @dev Cannot mint more than the max limit.
    error MintMoreThanMax();

    /// @dev Cannot withdraw more than the max limit.
    error WithdrawMoreThanMax();

    /// @dev Cannot redeem more than the max limit.
    error RedeemMoreThanMax();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted during a mint call or deposit call.
    event Deposit(address indexed by, address indexed owner, uint256 assets, uint256 shares);

    /// @dev Emitted during a withdraw call or redeem call.
    event Withdraw(
        address indexed by,
        address indexed to,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /// @dev `keccak256(bytes("Deposit(address,address,uint256,uint256)"))`.
    uint256 private constant _DEPOSIT_EVENT_SIGNATURE =
        0xdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d7;

    /// @dev `keccak256(bytes("Withdraw(address,address,address,uint256,uint256)"))`.
    uint256 private constant _WITHDRAW_EVENT_SIGNATURE =
        0xfbde797d201c681b91056529119e0b02407c7bb96a4a2c75c01fc9667232c8db;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ERC4626 CONSTANTS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev To be overridden to return the address of the underlying asset.
    ///
    /// - MUST be an ERC20 token contract.
    /// - MUST NOT revert.
    function asset() public view virtual returns (address);

    /// @dev To be overridden to return the number of decimals of the underlying asset.
    /// Default: 18.
    ///
    /// - MUST NOT revert.
    function _underlyingDecimals() internal view virtual returns (uint8) {
        return _DEFAULT_UNDERLYING_DECIMALS;
    }

    /// @dev Override to return a non-zero value to make the inflation attack even more unfeasible.
    /// Only used when {_useVirtualShares} returns true.
    /// Default: 0.
    ///
    /// - MUST NOT revert.
    function _decimalsOffset() internal view virtual returns (uint8) {
        return _DEFAULT_DECIMALS_OFFSET;
    }

    /// @dev Returns whether virtual shares will be used to mitigate the inflation attack.
    /// See: https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3706
    /// Override to return true or false.
    /// Default: true.
    ///
    /// - MUST NOT revert.
    function _useVirtualShares() internal view virtual returns (bool) {
        return true;
    }

    /// @dev Returns the decimals places of the token.
    ///
    /// - MUST NOT revert.
    function decimals() public view virtual override(ERC20) returns (uint8) {
        if (!_useVirtualShares()) return _underlyingDecimals();
        return _underlyingDecimals() + _decimalsOffset();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                ASSET DECIMALS GETTER HELPER                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Helper function to get the decimals of the underlying asset.
    /// Useful for setting the return value of `_underlyingDecimals` during initialization.
    /// If the retrieval succeeds, `success` will be true, and `result` will hold the result.
    /// Otherwise, `success` will be false, and `result` will be zero.
    ///
    /// Example usage:
    /// ```
    /// (bool success, uint8 result) = _tryGetAssetDecimals(underlying);
    /// _decimals = success ? result : _DEFAULT_UNDERLYING_DECIMALS;
    /// ```
    function _tryGetAssetDecimals(address underlying)
        internal
        view
        returns (bool success, uint8 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the function selector of `decimals()`.
            mstore(0x00, 0x313ce567)
            // Arguments are evaluated last to first.
            success :=
                and(
                    // Returned value is less than 256, at left-padded to 32 bytes.
                    and(lt(mload(0x00), 0x100), gt(returndatasize(), 0x1f)),
                    // The staticcall succeeds.
                    staticcall(gas(), underlying, 0x1c, 0x04, 0x00, 0x20)
                )
            result := mul(mload(0x00), success)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ACCOUNTING LOGIC                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the total amount of the underlying asset managed by the Vault.
    ///
    /// - SHOULD include any compounding that occurs from the yield.
    /// - MUST be inclusive of any fees that are charged against assets in the Vault.
    /// - MUST NOT revert.
    function totalAssets() public view virtual returns (uint256 assets) {
        assets = SafeTransferLib.balanceOf(asset(), address(this));
    }

    /// @dev Returns the amount of shares that the Vault will exchange for the amount of
    /// assets provided, in an ideal scenario where all conditions are met.
    ///
    /// - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
    /// - MUST NOT show any variations depending on the caller.
    /// - MUST NOT reflect slippage or other on-chain conditions, during the actual exchange.
    /// - MUST NOT revert.
    ///
    /// Note: This calculation MAY NOT reflect the "per-user" price-per-share, and instead
    /// should reflect the "average-user's" price-per-share, i.e. what the average user should
    /// expect to see when exchanging to and from.
    function convertToShares(uint256 assets) public view virtual returns (uint256 shares) {
        if (!_useVirtualShares()) {
            uint256 supply = totalSupply();
            return _eitherIsZero(assets, supply)
                ? _initialConvertToShares(assets)
                : FixedPointMathLib.fullMulDiv(assets, supply, totalAssets());
        }
        shares = FixedPointMathLib.fullMulDiv(
            assets, totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1
        );
    }

    /// @dev Returns the amount of assets that the Vault will exchange for the amount of
    /// shares provided, in an ideal scenario where all conditions are met.
    ///
    /// - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
    /// - MUST NOT show any variations depending on the caller.
    /// - MUST NOT reflect slippage or other on-chain conditions, during the actual exchange.
    /// - MUST NOT revert.
    ///
    /// Note: This calculation MAY NOT reflect the "per-user" price-per-share, and instead
    /// should reflect the "average-user's" price-per-share, i.e. what the average user should
    /// expect to see when exchanging to and from.
    function convertToAssets(uint256 shares) public view virtual returns (uint256 assets) {
        if (!_useVirtualShares()) {
            uint256 supply = totalSupply();
            return supply == 0
                ? _initialConvertToAssets(shares)
                : FixedPointMathLib.fullMulDiv(shares, totalAssets(), supply);
        }
        assets = FixedPointMathLib.fullMulDiv(
            shares, totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset()
        );
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their deposit
    /// at the current block, given current on-chain conditions.
    ///
    /// - MUST return as close to and no more than the exact amount of Vault shares that
    ///   will be minted in a deposit call in the same transaction, i.e. deposit should
    ///   return the same or more shares as `previewDeposit` if call in the same transaction.
    /// - MUST NOT account for deposit limits like those returned from `maxDeposit` and should
    ///   always act as if the deposit will be accepted, regardless of approvals, etc.
    /// - MUST be inclusive of deposit fees. Integrators should be aware of this.
    /// - MUST not revert.
    ///
    /// Note: Any unfavorable discrepancy between `convertToShares` and `previewDeposit` SHOULD
    /// be considered slippage in share price or some other type of condition, meaning
    /// the depositor will lose assets by depositing.
    function previewDeposit(uint256 assets) public view virtual returns (uint256 shares) {
        shares = convertToShares(assets);
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their mint
    /// at the current block, given current on-chain conditions.
    ///
    /// - MUST return as close to and no fewer than the exact amount of assets that
    ///   will be deposited in a mint call in the same transaction, i.e. mint should
    ///   return the same or fewer assets as `previewMint` if called in the same transaction.
    /// - MUST NOT account for mint limits like those returned from `maxMint` and should
    ///   always act as if the mint will be accepted, regardless of approvals, etc.
    /// - MUST be inclusive of deposit fees. Integrators should be aware of this.
    /// - MUST not revert.
    ///
    /// Note: Any unfavorable discrepancy between `convertToAssets` and `previewMint` SHOULD
    /// be considered slippage in share price or some other type of condition,
    /// meaning the depositor will lose assets by minting.
    function previewMint(uint256 shares) public view virtual returns (uint256 assets) {
        if (!_useVirtualShares()) {
            uint256 supply = totalSupply();
            return supply == 0
                ? _initialConvertToAssets(shares)
                : FixedPointMathLib.fullMulDivUp(shares, totalAssets(), supply);
        }
        assets = FixedPointMathLib.fullMulDivUp(
            shares, totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset()
        );
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal
    /// at the current block, given the current on-chain conditions.
    ///
    /// - MUST return as close to and no fewer than the exact amount of Vault shares that
    ///   will be burned in a withdraw call in the same transaction, i.e. withdraw should
    ///   return the same or fewer shares as `previewWithdraw` if call in the same transaction.
    /// - MUST NOT account for withdrawal limits like those returned from `maxWithdraw` and should
    ///   always act as if the withdrawal will be accepted, regardless of share balance, etc.
    /// - MUST be inclusive of withdrawal fees. Integrators should be aware of this.
    /// - MUST not revert.
    ///
    /// Note: Any unfavorable discrepancy between `convertToShares` and `previewWithdraw` SHOULD
    /// be considered slippage in share price or some other type of condition,
    /// meaning the depositor will lose assets by depositing.
    function previewWithdraw(uint256 assets) public view virtual returns (uint256 shares) {
        if (!_useVirtualShares()) {
            uint256 supply = totalSupply();
            return _eitherIsZero(assets, supply)
                ? _initialConvertToShares(assets)
                : FixedPointMathLib.fullMulDivUp(assets, supply, totalAssets());
        }
        shares = FixedPointMathLib.fullMulDivUp(
            assets, totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1
        );
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their redemption
    /// at the current block, given current on-chain conditions.
    ///
    /// - MUST return as close to and no more than the exact amount of assets that
    ///   will be withdrawn in a redeem call in the same transaction, i.e. redeem should
    ///   return the same or more assets as `previewRedeem` if called in the same transaction.
    /// - MUST NOT account for redemption limits like those returned from `maxRedeem` and should
    ///   always act as if the redemption will be accepted, regardless of approvals, etc.
    /// - MUST be inclusive of withdrawal fees. Integrators should be aware of this.
    /// - MUST NOT revert.
    ///
    /// Note: Any unfavorable discrepancy between `convertToAssets` and `previewRedeem` SHOULD
    /// be considered slippage in share price or some other type of condition,
    /// meaning the depositor will lose assets by depositing.
    function previewRedeem(uint256 shares) public view virtual returns (uint256 assets) {
        assets = convertToAssets(shares);
    }

    /// @dev Private helper to return if either value is zero.
    function _eitherIsZero(uint256 a, uint256 b) private pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(iszero(a), iszero(b))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              DEPOSIT / WITHDRAWAL LIMIT LOGIC              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the maximum amount of the underlying asset that can be deposited
    /// into the Vault for `to`, via a deposit call.
    ///
    /// - MUST return a limited value if `to` is subject to some deposit limit.
    /// - MUST return `2**256-1` if there is no maximum limit.
    /// - MUST NOT revert.
    function maxDeposit(address to) public view virtual returns (uint256 maxAssets) {
        to = to; // Silence unused variable warning.
        maxAssets = type(uint256).max;
    }

    /// @dev Returns the maximum amount of the Vault shares that can be minter for `to`,
    /// via a mint call.
    ///
    /// - MUST return a limited value if `to` is subject to some mint limit.
    /// - MUST return `2**256-1` if there is no maximum limit.
    /// - MUST NOT revert.
    function maxMint(address to) public view virtual returns (uint256 maxShares) {
        to = to; // Silence unused variable warning.
        maxShares = type(uint256).max;
    }

    /// @dev Returns the maximum amount of the underlying asset that can be withdrawn
    /// from the `owner`'s balance in the Vault, via a withdraw call.
    ///
    /// - MUST return a limited value if `owner` is subject to some withdrawal limit or timelock.
    /// - MUST NOT revert.
    function maxWithdraw(address owner) public view virtual returns (uint256 maxAssets) {
        maxAssets = convertToAssets(balanceOf(owner));
    }

    /// @dev Returns the maximum amount of Vault shares that can be redeemed
    /// from the `owner`'s balance in the Vault, via a redeem call.
    ///
    /// - MUST return a limited value if `owner` is subject to some withdrawal limit or timelock.
    /// - MUST return `balanceOf(owner)` otherwise.
    /// - MUST NOT revert.
    function maxRedeem(address owner) public view virtual returns (uint256 maxShares) {
        maxShares = balanceOf(owner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 DEPOSIT / WITHDRAWAL LOGIC                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Mints `shares` Vault shares to `to` by depositing exactly `assets`
    /// of underlying tokens.
    ///
    /// - MUST emit the {Deposit} event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault
    ///   contract before the deposit execution, and are accounted for during deposit.
    /// - MUST revert if all of `assets` cannot be deposited, such as due to deposit limit,
    ///   slippage, insufficient approval, etc.
    ///
    /// Note: Most implementations will require pre-approval of the Vault with the
    /// Vault's underlying `asset` token.
    function deposit(uint256 assets, address to) public virtual returns (uint256 shares) {
        if (assets > maxDeposit(to)) _revert(0xb3c61a83); // `DepositMoreThanMax()`.
        shares = previewDeposit(assets);
        _deposit(msg.sender, to, assets, shares);
    }

    /// @dev Mints exactly `shares` Vault shares to `to` by depositing `assets`
    /// of underlying tokens.
    ///
    /// - MUST emit the {Deposit} event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault
    ///   contract before the mint execution, and are accounted for during mint.
    /// - MUST revert if all of `shares` cannot be deposited, such as due to deposit limit,
    ///   slippage, insufficient approval, etc.
    ///
    /// Note: Most implementations will require pre-approval of the Vault with the
    /// Vault's underlying `asset` token.
    function mint(uint256 shares, address to) public virtual returns (uint256 assets) {
        if (shares > maxMint(to)) _revert(0x6a695959); // `MintMoreThanMax()`.
        assets = previewMint(shares);
        _deposit(msg.sender, to, assets, shares);
    }

    /// @dev Burns `shares` from `owner` and sends exactly `assets` of underlying tokens to `to`.
    ///
    /// - MUST emit the {Withdraw} event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault
    ///   contract before the withdraw execution, and are accounted for during withdraw.
    /// - MUST revert if all of `assets` cannot be withdrawn, such as due to withdrawal limit,
    ///   slippage, insufficient balance, etc.
    ///
    /// Note: Some implementations will require pre-requesting to the Vault before a withdrawal
    /// may be performed. Those methods should be performed separately.
    function withdraw(uint256 assets, address to, address owner)
        public
        virtual
        returns (uint256 shares)
    {
        if (assets > maxWithdraw(owner)) _revert(0x936941fc); // `WithdrawMoreThanMax()`.
        shares = previewWithdraw(assets);
        _withdraw(msg.sender, to, owner, assets, shares);
    }

    /// @dev Burns exactly `shares` from `owner` and sends `assets` of underlying tokens to `to`.
    ///
    /// - MUST emit the {Withdraw} event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault
    ///   contract before the redeem execution, and are accounted for during redeem.
    /// - MUST revert if all of shares cannot be redeemed, such as due to withdrawal limit,
    ///   slippage, insufficient balance, etc.
    ///
    /// Note: Some implementations will require pre-requesting to the Vault before a redeem
    /// may be performed. Those methods should be performed separately.
    function redeem(uint256 shares, address to, address owner)
        public
        virtual
        returns (uint256 assets)
    {
        if (shares > maxRedeem(owner)) _revert(0x4656425a); // `RedeemMoreThanMax()`.
        assets = previewRedeem(shares);
        _withdraw(msg.sender, to, owner, assets, shares);
    }

    /// @dev Internal helper for reverting efficiently.
    function _revert(uint256 s) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, s)
            revert(0x1c, 0x04)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INTERNAL HELPERS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev For deposits and mints.
    ///
    /// Emits a {Deposit} event.
    function _deposit(address by, address to, uint256 assets, uint256 shares) internal virtual {
        SafeTransferLib.safeTransferFrom(asset(), by, address(this), assets);
        _mint(to, shares);
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the {Deposit} event.
            mstore(0x00, assets)
            mstore(0x20, shares)
            let m := shr(96, not(0))
            log3(0x00, 0x40, _DEPOSIT_EVENT_SIGNATURE, and(m, by), and(m, to))
        }
        _afterDeposit(assets, shares);
    }

    /// @dev For withdrawals and redemptions.
    ///
    /// Emits a {Withdraw} event.
    function _withdraw(address by, address to, address owner, uint256 assets, uint256 shares)
        internal
        virtual
    {
        if (by != owner) _spendAllowance(owner, by, shares);
        _beforeWithdraw(assets, shares);
        _burn(owner, shares);
        SafeTransferLib.safeTransfer(asset(), to, assets);
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the {Withdraw} event.
            mstore(0x00, assets)
            mstore(0x20, shares)
            let m := shr(96, not(0))
            log4(0x00, 0x40, _WITHDRAW_EVENT_SIGNATURE, and(m, by), and(m, to), and(m, owner))
        }
    }

    /// @dev Internal conversion function (from assets to shares) to apply when the Vault is empty.
    /// Only used when {_useVirtualShares} returns false.
    ///
    /// Note: Make sure to keep this function consistent with {_initialConvertToAssets}
    /// when overriding it.
    function _initialConvertToShares(uint256 assets)
        internal
        view
        virtual
        returns (uint256 shares)
    {
        shares = assets;
    }

    /// @dev Internal conversion function (from shares to assets) to apply when the Vault is empty.
    /// Only used when {_useVirtualShares} returns false.
    ///
    /// Note: Make sure to keep this function consistent with {_initialConvertToShares}
    /// when overriding it.
    function _initialConvertToAssets(uint256 shares)
        internal
        view
        virtual
        returns (uint256 assets)
    {
        assets = shares;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HOOKS TO OVERRIDE                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Hook that is called before any withdrawal or redemption.
    function _beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    /// @dev Hook that is called after any deposit or mint.
    function _afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}
