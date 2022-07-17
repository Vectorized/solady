// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibBitmap} from "../../../src/utils/LibBitmap.sol";

contract MockLibBitmap {
    using LibBitmap for LibBitmap.Bitmap;
    LibBitmap.Bitmap bitmap;

    function get(uint256 index) public view returns (bool result) {
        result = bitmap.get(index);
    }

    function set(uint256 index) public {
        bitmap.set(index);
    }

    function unset(uint256 index) public {
        bitmap.unset(index);
    }

    function toggle(uint256 index) public {
        bitmap.toggle(index);
    }

    function setTo(uint256 index, bool shouldSet) public {
        bitmap.setTo(index, shouldSet);
    }
}
