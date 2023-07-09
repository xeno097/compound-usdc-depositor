// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {CompundUsdcDepositor} from "src/CompundUsdcDepositor.sol";
import {Errors} from "src/libs/Errors.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {CometMainInterface} from "lib/comet/contracts/CometInterface.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {CTokenMock} from "test/mocks/cTokenMock.sol";

contract CompoundDepositorDepositTests is Test {
    CompundUsdcDepositor instance;
    address usdcContractAddress;
    address compoundUsdcContractAddres;
    ERC20Mock usdcContractMock;
    CTokenMock cUsdcContractMock;

    function setUp() public {
        usdcContractMock = new ERC20Mock();
        cUsdcContractMock = new CTokenMock();
        usdcContractAddress = address(usdcContractMock);
        compoundUsdcContractAddres = address(cUsdcContractMock);

        instance = new CompundUsdcDepositor(
            usdcContractAddress,
            compoundUsdcContractAddres
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

    // TESTS
    function testCannotDepositIfUserDidNotSetUsdcAllowance(
        uint256 amount
    ) external {
        amount = bound(amount, 1, type(uint256).max);

        mockERC20BalanceOfCall(usdcContractAddress, address(instance));
        mockERC20BalanceOfCall(compoundUsdcContractAddres, address(instance));

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
        mockERC20BalanceOfCall(compoundUsdcContractAddres, address(instance));

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
            amount,
            false
        );

        vm.expectRevert(Errors.UsdcTransferFailed.selector);

        instance.deposit(amount);
    }

    function testCannotDepositIfCUsdcApprovalFails(uint256 amount) external {
        amount = bound(amount, 1, type(uint256).max);

        mockERC20BalanceOfCall(usdcContractAddress, address(instance));
        mockERC20BalanceOfCall(compoundUsdcContractAddres, address(instance));

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
            amount,
            true
        );

        mockERC20ApproveCall(
            usdcContractAddress,
            compoundUsdcContractAddres,
            amount,
            false
        );

        vm.expectRevert(Errors.CUsdcApprovalFailed.selector);

        instance.deposit(amount);
    }

    function testCannotDepositIfCUsdcApprovalResetFails(
        uint256 amount
    ) external {
        amount = bound(amount, 1, type(uint256).max);

        mockERC20BalanceOfCall(usdcContractAddress, address(instance));
        mockERC20BalanceOfCall(compoundUsdcContractAddres, address(instance));

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
            amount,
            true
        );

        mockERC20ApproveCall(
            usdcContractAddress,
            compoundUsdcContractAddres,
            amount,
            true
        );

        mockERC20ApproveCall(
            usdcContractAddress,
            compoundUsdcContractAddres,
            0,
            false
        );

        vm.expectRevert(Errors.CUsdcApprovalResetFailed.selector);

        instance.deposit(amount);
    }

    function testCannotDepositIfCUsdcContractBalanceDidNotIncrease(
        uint256 amount
    ) external {
        amount = bound(amount, 1, type(uint256).max);

        mockERC20BalanceOfCall(usdcContractAddress, address(instance));

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
            amount,
            true
        );

        mockERC20ApproveCall(
            usdcContractAddress,
            compoundUsdcContractAddres,
            amount,
            true
        );

        mockERC20ApproveCall(
            usdcContractAddress,
            compoundUsdcContractAddres,
            0,
            true
        );

        mockCometTokenSupplyCall(
            compoundUsdcContractAddres,
            usdcContractAddress,
            amount
        );

        mockERC20ApproveCall(
            usdcContractAddress,
            compoundUsdcContractAddres,
            0,
            true
        );

        vm.expectRevert(Errors.InvalidState.selector);

        instance.deposit(amount);
    }

    function testCannotDepositIfCUsdcTransferToUserFails(
        uint256 amount
    ) external {
        amount = bound(amount, 1, type(uint256).max);

        cUsdcContractMock.setUpdateBalance(true);

        mockERC20BalanceOfCall(usdcContractAddress, address(instance));

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
            amount,
            true
        );

        mockERC20ApproveCall(
            usdcContractAddress,
            compoundUsdcContractAddres,
            amount,
            true
        );

        mockERC20ApproveCall(
            usdcContractAddress,
            compoundUsdcContractAddres,
            0,
            true
        );

        vm.expectRevert(Errors.CUsdcTransferToUserFailed.selector);

        instance.deposit(amount);
    }

    function testCannotDepositIfContractUsdcBalanceChangesAfterInteractions(
        uint256 amount
    ) external {
        amount = bound(amount, 1, type(uint256).max);

        cUsdcContractMock.setUpdateBalance(true);
        usdcContractMock.setUpdateBalance(true);

        mockERC20AllowanceCall(
            usdcContractAddress,
            address(this),
            address(instance),
            amount
        );

        mockERC20ApproveCall(
            usdcContractAddress,
            compoundUsdcContractAddres,
            amount,
            true
        );

        mockERC20ApproveCall(
            usdcContractAddress,
            compoundUsdcContractAddres,
            0,
            true
        );

        cUsdcContractMock.setTrasferReturnValueOnce(true);

        vm.expectRevert(Errors.InvalidState.selector);

        instance.deposit(amount);
    }

    function testCannotDepositIfContractCusdcBalanceChangesAfterInteractions(
        uint256 amount
    ) external {
        amount = bound(amount, 1, type(uint256).max);

        cUsdcContractMock.setUpdateBalance(true);

        mockERC20BalanceOfCall(usdcContractAddress, address(instance));

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
            amount,
            true
        );

        mockERC20ApproveCall(
            usdcContractAddress,
            compoundUsdcContractAddres,
            amount,
            true
        );

        mockERC20ApproveCall(
            usdcContractAddress,
            compoundUsdcContractAddres,
            0,
            true
        );

        cUsdcContractMock.setTrasferReturnValueOnce(true);

        vm.expectRevert(Errors.InvalidState.selector);

        instance.deposit(amount);
    }

    function testDeposit(uint256 amount) external {
        amount = bound(amount, 1, type(uint256).max);

        cUsdcContractMock.setUpdateBalance(true);
        cUsdcContractMock.setResetBalaceAfterTransfer(true);

        mockERC20BalanceOfCall(usdcContractAddress, address(instance));

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
            amount,
            true
        );

        mockERC20ApproveCall(
            usdcContractAddress,
            compoundUsdcContractAddres,
            amount,
            true
        );

        mockERC20ApproveCall(
            usdcContractAddress,
            compoundUsdcContractAddres,
            0,
            true
        );

        cUsdcContractMock.setTrasferReturnValueOnce(true);

        instance.deposit(amount);
    }
}
