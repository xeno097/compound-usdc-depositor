// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {CompundUsdcDepositor} from "src/CompundUsdcDepositor.sol";
import {Errors} from "src/libs/Errors.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract CompoundDepositorDepositTests is Test {
    CompundUsdcDepositor instance;
    address usdcContractAddress = address(97);
    address cUsdcContractAddres = address(666);

    function setUp() public {
        instance = new CompundUsdcDepositor(
            usdcContractAddress,
            cUsdcContractAddres
        );
    }

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
        uint256 amount
    ) internal {
        vm.mockCall(
            targetContract,
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                amount
            ),
            abi.encode(false)
        );
    }

    function testCannotDepositIfUserDidNotSetUsdcAllowance(
        uint256 amount
    ) external {
        amount = bound(amount, 1, type(uint256).max);

        mockERC20BalanceOfCall(usdcContractAddress, address(instance));
        mockERC20BalanceOfCall(cUsdcContractAddres, address(instance));

        mockERC20AllowanceCall(
            usdcContractAddress,
            address(this),
            address(instance)
        );

        vm.expectRevert(Errors.NotEnoughAllowanceApproved.selector);

        instance.deposit(amount);
    }

    function testCannotDepositIfUsdcTransferFromSenderToContractFails(
        uint256 amount
    ) external {
        amount = bound(amount, 1, type(uint256).max);

        mockERC20BalanceOfCall(usdcContractAddress, address(instance));
        mockERC20BalanceOfCall(cUsdcContractAddres, address(instance));

        mockERC20AllowanceCall(
            usdcContractAddress,
            address(this),
            address(instance),
            amount
        );

        mockERC20TransferFromCall(
            usdcContractAddress,
            address(this),
            address(instance),
            amount
        );

        vm.expectRevert(Errors.UsdcTransferFailed.selector);

        instance.deposit(amount);
    }
}
