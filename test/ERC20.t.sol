// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import "./utils/InvariantTest.sol";

import {ERC20, MockERC20} from "./utils/mocks/MockERC20.sol";
import {MockERC20ForPermit2} from "./utils/mocks/MockERC20ForPermit2.sol";

contract ERC20ForPermit2Test is SoladyTest {
    MockERC20ForPermit2 token;

    address internal constant _PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    function setUp() public {
        token = new MockERC20ForPermit2("Token", "TKN", 18);
    }

    function testApproveToPermit2(address owner, uint256 amount) public {
        vm.prank(owner);
        if (amount != type(uint256).max) {
            vm.expectRevert(ERC20.Permit2AllowanceIsFixedAtInfinity.selector);
        }
        token.approve(_PERMIT2, amount);
    }

    function testPermitToPermit2(address owner, uint256 amount) public {
        vm.prank(owner);
        if (amount != type(uint256).max) {
            vm.expectRevert(ERC20.Permit2AllowanceIsFixedAtInfinity.selector);
        } else {
            vm.expectRevert(ERC20.InvalidPermit.selector);
        }
        token.permit(owner, _PERMIT2, amount, block.timestamp, 0, bytes32(0), bytes32(0));
    }

    function testTransferFrom(address owner, uint256 amount) public {
        assertEq(token.allowance(owner, _PERMIT2), type(uint256).max);
        token.mint(owner, amount);
        uint256 amountToTransfer = _bound(_random(), 0, amount);
        address notPermit2 = _randomHashedAddress();
        address recipient = _randomHashedAddress();
        vm.prank(notPermit2);
        if (amountToTransfer != 0) {
            vm.expectRevert(ERC20.InsufficientAllowance.selector);
        }
        token.transferFrom(owner, recipient, amountToTransfer);

        vm.prank(_PERMIT2);
        token.transferFrom(owner, recipient, amountToTransfer);
        if (recipient != owner) {
            assertEq(token.balanceOf(recipient), amountToTransfer);
            assertEq(token.balanceOf(owner), amount - amountToTransfer);
        } else {
            assertEq(token.balanceOf(owner), amount);
        }
        assertEq(token.allowance(owner, _PERMIT2), type(uint256).max);
    }

    function check_IsNotUint256MaxTrickEquivalence(uint256 x) public pure {
        bool expected;
        bool optimized;
        /// @solidity memory-safe-assembly
        assembly {
            if add(x, 1) { expected := 1 }
            if not(x) { optimized := 1 }
        }
        assert(optimized == expected);
        expected = x != type(uint256).max;
        assert(optimized == expected);
    }

    function check_IsPermit2AndValueIsNotInfinityTrickEquivalence(address spender, uint256 amount)
        public
        pure
    {
        bool expected = spender == _PERMIT2 && amount != type(uint256).max;
        bool optimized;
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(or(xor(shr(96, shl(96, spender)), _PERMIT2), iszero(not(amount)))) {
                optimized := 1
            }
        }
        assert(optimized == expected);
    }
}

contract ERC20Test is SoladyTest {
    MockERC20 token;

    address internal constant _PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    bytes32 constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event ApprovalExpiration(address indexed owner, address indexed spender, uint64 expiration);

    uint256 internal constant _MAX_PACKED_ALLOWANCE = uint256(type(uint192).max) - 1;

    struct _TestTemps {
        address owner;
        address to;
        uint256 amount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 privateKey;
        uint256 nonce;
    }

    function _testTemps() internal returns (_TestTemps memory t) {
        (t.owner, t.privateKey) = _randomSigner();
        t.to = _randomNonZeroAddress();
        t.amount = _random();
        t.deadline = _random();
    }

    function setUp() public {
        token = new MockERC20("Token", "TKN", 18);
    }

    function testMetadata() public {
        assertEq(token.name(), "Token");
        assertEq(token.symbol(), "TKN");
        assertEq(token.decimals(), 18);
    }

    function testMint() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), address(0xBEEF), 1e18);
        token.mint(address(0xBEEF), 1e18);

        assertEq(token.totalSupply(), 1e18);
        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function testBurn() public {
        token.mint(address(0xBEEF), 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0xBEEF), address(0), 0.9e18);
        token.burn(address(0xBEEF), 0.9e18);

        assertEq(token.totalSupply(), 1e18 - 0.9e18);
        assertEq(token.balanceOf(address(0xBEEF)), 0.1e18);
    }

    function testApprove() public {
        vm.expectEmit(true, true, true, true);
        emit Approval(address(this), address(0xBEEF), 1e18);
        assertTrue(token.approve(address(0xBEEF), 1e18));

        assertEq(token.allowance(address(this), address(0xBEEF)), 1e18);
        (uint64 expiration, uint256 allowance) =
            token.allowanceAndExpiration(address(this), address(0xBEEF));
        assertEq(expiration, uint64(block.timestamp + token.maxApprovalDuration()));
        assertEq(allowance, 1e18);
    }

    function testApproveForDuration() public {
        vm.warp(1_000_000);
        assertEq(token.maxApprovalDuration(), 1 days);

        vm.expectEmit(true, true, true, true);
        emit Approval(address(this), address(0xBEEF), 100);
        vm.expectEmit(true, true, true, true);
        emit ApprovalExpiration(address(this), address(0xBEEF), uint64(block.timestamp + 3600));
        assertTrue(token.approveForDuration(address(0xBEEF), 100, 3600));

        (uint64 expiration, uint256 allowance) =
            token.allowanceAndExpiration(address(this), address(0xBEEF));
        assertEq(expiration, 1_003_600);
        assertEq(allowance, 100);
        assertEq(token.allowance(address(this), address(0xBEEF)), 100);

        vm.warp(1_003_600);
        assertEq(token.allowance(address(this), address(0xBEEF)), 100);

        vm.warp(1_003_601);
        assertEq(token.allowance(address(this), address(0xBEEF)), 0);
        (expiration, allowance) = token.allowanceAndExpiration(address(this), address(0xBEEF));
        assertEq(expiration, 1_003_600);
        assertEq(allowance, 100);
    }

    function testLegacyCompatibleSpender() public {
        vm.warp(1_000_000);
        address owner = address(0xABCD);
        address spender = address(0xBEEF);
        address recipient = address(0xCAFE);

        token.mint(owner, 100);
        vm.prank(owner);
        token.approveForDuration(spender, 100, 3600);

        vm.warp(1_003_601);
        assertEq(token.allowance(owner, spender), 0);
        (uint64 expiration, uint256 allowance) = token.allowanceAndExpiration(owner, spender);
        assertEq(expiration, 1_003_600);
        assertEq(allowance, 100);

        token.setLegacySpender(spender, true);
        assertEq(token.allowance(owner, spender), 100);
        (expiration, allowance) = token.allowanceAndExpiration(owner, spender);
        assertEq(expiration, uint64(block.timestamp));
        assertEq(allowance, 100);

        vm.prank(spender);
        token.transferFrom(owner, recipient, 40);
        assertEq(token.balanceOf(recipient), 40);
        assertEq(token.allowance(owner, spender), 60);

        token.directSpendAllowance(owner, spender, 10);
        assertEq(token.allowance(owner, spender), 50);

        token.setLegacySpender(spender, false);
        assertEq(token.allowance(owner, spender), 0);
        (expiration, allowance) = token.allowanceAndExpiration(owner, spender);
        assertEq(expiration, 1_003_600);
        assertEq(allowance, 50);

        token.setLegacySpender(spender, true);
        vm.prank(owner);
        token.approve(spender, 0);
        (expiration, allowance) = token.allowanceAndExpiration(owner, spender);
        assertEq(expiration, 0);
        assertEq(allowance, 0);
    }

    function testApproveForDurationRevertsIfTooLong() public {
        vm.expectRevert(ERC20.ApprovalDurationTooLong.selector);
        token.approveForDuration(address(0xBEEF), 100, 1 days + 1);
    }

    function testApproveZeroClearsExpiration() public {
        token.approve(address(0xBEEF), 100);
        token.approve(address(0xBEEF), 0);
        (uint64 expiration, uint256 allowance) =
            token.allowanceAndExpiration(address(this), address(0xBEEF));
        assertEq(expiration, 0);
        assertEq(allowance, 0);
    }

    function testApproveUnsupportedPackedAllowanceReverts() public {
        vm.expectRevert(ERC20.AllowanceOverflow.selector);
        token.approve(address(0xBEEF), type(uint192).max);

        vm.expectRevert(ERC20.AllowanceOverflow.selector);
        token.approve(address(0xBEEF), uint256(type(uint192).max) + 1);
    }

    function testLegacyMaxApprovalSlotReverts() public {
        vm.warp(1_000_000);
        address owner = address(0xABCD);
        address spender = address(this);
        _storeRawAllowance(owner, spender, type(uint256).max);
        token.setLegacySpender(spender, true);

        vm.expectRevert(ERC20.InvalidStoredApproval.selector);
        token.allowance(owner, spender);

        vm.expectRevert(ERC20.InvalidStoredApproval.selector);
        token.allowanceAndExpiration(owner, spender);

        token.mint(owner, 1);
        vm.expectRevert(ERC20.InvalidStoredApproval.selector);
        token.transferFrom(owner, address(0xBEEF), 1);

        vm.expectRevert(ERC20.InvalidStoredApproval.selector);
        token.directSpendAllowance(owner, spender, 1);
    }

    function testMaxApprovalSentinelExpirationBound() public {
        vm.warp(1_000_000);
        address owner = address(0xABCD);
        address spender = address(this);
        uint256 sentinel = uint256(type(uint192).max);

        uint256 maxValidExpiration = block.timestamp + token.maxApprovalDuration();
        _storeRawAllowance(owner, spender, (maxValidExpiration << 192) | sentinel);
        assertEq(token.allowance(owner, spender), type(uint256).max);

        _storeRawAllowance(owner, spender, ((maxValidExpiration + 1) << 192) | 123);
        vm.expectRevert(ERC20.InvalidStoredApproval.selector);
        token.allowance(owner, spender);

        _storeRawAllowance(owner, spender, ((maxValidExpiration + 1) << 192) | sentinel);
        vm.expectRevert(ERC20.InvalidStoredApproval.selector);
        token.allowance(owner, spender);
    }

    function testTransfer() public {
        token.mint(address(this), 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(0xBEEF), 1e18);
        assertTrue(token.transfer(address(0xBEEF), 1e18));
        assertEq(token.totalSupply(), 1e18);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function testTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);

        vm.prank(from);
        token.approve(address(this), 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(from, address(0xBEEF), 1e18);
        assertTrue(token.transferFrom(from, address(0xBEEF), 1e18));
        assertEq(token.totalSupply(), 1e18);

        assertEq(token.allowance(from, address(this)), 0);

        assertEq(token.balanceOf(from), 0);
        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function testInfiniteApproveTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);

        vm.prank(from);
        token.approve(address(this), type(uint256).max);

        assertTrue(token.transferFrom(from, address(0xBEEF), 1e18));
        assertEq(token.totalSupply(), 1e18);

        assertEq(token.allowance(from, address(this)), type(uint256).max);

        assertEq(token.balanceOf(from), 0);
        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function testPermit() public {
        _TestTemps memory t = _testTemps();
        t.amount = _boundValidAllowance(t.amount);
        t.deadline = block.timestamp;

        _signPermit(t);

        _expectPermitEmitApproval(t);
        _permit(t);

        _checkAllowanceAndNonce(t);
    }

    function testMintOverMaxUintReverts() public {
        token.mint(address(this), type(uint256).max);
        vm.expectRevert(ERC20.TotalSupplyOverflow.selector);
        token.mint(address(this), 1);
    }

    function testTransferInsufficientBalanceReverts() public {
        token.mint(address(this), 0.9e18);
        vm.expectRevert(ERC20.InsufficientBalance.selector);
        token.transfer(address(0xBEEF), 1e18);
    }

    function testTransferFromInsufficientAllowanceReverts() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);

        vm.prank(from);
        token.approve(address(this), 0.9e18);

        vm.expectRevert(ERC20.InsufficientAllowance.selector);
        token.transferFrom(from, address(0xBEEF), 1e18);
    }

    function testTransferFromInsufficientBalanceReverts() public {
        address from = address(0xABCD);

        token.mint(from, 0.9e18);

        vm.prank(from);
        token.approve(address(this), 1e18);

        vm.expectRevert(ERC20.InsufficientBalance.selector);
        token.transferFrom(from, address(0xBEEF), 1e18);
    }

    function testMint(address to, uint256 amount) public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), to, amount);
        token.mint(to, amount);

        assertEq(token.totalSupply(), amount);
        assertEq(token.balanceOf(to), amount);
    }

    function testBurn(address from, uint256 mintAmount, uint256 burnAmount) public {
        burnAmount = _bound(burnAmount, 0, mintAmount);

        token.mint(from, mintAmount);
        vm.expectEmit(true, true, true, true);
        emit Transfer(from, address(0), burnAmount);
        token.burn(from, burnAmount);

        assertEq(token.totalSupply(), mintAmount - burnAmount);
        assertEq(token.balanceOf(from), mintAmount - burnAmount);
    }

    function testApprove(address to, uint256 amount) public {
        if (to == _PERMIT2) {
            amount = type(uint256).max;
        } else {
            amount = _boundValidAllowance(amount);
        }
        assertTrue(token.approve(to, amount));
        assertEq(token.allowance(address(this), to), amount);
    }

    function testTransfer(address to, uint256 amount) public {
        token.mint(address(this), amount);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), to, amount);
        assertTrue(token.transfer(to, amount));
        assertEq(token.totalSupply(), amount);

        if (address(this) == to) {
            assertEq(token.balanceOf(address(this)), amount);
        } else {
            assertEq(token.balanceOf(address(this)), 0);
            assertEq(token.balanceOf(to), amount);
        }
    }

    function testTransferFrom(
        address spender,
        address from,
        address to,
        uint256 approval,
        uint256 amount
    ) public {
        vm.assume(spender != _PERMIT2);
        approval = _boundValidAllowance(approval);
        amount = _bound(amount, 0, approval);

        token.mint(from, amount);
        assertEq(token.balanceOf(from), amount);

        vm.prank(from);
        token.approve(spender, approval);

        vm.expectEmit(true, true, true, true);
        emit Transfer(from, to, amount);
        vm.prank(spender);
        assertTrue(token.transferFrom(from, to, amount));
        assertEq(token.totalSupply(), amount);

        if (approval == type(uint256).max) {
            assertEq(token.allowance(from, spender), approval);
        } else {
            assertEq(token.allowance(from, spender), approval - amount);
        }

        if (from == to) {
            assertEq(token.balanceOf(from), amount);
        } else {
            assertEq(token.balanceOf(from), 0);
            assertEq(token.balanceOf(to), amount);
        }
    }

    function testDirectTransfer(uint256) public {
        _TestTemps memory t = _testTemps();
        while (t.owner == t.to) (t.to,) = _randomSigner();

        uint256 totalSupply = _random();
        token.mint(t.owner, totalSupply);
        assertEq(token.balanceOf(t.owner), totalSupply);
        assertEq(token.balanceOf(t.to), 0);
        if (t.amount > totalSupply) {
            vm.expectRevert(ERC20.InsufficientBalance.selector);
            token.directTransfer(t.owner, t.to, t.amount);
        } else {
            vm.expectEmit(true, true, true, true);
            emit Transfer(t.owner, t.to, t.amount);
            token.directTransfer(t.owner, t.to, t.amount);
            assertEq(token.balanceOf(t.owner), totalSupply - t.amount);
            assertEq(token.balanceOf(t.to), t.amount);
        }
    }

    function testDirectSpendAllowance(uint256) public {
        _TestTemps memory t = _testTemps();
        uint256 allowance = _boundValidAllowance(_random());
        vm.prank(t.owner);
        token.approve(t.to, allowance);
        assertEq(token.allowance(t.owner, t.to), allowance);
        if (allowance == type(uint256).max) {
            token.directSpendAllowance(t.owner, t.to, t.amount);
            assertEq(token.allowance(t.owner, t.to), allowance);
        } else if (t.amount > allowance) {
            vm.expectRevert(ERC20.InsufficientAllowance.selector);
            token.directSpendAllowance(t.owner, t.to, t.amount);
        } else {
            token.directSpendAllowance(t.owner, t.to, t.amount);
            assertEq(token.allowance(t.owner, t.to), allowance - t.amount);
        }
    }

    function testPermit(uint256) public {
        _TestTemps memory t = _testTemps();
        t.amount = _boundValidAllowance(t.amount);
        if (t.deadline < block.timestamp) t.deadline = block.timestamp;

        _signPermit(t);

        _expectPermitEmitApproval(t);
        _permit(t);

        _checkAllowanceAndNonce(t);
    }

    function _checkAllowanceAndNonce(_TestTemps memory t) internal {
        assertEq(token.allowance(t.owner, t.to), t.amount);
        (uint64 expiration, uint256 allowance) = token.allowanceAndExpiration(t.owner, t.to);
        assertEq(expiration, _expectedDefaultExpiration(t.amount));
        assertEq(allowance, t.amount);
        assertEq(token.nonces(t.owner), t.nonce + 1);
    }

    function testBurnInsufficientBalanceReverts(address to, uint256 mintAmount, uint256 burnAmount)
        public
    {
        if (mintAmount == type(uint256).max) mintAmount--;
        burnAmount = _bound(burnAmount, mintAmount + 1, type(uint256).max);

        token.mint(to, mintAmount);
        vm.expectRevert(ERC20.InsufficientBalance.selector);
        token.burn(to, burnAmount);
    }

    function testTransferInsufficientBalanceReverts(
        address to,
        uint256 mintAmount,
        uint256 sendAmount
    ) public {
        if (mintAmount == type(uint256).max) mintAmount--;
        sendAmount = _bound(sendAmount, mintAmount + 1, type(uint256).max);

        token.mint(address(this), mintAmount);
        vm.expectRevert(ERC20.InsufficientBalance.selector);
        token.transfer(to, sendAmount);
    }

    function testTransferFromInsufficientAllowanceReverts(
        address to,
        uint256 approval,
        uint256 amount
    ) public {
        if (approval == type(uint256).max) approval--;
        approval = _bound(approval, 0, _MAX_PACKED_ALLOWANCE - 1);
        amount = _bound(amount, approval + 1, _MAX_PACKED_ALLOWANCE);

        address from = address(0xABCD);

        token.mint(from, amount);

        vm.prank(from);
        token.approve(address(this), approval);

        vm.expectRevert(ERC20.InsufficientAllowance.selector);
        token.transferFrom(from, to, amount);
    }

    function testTransferFromInsufficientBalanceReverts(
        address to,
        uint256 mintAmount,
        uint256 sendAmount
    ) public {
        sendAmount = _bound(sendAmount, 1, _MAX_PACKED_ALLOWANCE);
        mintAmount = _bound(mintAmount, 0, sendAmount - 1);

        address from = address(0xABCD);

        token.mint(from, mintAmount);

        vm.prank(from);
        token.approve(address(this), sendAmount);

        vm.expectRevert(ERC20.InsufficientBalance.selector);
        token.transferFrom(from, to, sendAmount);
    }

    function testPermitBadNonceReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        if (t.deadline < block.timestamp) t.deadline = block.timestamp;
        while (t.nonce == 0) t.nonce = _random();

        _signPermit(t);

        vm.expectRevert(ERC20.InvalidPermit.selector);
        _permit(t);
    }

    function testPermitBadDeadlineReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        if (t.deadline == type(uint256).max) t.deadline--;
        if (t.deadline < block.timestamp) t.deadline = block.timestamp;

        _signPermit(t);

        vm.expectRevert(ERC20.InvalidPermit.selector);
        t.deadline += 1;
        _permit(t);
    }

    function testPermitPastDeadlineReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        t.deadline = _bound(t.deadline, 0, block.timestamp - 1);

        _signPermit(t);

        vm.expectRevert(ERC20.PermitExpired.selector);
        _permit(t);
    }

    function testPermitReplayReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        t.amount = _boundValidAllowance(t.amount);
        if (t.deadline < block.timestamp) t.deadline = block.timestamp;

        _signPermit(t);

        _expectPermitEmitApproval(t);
        _permit(t);
        vm.expectRevert(ERC20.InvalidPermit.selector);
        _permit(t);
    }

    function _signPermit(_TestTemps memory t) internal view {
        bytes32 innerHash =
            keccak256(abi.encode(PERMIT_TYPEHASH, t.owner, t.to, t.amount, t.nonce, t.deadline));
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 outerHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, innerHash));
        (t.v, t.r, t.s) = vm.sign(t.privateKey, outerHash);
    }

    function _expectPermitEmitApproval(_TestTemps memory t) internal {
        vm.expectEmit(true, true, true, true);
        emit Approval(t.owner, t.to, t.amount);
        vm.expectEmit(true, true, true, true);
        emit ApprovalExpiration(t.owner, t.to, _expectedDefaultExpiration(t.amount));
    }

    function _boundValidAllowance(uint256 amount) internal pure returns (uint256) {
        if (amount == type(uint256).max) return amount;
        return amount % uint256(type(uint192).max);
    }

    function _storeRawAllowance(address owner, address spender, uint256 packed) internal {
        bytes32 allowanceSlot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, spender)
            mstore(0x0c, 0x7f5e9f20)
            mstore(0x00, owner)
            allowanceSlot := keccak256(0x0c, 0x34)
        }
        vm.store(address(token), allowanceSlot, bytes32(packed));
    }

    function _expectedDefaultExpiration(uint256 amount) internal view returns (uint64) {
        if (amount == 0) return 0;
        return uint64(block.timestamp + token.maxApprovalDuration());
    }

    function _permit(_TestTemps memory t) internal {
        address token_ = address(token);
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(sub(t, 0x20))
            mstore(sub(t, 0x20), 0xd505accf)
            let success := call(gas(), token_, 0, sub(t, 0x04), 0xe4, 0x00, 0x00)
            if iszero(success) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
            mstore(sub(t, 0x20), m)
        }
    }
}

contract ERC20Invariants is SoladyTest, InvariantTest {
    BalanceSum balanceSum;
    MockERC20 token;

    function setUp() public {
        token = new MockERC20("Token", "TKN", 18);
        balanceSum = new BalanceSum(token);
        _addTargetContract(address(balanceSum));
    }

    function invariantBalanceSum() public {
        assertEq(token.totalSupply(), balanceSum.sum());
    }
}

contract BalanceSum {
    MockERC20 token;
    uint256 public sum;

    constructor(MockERC20 _token) {
        token = _token;
    }

    function mint(address from, uint256 amount) public {
        token.mint(from, amount);
        sum += amount;
    }

    function burn(address from, uint256 amount) public {
        token.burn(from, amount);
        sum -= amount;
    }

    function approve(address to, uint256 amount) public {
        token.approve(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public {
        token.transferFrom(from, to, amount);
    }

    function transfer(address to, uint256 amount) public {
        token.transfer(to, amount);
    }
}
