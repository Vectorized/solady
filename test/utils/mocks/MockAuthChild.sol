// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Auth, Authority} from "solmate/auth/Auth.sol";

contract MockAuthChild is Auth(msg.sender, Authority(address(0))) {
    bool public flag;

    function updateFlag() public virtual requiresAuth {
        flag = true;
    }
}
