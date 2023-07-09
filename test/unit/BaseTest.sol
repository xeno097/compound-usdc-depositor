// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {CometMainInterface} from "lib/comet/contracts/CometInterface.sol";

contract BaseTest is Test {
    function mockERC20BalanceOfCall(address target, address account) internal {
        mockERC20BalanceOfCall(target, account, 0);
    }

    function mockERC20BalanceOfCall(
        address target,
        address account,
        uint256 ret
    ) internal {
        vm.mockCall(
            target,
            abi.encodeWithSelector(IERC20.balanceOf.selector, account),
            abi.encode(ret)
        );
    }

    function mockERC20AllowanceCall(
        address target,
        address account,
        address targetAccount,
        uint256 ret
    ) internal {
        vm.mockCall(
            target,
            abi.encodeWithSelector(
                IERC20.allowance.selector,
                account,
                targetAccount
            ),
            abi.encode(ret)
        );
    }

    function mockERC20AllowanceCall(
        address target,
        address account,
        address targetAccount
    ) internal {
        mockERC20AllowanceCall(target, account, targetAccount, 0);
    }

    function mockERC20TransferFromCall(
        address targetContract,
        address from,
        address to,
        uint256 amount,
        bool ret
    ) internal {
        vm.mockCall(
            targetContract,
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                amount
            ),
            abi.encode(ret)
        );
    }

    function mockERC20ApproveCall(
        address targetContract,
        address spender,
        uint256 amount,
        bool ret
    ) internal {
        vm.mockCall(
            targetContract,
            abi.encodeWithSelector(IERC20.approve.selector, spender, amount),
            abi.encode(ret)
        );
    }

    function mockCometTokenSupplyCall(
        address targetContract,
        address token,
        uint256 amount
    ) internal {
        vm.mockCall(
            targetContract,
            abi.encodeWithSelector(
                CometMainInterface.supply.selector,
                token,
                amount
            ),
            abi.encode()
        );
    }

    function mockERC20TokenTransferCall(
        address targetContract,
        address to,
        uint256 amount,
        bool ret
    ) internal {
        vm.mockCall(
            targetContract,
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount),
            abi.encode(ret)
        );
    }

    // Storage
    function writeToStorage(
        address target,
        bytes32 sslot,
        bytes32 value,
        uint256 offset
    ) internal {
        bytes32 storageSlot = bytes32(uint256(sslot) + offset);
        vm.store(target, storageSlot, value);
    }
}
