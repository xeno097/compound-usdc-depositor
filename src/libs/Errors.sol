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
}
