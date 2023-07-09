// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20Mock} from "./ERC20Mock.sol";
import {CometInterface} from "lib/comet/contracts/CometInterface.sol";

contract CTokenMock is ERC20Mock {
    function supply(address, uint256) external {
        _maybeUpdateBalance();
    }
}
