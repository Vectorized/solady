// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {Base58} from "../src/utils/Base58.sol";
import {LibString} from "../src/utils/LibString.sol";

contract Base58Test is SoladyTest {
    function testBase58Encode() public {
        // 0x000000000000000000001e3c8bf2dd5877fc13a2456ad7a584fe1629499985d685d6bf2e2983334225ec9dec91a445ce4f940fa4e75c3eee0436561dafe334
        bytes memory b =
            hex"00001e3c8bf2dd5877fc13a2456ad7a584fe1629499985d6bf2e2983334225ec9dec91a445ce4f940fa4e75c3eee0436561dafe334ef0886895d9ce60d812a18d92ead188c4e550a9479f9e83765d603c1c0ee6b2142457b3407b2ec756faabb";
        string memory encoded = Base58.encode(b);
        emit LogString(encoded);
    }
}
