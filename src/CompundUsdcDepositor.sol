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
    mapping(address => uint256) cUsdcPerAddress;

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
        bool ok = uSDC.transferFrom(msg.sender, address(this), amount);

        if (!ok) {
            revert Errors.UsdcTransferFailed();
        }

        // Approve the cUSDC contract to transfer USDC to the compound protocol contract.
        ok = uSDC.approve(address(cUSDC), amount);

        if (!ok) {
            revert Errors.CUsdcApprovalFailed();
        }

        // Deposit `amount` USDC into the compound protocol to receive cUSDC.
        cUSDC.supply(address(uSDC), amount);

        // Resettting usdc approval for this contract.
        ok = uSDC.approve(address(cUSDC), 0);

        if (!ok) {
            revert Errors.CUsdcApprovalResetFailed();
        }

        uint256 newCUsdcBalance = cUSDC.balanceOf(address(this));

        if (newCUsdcBalance <= initialCUsdcBalance) {
            revert Errors.InvalidState();
        }

        // TODO check if there is any way to know before hand how many cTokens the user will receive
        // Calculate how many cUSDC we received from the protocol.
        uint256 cUsdcAmountToTransfer = newCUsdcBalance - initialCUsdcBalance;
        cUsdcPerAddress[msg.sender] += cUsdcAmountToTransfer;

        ok = cUSDC.transfer(msg.sender, cUsdcAmountToTransfer);

        if (!ok) {
            revert Errors.CUsdcTransferToUserFailed();
        }

        // Final checks
        _verifyFinalState(initialUsdcBalance, initialCUsdcBalance);
    }

    /*
     * Checks that the contract did not change its balance in any of the tokens.
     */
    function _verifyFinalState(
        uint256 initialUsdcBalance,
        uint256 initialCUsdcBalance
    ) internal view {
        uint256 finalUsdcBalance = uSDC.balanceOf(address(this));

        if (finalUsdcBalance != initialUsdcBalance) {
            revert Errors.InvalidState();
        }

        uint256 finalCUsdcBalance = cUSDC.balanceOf(address(this));

        if (finalCUsdcBalance != initialCUsdcBalance) {
            revert Errors.InvalidState();
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
