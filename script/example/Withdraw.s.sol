// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CompoundUsdcDepositor} from "src/CompoundUsdcDepositor.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

import {CometInterface} from "lib/comet/contracts/CometInterface.sol";

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

        // Before depositing the user must allow the contract to move his funds through the cUSDC contract.
        CometInterface(cUsdcAddress).allow(address(instance), true);

        instance.withdraw(cUsdcWithdrawAmount);

        // Reset permission
        CometInterface(cUsdcAddress).allow(address(instance), false);

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
