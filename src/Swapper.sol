// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

interface ICERC20 is IERC20 {
    function supply(address asset, uint amount) external;

    function redeemUnderlying(uint redeemAmount) external returns (uint);
}

contract Swapper {
    uint256 public number;
    ICERC20 cUSDC;
    IERC20 uSDC;

    constructor(address _usdc, address _cUcdc) {
        uSDC = IERC20(_usdc);
        cUSDC = ICERC20(_cUcdc);
    }

    function deposit(uint256 amount) external {
        uint256 checkApproval = uSDC.allowance(msg.sender, address(this));
        // uint256 initialContractBalance = uSDC.balanceOf(address(this));

        if (checkApproval < amount) {
            revert("User did not approve enough allowance for this contract");
        }

        console.log("USER DID APPROVE SWAPPER");

        bool checkTransfer = uSDC.transferFrom(
            msg.sender,
            address(this),
            amount
        );

        if (!checkTransfer) {
            revert("USDC transfer from User account to Contract failed");
        }

        console.log(
            "RUGGED USER FROM ITS USDC BALANCE",
            uSDC.balanceOf(address(this))
        );

        bool check = uSDC.approve(address(cUSDC), amount);

        if (!check) {
            revert("Failed approval");
        }

        cUSDC.supply(address(uSDC), amount);

        // if (errorCode != 0) {
        //     revert("COMPOUND ERROR WHILE MINTING");
        // }

        checkTransfer = cUSDC.transfer(msg.sender, amount);

        if (!checkTransfer) {
            revert("cUSDC transfer from Contract to User failed");
        }
    }
}
