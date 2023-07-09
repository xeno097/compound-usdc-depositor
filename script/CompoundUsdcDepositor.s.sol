// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CompoundUsdcDepositor} from "src/CompoundUsdcDepositor.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

import {CometInterface} from "lib/comet/contracts/CometInterface.sol";

contract DeployCompoundUsdcDepositor is Script {
    function setUp() public {}

    function run() public {
        uint256 priv_key = vm.envUint("PRIV_KEY");
        // address deployer_add = vm.addr(priv_key);
        address cUsdcAddress = vm.envAddress("cUSDC_ADDRESS");
        address usdcAddress = vm.envAddress("USDC_ADDRESS");

        vm.startBroadcast(priv_key);

        CompoundUsdcDepositor instance = new CompoundUsdcDepositor(
            usdcAddress,
            cUsdcAddress
        );

        console.log("SWAPPER INSTANCE IS", address(instance));

        // uint256 balance = IERC20(usdcAddress).balanceOf(deployer_add);
        uint256 balance = 10_000000;

        IERC20(usdcAddress).approve(address(instance), balance);

        instance.deposit(balance);
    }
}
