// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseTest.sol";
import {CompoundUsdcDepositor} from "src/CompoundUsdcDepositor.sol";
import {Errors} from "src/libs/Errors.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {CometMainInterface} from "lib/comet/contracts/CometInterface.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {CTokenMock} from "test/mocks/cTokenMock.sol";

contract BaseCompoundDepositorTests is BaseTest {
    CompoundUsdcDepositor instance;
    address instanceAddress;
    ERC20Mock usdcContractMock;
    address usdcContractAddress;
    CTokenMock cUsdcContractMock;
    address compoundUsdcContractAddres;
    address senderAddress;

    function setUp() public {
        usdcContractMock = new ERC20Mock();
        cUsdcContractMock = new CTokenMock();
        usdcContractAddress = address(usdcContractMock);
        compoundUsdcContractAddres = address(cUsdcContractMock);

        instance = new CompoundUsdcDepositor(
            usdcContractAddress,
            compoundUsdcContractAddres
        );
        instanceAddress = address(instance);
        senderAddress = address(this);
    }
}

contract CompoundDepositorDepositTests is BaseCompoundDepositorTests {
    function testCannotDepositIfUserDidNotSetUsdcAllowance(
        uint256 amount
    ) external {
        amount = bound(amount, 1, type(uint256).max);

        mockERC20BalanceOfCall(usdcContractAddress, address(instance));
        mockERC20BalanceOfCall(compoundUsdcContractAddres, address(instance));

        mockERC20AllowanceCall(
            compoundUsdcContractAddres,
            senderAddress,
            address(instance)
        );

        vm.expectRevert(Errors.NotEnoughAllowanceApproved.selector);

        instance.deposit(amount);
    }

    function testCannotDepositIfContractCUsdcBalanceChangesAfterInteractions(
        uint256 amount
    ) external {
        amount = bound(amount, 1, type(uint256).max);

        mockERC20AllowanceCall(
            compoundUsdcContractAddres,
            senderAddress,
            address(instance),
            amount
        );

        cUsdcContractMock.setUpdateBalance(true);

        vm.expectRevert(Errors.InvalidState.selector);

        instance.deposit(amount);
    }

    function testDeposit(uint256 amount) external {
        amount = bound(amount, 1, type(uint256).max);

        mockERC20BalanceOfCall(compoundUsdcContractAddres, address(instance));

        mockERC20AllowanceCall(
            compoundUsdcContractAddres,
            senderAddress,
            address(instance),
            amount
        );

        instance.deposit(amount);
    }
}

contract CompoundDepositorWithDrawTests is BaseCompoundDepositorTests {
    function testCannotWithdrawIfUserDidNotSetEnoughCUsdcAllowance(
        uint256 amount
    ) external {
        amount = bound(amount, 1, type(uint256).max);

        vm.expectRevert(Errors.NotEnoughAllowanceApproved.selector);

        instance.withdraw(amount);
    }

    function testCannotWithdrawIfCUsdcBalanceChangedAfterInteractions(
        uint256 amount
    ) external {
        amount = bound(amount, 1, type(uint256).max);

        mockERC20AllowanceCall(
            compoundUsdcContractAddres,
            senderAddress,
            address(instance),
            amount
        );

        cUsdcContractMock.setUpdateBalance(true);

        vm.expectRevert(Errors.InvalidState.selector);

        instance.withdraw(amount);
    }

    function testWithdraw(uint256 amount) external {
        amount = bound(amount, 1, type(uint256).max);

        mockERC20AllowanceCall(
            compoundUsdcContractAddres,
            senderAddress,
            address(instance),
            amount
        );

        instance.withdraw(amount);

        uint256 finalBalance = instance.balanceOf(senderAddress);

        assertEq(finalBalance, 0);
    }
}

contract CompoundDepositorSetUsdcContractAddressTests is
    BaseCompoundDepositorTests
{
    function testCannotSetUsdcContractAddress(
        address notOwnerAccount,
        address newTokenAddress
    ) external {
        vm.assume(
            notOwnerAccount != address(this) && newTokenAddress != address(0)
        );

        vm.prank(notOwnerAccount);

        vm.expectRevert("Ownable: caller is not the owner");

        instance.setUsdcContractAddress(newTokenAddress);
    }

    function testSetUsdcContractAddress(address newTokenAddress) external {
        vm.assume(newTokenAddress != address(0));

        instance.setUsdcContractAddress(newTokenAddress);

        address res = instance.uSDCAddress();
        assertEq(res, newTokenAddress);
    }
}

contract CompoundDepositorSetCUsdcContractAddressTests is
    BaseCompoundDepositorTests
{
    function testCannotSetCUsdcContractAddressIfSenderIsNotTheOwner(
        address notOwnerAccount,
        address newTokenAddress
    ) external {
        vm.assume(
            notOwnerAccount != address(this) && newTokenAddress != address(0)
        );

        vm.prank(notOwnerAccount);

        vm.expectRevert("Ownable: caller is not the owner");

        instance.setCUsdcContractAddress(newTokenAddress);
    }

    function testSetCUsdcContractAddress(address newTokenAddress) external {
        vm.assume(newTokenAddress != address(0));

        instance.setCUsdcContractAddress(newTokenAddress);

        address res = instance.cUSDCAddress();
        assertEq(res, newTokenAddress);
    }
}
