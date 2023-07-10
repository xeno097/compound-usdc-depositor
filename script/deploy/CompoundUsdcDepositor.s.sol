// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CompoundUsdcDepositor} from "src/CompoundUsdcDepositor.sol";
import "forge-std/console.sol";

contract DeployCompoundUsdcDepositor is Script {
    function setUp() public {}

    function run() public {
        uint256 priv_key = vm.envUint("PRIV_KEY");
        address cUsdcAddress = vm.envAddress("cUSDC_ADDRESS");
        address usdcAddress = vm.envAddress("USDC_ADDRESS");

        vm.startBroadcast(priv_key);

        CompoundUsdcDepositor instance = new CompoundUsdcDepositor(
            usdcAddress,
            cUsdcAddress
        );

        console.log("CONTRACT DEPLOYED AT:", address(instance));
    }
}
