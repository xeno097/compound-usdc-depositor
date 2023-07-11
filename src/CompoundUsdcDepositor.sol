// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {CometInterface} from "lib/comet/contracts/CometInterface.sol";
import {Errors} from "src/libs/Errors.sol";

contract CompoundUsdcDepositor {
    CometInterface cUSDC;
    IERC20 uSDC;

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
        return cUSDC.balanceOf(account);
    }

    /*
     * Allows `msg.sender` to deposit `amount` of tokens into the compound protocol and receive cTokens in exchange.
     *
     * @param amount The amount of tokens to be deposited into the compound protocol.
     */
    function deposit(uint256 amount) external {
        // Checkpoint values
        uint256 initialUsdcBalance = uSDC.balanceOf(address(this));
        uint256 initialCUsdcBalance = cUSDC.balanceOf(address(this));

        _checkApproval(IERC20(address(cUSDC)), amount);

        // Deposit `amount` USDC into the compound protocol and send cUSDC in response.
        cUSDC.supplyFrom(msg.sender, msg.sender, address(uSDC), amount);

        _verifyFinalState(initialUsdcBalance, initialCUsdcBalance);
    }

    /*
     * Allows `msg.sender` to withdraw USDC in exchange of `amount` of cUSDC tokens.
     *
     * @param amount The amount of tokens to be deposited into the compound protocol to withdraw USDC.
     */
    function withdraw(uint256 amount) external {
        uint256 initialUsdcBalance = uSDC.balanceOf(address(this));
        uint256 initialCUsdcBalance = cUSDC.balanceOf(address(this));

        _checkApproval(IERC20(address(cUSDC)), amount);

        cUSDC.withdrawFrom(msg.sender, msg.sender, address(uSDC), amount);

        _verifyFinalState(initialUsdcBalance, initialCUsdcBalance);
    }

    /*
     * Checks that `msg.sender` set at least `amount` of allowance for `token` .
     *
     * @param from The ERC20 token to transfer.
     * @param amount The amount of ERC20 tokens to be transferred.
     */
    function _checkApproval(IERC20 token, uint256 amount) internal view {
        uint256 approvedAmount = token.allowance(msg.sender, address(this));

        if (approvedAmount < amount) {
            revert Errors.NotEnoughAllowanceApproved();
        }
    }

    /*
     * Checks that the contract did not change its balance in any of the tokens of the transaction.
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
