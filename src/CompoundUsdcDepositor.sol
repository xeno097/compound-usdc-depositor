// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {CometInterface} from "lib/comet/contracts/CometInterface.sol";
import "forge-std/console.sol";
import {Errors} from "src/libs/Errors.sol";

contract CompoundUsdcDepositor {
    uint256 public number;
    CometInterface cUSDC;
    IERC20 uSDC;
    mapping(address => uint256) cUsdcPerAddress;

    constructor(address _usdc, address _cUcdc) {
        uSDC = IERC20(_usdc);
        cUSDC = CometInterface(_cUcdc);
    }

    /*
     * Returns the amount of cUSDC tokens that `account` can use to reedem USDC from the compound protocol.
     *
     * @param account the address of the user which cUSDC tokens balance is to be inspected.
     */
    function balanceOf(address account) external view returns (uint256) {
        return cUsdcPerAddress[account];
    }

    /*
     * Allows `msg.sender` to deposit `amount` of tokens into the compound protocol and receive cTokens in exchange.
     *
     * @param amount The amount of tokens to be deposited into the compound protocol.
     */
    // TODO: update this logic using supplyFrom instead of supply to save gas and operations
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

    function withdraw(uint256 amount) external {
        if (amount > cUsdcPerAddress[msg.sender]) {
            revert Errors.InvalidWithdrawAmount();
        }

        cUsdcPerAddress[msg.sender] -= amount;

        uint256 initialUsdcBalance = uSDC.balanceOf(address(this));
        uint256 initialCUsdcBalance = cUSDC.balanceOf(address(this));

        // MAYBE CREATE A FUNCTION FOR THIS
        uint256 approvedAmount = cUSDC.allowance(msg.sender, address(this));

        if (approvedAmount < amount) {
            revert Errors.NotEnoughAllowanceApproved();
        }

        // Deposit `msg.sender` USDC into this contract account.
        bool ok = cUSDC.transferFrom(msg.sender, address(this), amount);

        if (!ok) {
            revert Errors.UsdcTransferFailed();
        }
        // END OF THE MAYBE FUNCTION BODY

        uint256 newCUsdcBalance = cUSDC.balanceOf(address(this));

        if (newCUsdcBalance <= initialCUsdcBalance) {
            revert Errors.InvalidState();
        }

        uint256 amountToWithDraw = newCUsdcBalance - initialCUsdcBalance;

        cUSDC.withdrawTo(msg.sender, address(uSDC), amountToWithDraw);

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
}
