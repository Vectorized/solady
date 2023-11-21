// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {GasBurnerLib} from "../src/utils/GasBurnerLib.sol";

contract GasBurnerLibTest is SoladyTest {
    event LogGasBurn(uint256 required, uint256 actual);

    function testBurnGas() public {
        _testBurnGas(0);
        _testBurnGas(1);
        _testBurnGas(110);
        _testBurnGas(119);
        _testBurnGas(120);
        _testBurnGas(121);
        _testBurnGas(300);
        for (uint256 x = 300; x < 9000; x += 32) {
            _testBurnGas(x);
        }
    }

    function _testBurnGas(uint256 x) internal {
        unchecked {
            uint256 gasBefore = gasleft();
            GasBurnerLib.burn(x);
            uint256 gasAfter = gasleft();
            emit LogGasBurn(x, gasBefore - gasAfter);
        }
    }
}
