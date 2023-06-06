// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

import {ERC2981, MockERC2981} from "./utils/mocks/MockERC2981.sol";

contract ERC2981Test is SoladyTest {
    MockERC2981 token;

    function setUp() public {
        token = new MockERC2981();
    }

    struct _TestTemps {
        uint256 feeDenominator;
        address[2] receivers;
        uint256[2] tokenIds;
        uint256[2] salePrices;
        uint256[2] royaltyFractions;
        address defaultReceiver;
        uint256 defaultRoyaltyFraction;
    }

    function testSetAndGetRoyaltyInfo(uint256) public {
        _TestTemps memory t;
        t.feeDenominator = token.feeDenominator();
        t.tokenIds[0] = _random();
        do {
            t.tokenIds[1] = _random();
        } while (t.tokenIds[0] == t.tokenIds[1]);
        t.receivers[0] = _randomNonZeroAddress();
        do {
            t.receivers[1] = _randomNonZeroAddress();
        } while (t.receivers[0] == t.receivers[1]);
        t.salePrices[0] = _bound(_random(), 0, type(uint160).max);
        t.salePrices[1] = _bound(_random(), 0, type(uint160).max);
        t.defaultReceiver = _randomNonZeroAddress();
        t.defaultRoyaltyFraction = _bound(_random(), 0, t.feeDenominator);
        t.royaltyFractions[0] = _bound(_random(), 0, t.feeDenominator);
        t.royaltyFractions[1] = _bound(_random(), 0, t.feeDenominator);

        _checkRoyaltyInfoIsZero(t);

        vm.expectRevert(ERC2981.RoyaltyReceiverIsZeroAddress.selector);
        token.setDefaultRoyalty(address(0), 1);
        vm.expectRevert(ERC2981.RoyaltyOverflow.selector);
        token.setDefaultRoyalty(t.defaultReceiver, _getInvalidFeeNumerator(t));

        token.setDefaultRoyalty(t.defaultReceiver, uint96(t.defaultRoyaltyFraction));

        for (uint256 i; i < 2; ++i) {
            _checkRoyaltyInfoIsDefault(t, i);
        }

        for (uint256 i; i < 2; ++i) {
            vm.expectRevert(ERC2981.RoyaltyReceiverIsZeroAddress.selector);
            token.setTokenRoyalty(t.tokenIds[i], address(0), 1);
            vm.expectRevert(ERC2981.RoyaltyOverflow.selector);
            token.setTokenRoyalty(t.tokenIds[i], t.receivers[i], _getInvalidFeeNumerator(t));

            token.setTokenRoyalty(t.tokenIds[i], t.receivers[i], uint96(t.royaltyFractions[i]));
        }

        for (uint256 i; i < 2; ++i) {
            _checkRoyaltyInfo(
                t, i, t.receivers[i], t.salePrices[i] * t.royaltyFractions[i] / t.feeDenominator
            );
        }

        for (uint256 i; i < 2; ++i) {
            token.resetTokenRoyalty(t.tokenIds[i]);
            _checkRoyaltyInfoIsDefault(t, i);
        }

        for (uint256 i; i < 2; ++i) {
            _checkRoyaltyInfoIsDefault(t, i);
        }

        token.deleteDefaultRoyalty();

        _checkRoyaltyInfoIsZero(t);
    }

    function _getInvalidFeeNumerator(_TestTemps memory t) internal returns (uint96 r) {
        while (true) {
            r = uint96(_random());
            if (r > t.feeDenominator) return r;
        }
    }

    function _checkRoyaltyInfoIsZero(_TestTemps memory t) internal {
        for (uint256 i; i < 2; ++i) {
            _checkRoyaltyInfo(t, i, address(0), 0);
        }
    }

    function _checkRoyaltyInfoIsDefault(_TestTemps memory t, uint256 i) internal {
        _checkRoyaltyInfo(
            t, i, t.defaultReceiver, t.salePrices[i] * t.defaultRoyaltyFraction / t.feeDenominator
        );
    }

    function _checkRoyaltyInfo(
        _TestTemps memory t,
        uint256 i,
        address expectedReceiver,
        uint256 expectedAmount
    ) internal {
        (address receiver, uint256 amount) = token.royaltyInfo(t.tokenIds[i], t.salePrices[i]);
        assertEq(receiver, expectedReceiver);
        assertEq(amount, expectedAmount);
    }
}
