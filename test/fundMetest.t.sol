// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/fundme.sol";
import {Script} from "forge-std/Script.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address fakeUser = makeAddr("fakeUser");
    uint256 SEND_value = 0.1 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();

        fundMe = deployFundMe.run();
        vm.deal(fakeUser, 10 ether);
    }

    function testMinimumDollaris5() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    address constant OWNER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    function testOwner() public {
        assertEq(fundMe.i_owner(), address(OWNER));
    }

    function testPriceFeedVersionIsAccurate() public {
        if (block.chainid == 11155111) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 4);
        } else if (block.chainid == 1) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 6);
        }
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    modifier fakeFunding() {
        vm.prank(fakeUser);
        fundMe.fund{value: 0.1 ether}();
        _;
    }

    function testFundUpdatesFundDataStructure() public fakeFunding {
        assertEq(fundMe.getAddressToAmountFunded(fakeUser), 0.1 ether);
    }

    function testAddsFunderToFunders() public fakeFunding {
        assertEq(fundMe.getFunder(0), fakeUser);
    }

    function testOnlyOwnerCanWithdraw() public fakeFunding {
        vm.prank(fakeUser);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawFromSingleFunder() public {
        uint256 contractBalance = address(fundMe).balance;
        uint256 ownerBalance = fundMe.getOwner().balance;
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.assertEq(contractBalance, 0);
    }

    function testWithdrawFromMultipleFunder() public fakeFunding {
        uint160 funderIndex = 10;
        uint256 startContractBalance = address(fundMe).balance;
        uint256 ownerBalance = fundMe.getOwner().balance;
        for (uint160 i = 0; i < 10; i++) {
            hoax(address(i), SEND_value);
            fundMe.fund{value: SEND_value}();
        }
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.assertEq(address(fundMe).balance, 0);
        vm.stopPrank();
    }

    function testWithdrawFromMultipleFunderCheaper() public fakeFunding {
        uint160 funderIndex = 10;
        uint256 startContractBalance = address(fundMe).balance;
        uint256 ownerBalance = fundMe.getOwner().balance;
        for (uint160 i = 0; i < 10; i++) {
            hoax(address(i), SEND_value);
            fundMe.fund{value: SEND_value}();
        }
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.assertEq(address(fundMe).balance, 0);
        vm.stopPrank();
    }
}
