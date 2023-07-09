// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Errors {
    /*
     * @dev Thrown when `msg.sender` has not given enough allowance to the contract to move the funds.
     */
    error NotEnoughAllowanceApproved();

    /*
     * @dev Thrown when transfering USDC from one account to another fails.
     */
    error UsdcTransferFailed();

    /*
     * @dev Thrown when approval for cUSDC contract to move USDC tokens fails.
     */
    error CUsdcApprovalFailed();

    /*
     * @dev Thrown when approval reset for cUSDC contract to move USDC tokens fails.
     */
    error CUsdcApprovalResetFailed();

    /*
     * @dev Thrown when tranfer of cUSDC tokens to the User fails.
     */
    error CUsdcTransferToUserFailed();

    /*
     * @dev Thrown when after checking the contract state an anomaly is found.
     */
    error InvalidState();
}
