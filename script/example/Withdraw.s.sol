// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CompoundUsdcDepositor} from "src/CompoundUsdcDepositor.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract WithdrawExample is Script {
    uint256 privKey;
    address deployerAddress;
    address cUsdcAddress;
    address usdcAddress;
    address depositorAddress;
    uint256 cUsdcWithdrawAmount;

    function setUp() public {
        privKey = vm.envUint("PRIV_KEY");
        deployerAddress = vm.addr(privKey);
        cUsdcAddress = vm.envAddress("cUSDC_ADDRESS");
        usdcAddress = vm.envAddress("USDC_ADDRESS");
        depositorAddress = vm.envAddress("COMPOUND_DEPOSITOR_ADDRESS");
        cUsdcWithdrawAmount = vm.envUint("CUSDC_WITHDRAW_AMOUNT");
    }

    function run() public {
        vm.startBroadcast(privKey);

        CompoundUsdcDepositor instance = CompoundUsdcDepositor(
            depositorAddress
        );

        console.log("BEFORE WITHDRAWAL");

        console.log(
            "CompoundUsdcDepositor USDC balance is:",
            IERC20(usdcAddress).balanceOf(address(instance)),
            "cUSDC balance is:",
            IERC20(cUsdcAddress).balanceOf(address(instance))
        );

        console.log(
            "User USDC balance is:",
            IERC20(usdcAddress).balanceOf(deployerAddress),
            "cUSDC balance is:",
            IERC20(cUsdcAddress).balanceOf(deployerAddress)
        );

        // Before executing the withdrawal the user must approve the CompoundUsdcDepositor instance to move the funds.
        bool ok = IERC20(cUsdcAddress).approve(
            address(instance),
            type(uint256).max
        );

        if (!ok) {
            revert("Approval failed");
        }

        instance.withdraw(cUsdcWithdrawAmount);

        console.log("AFTER WITHDRAWAL");

        console.log(
            "CompoundUsdcDepositor USDC balance is:",
            IERC20(usdcAddress).balanceOf(address(instance)),
            "cUSDC balance is:",
            IERC20(cUsdcAddress).balanceOf(address(instance))
        );

        console.log(
            "User USDC balance is:",
            IERC20(usdcAddress).balanceOf(deployerAddress),
            "cUSDC balance is:",
            IERC20(cUsdcAddress).balanceOf(deployerAddress)
        );
    }
}
