// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {GasBurnerLib} from "../src/utils/GasBurnerLib.sol";

contract GasBurnerLibTest is SoladyTest {
    function testBurnGas() public view {
        unchecked {
            GasBurnerLib.burn(0);
            GasBurnerLib.burn(1);
            uint256 gasBefore = gasleft();
            GasBurnerLib.burn(30000000);
            uint256 gasAfter = gasleft();
            console.log(gasBefore - gasAfter);
        }
    }
}
