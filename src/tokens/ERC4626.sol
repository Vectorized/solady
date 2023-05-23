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
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    /// @dev Emitted during a withdraw call or redeem call.
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ERC4626 CONSTANTS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev To be overridden to return the address of the underlying asset.
    ///
    /// - MUST be an ERC20 token contract.
    /// - MUST NOT revert.
    function asset() public view virtual returns (address);

    /// @dev To be overridden to return the number of decimals of the underlying asset.
    ///
    /// - MUST NOT revert.
    function _underlyingDecimals() internal view virtual returns (uint8) {
        return 18;
    }

    /// @dev May be overridden to return a non-zero value to mitigate the inflation attack.
    /// See: https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3706
    ///
    /// - MUST NOT revert.
    function _decimalsOffset() internal view virtual returns (uint8) {
        return 0;
    }

    /// @dev Returns the decimals places of the token.
    ///
    /// - MUST NOT revert.
    function decimals() public view virtual override(ERC20) returns (uint8) {
        return _underlyingDecimals() + _decimalsOffset();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERC4626                           */
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
    /// NOTE: This calculation MAY NOT reflect the "per-user" price-per-share, and instead
    /// should reflect the "average-user's" price-per-share, i.e. what the average user should
    /// expect to see when exchanging to and from.
    function convertToShares(uint256 assets) public view virtual returns (uint256 shares) {
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
    /// NOTE: This calculation MAY NOT reflect the "per-user" price-per-share, and instead
    /// should reflect the "average-user's" price-per-share, i.e. what the average user should
    /// expect to see when exchanging to and from.
    function convertToAssets(uint256 shares) public view virtual returns (uint256 assets) {
        assets = FixedPointMathLib.fullMulDiv(
            shares, totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset()
        );
    }

    /// @dev Returns the maximum amount of the underlying asset that can be deposited
    /// into the Vault for the receiver, via a deposit call.
    ///
    /// - MUST return a limited value if receiver is subject to some deposit limit.
    /// - MUST return `2**256-1` if there is no maximum limit.
    /// - MUST NOT revert.
    function maxDeposit(address receiver) public view virtual returns (uint256 maxAssets) {
        receiver; // Silence unused variable warning.
        maxAssets = type(uint256).max;
    }

    /// @dev Returns the maximum amount of the Vault shares that can be minter for the
    /// receiver, via a mint call.
    ///
    /// - MUST return a limited value if receiver is subject to some mint limit.
    /// - MUST return `2**256-1` if there is no maximum limit.
    /// - MUST NOT revert.
    function maxMint(address receiver) public view virtual returns (uint256 maxShares) {
        receiver; // Silence unused variable warning.
        maxShares = type(uint256).max;
    }

    /// @dev Returns the maximum amount of the underlying asset that can be withdrawn
    /// from the owner's balance in the Vault, via a withdraw call.
    ///
    /// - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
    /// - MUST NOT revert.
    function maxWithdraw(address owner) public view virtual returns (uint256 maxAssets) {
        maxAssets = convertToAssets(balanceOf(owner));
    }

    /// @dev Returns the maximum amount of Vault shares that can be redeemed
    /// from the owner's balance in the Vault, via a redeem call.
    ///
    /// - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
    /// - MUST return `balanceOf(owner)` otherwise.
    /// - MUST NOT revert.
    function maxRedeem(address owner) public view virtual returns (uint256 maxShares) {
        maxShares = balanceOf(owner);
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
    /// NOTE: any unfavorable discrepancy between `convertToShares` and `previewDeposit` SHOULD
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
    /// NOTE: any unfavorable discrepancy between `convertToAssets` and `previewMint` SHOULD
    /// be considered slippage in share price or some other type of condition,
    /// meaning the depositor will lose assets by minting.
    function previewMint(uint256 shares) public view virtual returns (uint256 assets) {
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
    /// NOTE: any unfavorable discrepancy between `convertToShares` and `previewWithdraw` SHOULD
    /// be considered slippage in share price or some other type of condition,
    /// meaning the depositor will lose assets by depositing.
    function previewWithdraw(uint256 assets) public view virtual returns (uint256 shares) {
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
    /// NOTE: any unfavorable discrepancy between `convertToAssets` and `previewRedeem` SHOULD
    /// be considered slippage in share price or some other type of condition,
    /// meaning the depositor will lose assets by depositing.
    function previewRedeem(uint256 shares) public view virtual returns (uint256 assets) {
        assets = convertToAssets(shares);
    }

    /// @dev Mints `shares` Vault shares to `receiver` by depositing exactly `assets`
    /// of underlying tokens.
    ///
    /// - MUST emit the {Deposit} event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault
    ///   contract before the deposit execution, and are accounted for during deposit.
    /// - MUST revert if all of `assets` cannot be deposited, such as due to deposit limit,
    ///   slippage, insufficient approval, etc.
    ///
    /// NOTE: most implementations will require pre-approval of the Vault with the
    /// Vault's underlying `asset` token.
    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        if (assets > maxDeposit(receiver)) revert DepositMoreThanMax();
        shares = previewDeposit(assets);
        _deposit(msg.sender, receiver, assets, shares);
    }

    /// @dev Mints exactly `shares` Vault shares to `receiver` by depositing `assets`
    /// of underlying tokens.
    ///
    /// - MUST emit the {Deposit} event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault
    ///   contract before the mint execution, and are accounted for during mint.
    /// - MUST revert if all of `shares` cannot be deposited, such as due to deposit limit,
    ///   slippage, insufficient approval, etc.
    ///
    /// NOTE: most implementations will require pre-approval of the Vault with the
    /// Vault's underlying `asset` token.
    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        if (shares > maxMint(receiver)) revert MintMoreThanMax();
        assets = previewMint(shares);
        _deposit(msg.sender, receiver, assets, shares);
    }

    /// @dev Burns `shares` from `owner` and sends exactly `assets` of
    /// underlying tokens to `receiver`.
    ///
    /// - MUST emit the {Withdraw} event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault
    ///   contract before the withdraw execution, and are accounted for during withdraw.
    /// - MUST revert if all of `assets` cannot be withdrawan, such as due to withdrawal limit,
    ///   slippage, insufficient balance, etc.
    ///
    /// NOTE: some implementations will require pre-requesting to the Vault before a withdrawal
    /// may be performed. Those methods should be performed separately.
    function withdraw(uint256 assets, address receiver, address owner)
        public
        virtual
        returns (uint256 shares)
    {
        if (assets > maxWithdraw(owner)) revert WithdrawMoreThanMax();
        shares = previewWithdraw(assets);
        _withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /// @dev Burns exactly `shares` from `owner` and sends `assets` of underlying tokens
    /// to `receiver`.
    ///
    /// - MUST emit the {Withdraw} event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault
    ///   contract before the redeem execution, and are accounted for during redeem.
    /// - MUST revert if all of shares cannot be redeemed, such as due to withdrawal limit,
    ///   slippage, insufficient balance, etc.
    ///
    /// NOTE: some implementations will require pre-requesting to the Vault before a redeem
    /// may be performed. Those methods should be performed separately.
    function redeem(uint256 shares, address receiver, address owner)
        public
        virtual
        returns (uint256 assets)
    {
        if (shares > maxRedeem(owner)) revert RedeemMoreThanMax();
        assets = previewRedeem(shares);
        _withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev For deposit and mint.
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
        internal
        virtual
    {
        SafeTransferLib.safeTransferFrom(asset(), caller, address(this), assets);
        _mint(receiver, shares);
        emit Deposit(caller, receiver, assets, shares);
        _afterDeposit(assets, shares);
    }

    /// @dev For withdraw and redeem.
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }
        _beforeWithdraw(assets, shares);
        _burn(owner, shares);
        SafeTransferLib.safeTransfer(asset(), receiver, assets);
        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HOOKS TO OVERRIDE                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Hook that is called before any withdraw or redeem.
    function _beforeWithdraw(uint256 assets, uint256 shares) internal virtual;

    /// @dev Hook that is called after any deposit or mint.
    function _afterDeposit(uint256 assets, uint256 shares) internal virtual;
}
