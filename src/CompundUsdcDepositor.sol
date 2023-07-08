// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {CometInterface} from "lib/comet/contracts/CometInterface.sol";
import "forge-std/console.sol";
import {Errors} from "src/libs/Errors.sol";

contract CompundUsdcDepositor {
    uint256 public number;
    CometInterface cUSDC;
    IERC20 uSDC;

    constructor(address _usdc, address _cUcdc) {
        uSDC = IERC20(_usdc);
        cUSDC = CometInterface(_cUcdc);
    }

    /// Allows `msg.sender` to deposit `amount` of tokens into the compound protocol and receive cTokens in exchange.
    ///
    /// @param amount The amount of tokens to be deposited into the compound protocol.
    function deposit(uint256 amount) external {
        // Checkpoint values
        uint256 initialUsdcBalance = uSDC.balanceOf(address(this));
        uint256 initialCUsdcBalance = cUSDC.balanceOf(address(this));

        uint256 approvedAmount = uSDC.allowance(msg.sender, address(this));

        if (approvedAmount < amount) {
            revert Errors.NotEnoughAllowanceApproved();
        }

        // Deposit `msg.sender` USDC into this contract account.
        bool checkTransfer = uSDC.transferFrom(
            msg.sender,
            address(this),
            amount
        );

        if (!checkTransfer) {
            revert Errors.UsdcTransferFailed();
        }

        // Approve the cUSDC contract to transfer USDC to the compound protocol contract.
        bool check = uSDC.approve(address(cUSDC), amount);

        if (!check) {
            revert("Failed approval");
        }

        // Deposit `amount` USDC into the compound protocol to receive cUSDC.
        cUSDC.supply(address(uSDC), amount);

        uint256 newCUsdcBalance = cUSDC.balanceOf(address(this));

        // Calculate how many cUSDC we received from the protocol.
        uint256 dep = newCUsdcBalance - initialCUsdcBalance;

        checkTransfer = cUSDC.transfer(msg.sender, dep);

        if (!checkTransfer) {
            revert("cUSDC transfer from Contract to User failed");
        }

        // Final checks
        uint256 finalUsdcBalance = uSDC.balanceOf(address(this));

        if (finalUsdcBalance != initialUsdcBalance) {
            revert(
                "Final Usdc balance and initial usdc balance should be equal"
            );
        }

        uint256 finalCUsdcBalance = cUSDC.balanceOf(address(this));

        if (finalCUsdcBalance != initialCUsdcBalance) {
            revert(
                "Final cUSDC balance and initial USDC balance should be equal"
            );
        }
    }

    function withdraw(uint256 amount) external {
        uint256 balance = cUSDC.balanceOf(address(this));

        console.log(
            "CONTRACT cUSDC BALANCE IS",
            balance,
            "USDC BALANCE IS",
            uSDC.balanceOf(address(this))
        );

        cUSDC.withdraw(address(uSDC), amount);

        console.log("SUCCESFULLY WITHDRWAN cUSDC", balance);

        uint256 usdcBalance = uSDC.balanceOf(address(this));

        console.log(
            "CONTRACT USDC BALANCE IS",
            usdcBalance,
            "cUSDC BALANCE IS",
            cUSDC.balanceOf(address(this))
        );

        bool check = uSDC.transfer(msg.sender, usdcBalance);

        require(check, "USDC WITHDRAWAL TO USER FAILED");
    }
}
