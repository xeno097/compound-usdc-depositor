// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ERC20Mock is IERC20 {
    uint256 approveCalls;
    bool[] approveReturnValues;

    bool updateBalance;
    uint256 balanceReturnValue;

    uint256 transferCalls;
    bool resetBalanceAfterTransfer;
    bool[] transferReturnValues;

    function totalSupply() external view override returns (uint256) {}

    function setUpdateBalance(bool newValue) external {
        updateBalance = newValue;
    }

    function balanceOf(address) external view override returns (uint256) {
        return balanceReturnValue;
    }

    function setResetBalaceAfterTransfer(bool newValue) external {
        resetBalanceAfterTransfer = newValue;
    }

    function setTrasferReturnValueOnce(bool returnValue) external {
        transferReturnValues.push(returnValue);
    }

    function transfer(address, uint256) external override returns (bool) {
        if (transferCalls >= transferReturnValues.length) {
            return false;
        }

        bool ret = transferReturnValues[transferCalls];

        if (ret) {
            _maybeUpdateBalance();
        }

        if (resetBalanceAfterTransfer) {
            balanceReturnValue = 0;
        }

        transferCalls++;
        return ret;
    }

    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {}

    function mockApproveReturnValue(bool value) external {
        approveReturnValues.push(value);
    }

    function approve(address, uint256) external override returns (bool) {
        if (approveCalls >= approveReturnValues.length) {
            return false;
        }

        approveCalls++;
        return approveReturnValues[approveCalls - 1];
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external override returns (bool) {
        _maybeUpdateBalance();

        return true;
    }

    function _maybeUpdateBalance() internal {
        if (updateBalance) {
            balanceReturnValue++;
        }
    }
}
