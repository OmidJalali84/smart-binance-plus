// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SmartBinancePlus} from "../../src/SmartBinancePlus.sol";
import {console} from "forge-std/console.sol";
import {DAI} from "../Mocks/DAI.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Unit is Test {
    SmartBinancePlus public smartBinancePlus;
    DAI public dai;

    SmartBinancePlus.Plan Binary = Binary;
    SmartBinancePlus.Plan InOrder = SmartBinancePlus.Plan.InOrder;

    address daiHolder = address(100);
    address owner = address(101);
    address admin = address(102);
    address root = address(103);

    address user1 = address(1);
    address user2 = address(2);
    address user3 = address(3);
    address user4 = address(4);
    address user5 = address(5);
    address user6 = address(6);
    address user7 = address(7);
    address user8 = address(8);

    function setUp() public {
        dai = new DAI(daiHolder, 1e30);
        smartBinancePlus = new SmartBinancePlus(owner, admin, address(dai), root);
    }

    function fundDai(address user) public {
        vm.prank(daiHolder);
        dai.transfer(user, 100 ether);
        vm.prank(user);
        dai.approve(address(smartBinancePlus), 100 ether);
    }

    function fundDai(address user, uint256 amount) public {
        vm.prank(daiHolder);
        dai.transfer(user, amount);
        vm.prank(user);
        dai.approve(address(smartBinancePlus), amount);
    }

    function registerUser(address user, SmartBinancePlus.Plan plan, address referrer) public {
        fundDai(user);
        vm.prank(user);
        smartBinancePlus.register(plan, referrer);
    }

    function test_simpleRegister() public {
        registerUser(user1, Binary, root);
        assertEq(smartBinancePlus.drCat().balanceOf(user1), 500e18);
    }

    function test_registerReverts() public {
        fundDai(user1, 10000 ether);
        vm.startPrank(user1);
        vm.expectRevert("Referrer is not active");
        smartBinancePlus.register(Binary, user2);

        smartBinancePlus.register(Binary, root);

        vm.expectRevert("User is already active");
        smartBinancePlus.register(Binary, root);

        vm.expectRevert("User is already active");
        smartBinancePlus.register(Binary, user1);
        vm.stopPrank();
    }

    function test_registerBinary() public {
        registerUser(user1, Binary, root);

        SmartBinancePlus.User memory uplineInfo = smartBinancePlus.getUser(root);
        SmartBinancePlus.User memory userInfo = smartBinancePlus.getUser(user1);

        assertEq(userInfo.referrer, root);
        assertTrue(userInfo.plan == Binary);
        assertEq(userInfo.totalEarnings, 0);
        assertEq(userInfo.directs, 0);
        assertEq(userInfo.left, address(0));
        assertEq(userInfo.right, address(0));
        assertEq(userInfo.currentLeftVolume, 0);
        assertEq(userInfo.currentRightVolume, 0);
        assertEq(userInfo.totalLeftVolume, 0);
        assertEq(userInfo.totalRightVolume, 0);
        assertEq(userInfo.balancePoints, 0);
        assertEq(userInfo.active, true);

        assertEq(uplineInfo.referrer, address(0));
        assertTrue(uplineInfo.plan == Binary);
        assertEq(uplineInfo.totalEarnings, 0);
        assertEq(uplineInfo.directs, 1);
        assertEq(uplineInfo.left, user1);
        assertEq(uplineInfo.right, address(0));
        assertEq(uplineInfo.currentLeftVolume, 90 ether);
        assertEq(uplineInfo.currentRightVolume, 0);
        assertEq(uplineInfo.totalLeftVolume, 90 ether);
        assertEq(uplineInfo.totalRightVolume, 0);
        assertEq(uplineInfo.balancePoints, 0);
        assertEq(uplineInfo.active, true);
    }

    function test_points() public {
        registerUser(user1, Binary, root);
        assertEq(smartBinancePlus.getUser(root).balancePoints, 0);
        registerUser(user2, Binary, root);
        assertEq(smartBinancePlus.getUser(root).balancePoints, 1);
        registerUser(user3, Binary, user1);
        assertEq(smartBinancePlus.getUser(root).balancePoints, 1);
        assertEq(smartBinancePlus.getUser(user1).balancePoints, 0);
        registerUser(user4, Binary, user1);
        assertEq(smartBinancePlus.getUser(root).balancePoints, 1);
        assertEq(smartBinancePlus.getUser(user1).balancePoints, 1);
        registerUser(user5, Binary, user2);
        assertEq(smartBinancePlus.getUser(root).balancePoints, 2);
        assertEq(smartBinancePlus.getUser(user2).balancePoints, 0);
        registerUser(user6, Binary, user2);
        assertEq(smartBinancePlus.getUser(root).balancePoints, 3);
        assertEq(smartBinancePlus.getUser(user2).balancePoints, 1);

        assertEq(smartBinancePlus.totalCyclePoints(), 5);
        assertEq(smartBinancePlus.getPointWorth(), 6 * 90 ether / 5);
    }

    function test_claimingRewards() public {
        registerUser(user1, Binary, root);
        registerUser(user2, Binary, root);
        registerUser(user3, Binary, user1);
        registerUser(user4, Binary, user1);
        registerUser(user5, Binary, user2);
        registerUser(user6, Binary, user2);

        assertEq(smartBinancePlus.totalCyclePoints(), 5);
        uint256 pointWorth = 6 * 90 ether / 5;
        assertEq(smartBinancePlus.getPointWorth(), pointWorth);

        uint256 bal1Contract = dai.balanceOf(address(smartBinancePlus));
        uint256 bal1owner = dai.balanceOf(root);
        uint256 bal1user1 = dai.balanceOf(user1);
        uint256 bal1user2 = dai.balanceOf(user2);
        uint256 bal1user3 = dai.balanceOf(user3);
        uint256 bal1user4 = dai.balanceOf(user4);
        uint256 bal1user5 = dai.balanceOf(user5);
        uint256 bal1user6 = dai.balanceOf(user6);
        vm.warp(2 hours);
        smartBinancePlus.distributeRewards();

        uint256 bal2Contract = dai.balanceOf(address(smartBinancePlus));
        uint256 bal2owner = dai.balanceOf(root);
        uint256 bal2user1 = dai.balanceOf(user1);
        uint256 bal2user2 = dai.balanceOf(user2);
        uint256 bal2user3 = dai.balanceOf(user3);
        uint256 bal2user4 = dai.balanceOf(user4);
        uint256 bal2user5 = dai.balanceOf(user5);
        uint256 bal2user6 = dai.balanceOf(user6);

        assertEq(bal1Contract - bal2Contract, 5 * pointWorth);
        assertEq(bal2owner - bal1owner, 3 * pointWorth);
        assertEq(bal2user1 - bal1user1, 1 * pointWorth);
        assertEq(bal2user2 - bal1user2, 1 * pointWorth);
        assertEq(bal2user3 - bal1user3, 0 * pointWorth);
        assertEq(bal2user4 - bal1user4, 0 * pointWorth);
        assertEq(bal2user5 - bal1user5, 0 * pointWorth);
        assertEq(bal2user6 - bal1user6, 0 * pointWorth);
    }

    function test_binaryMoreThan2Directs() public {
        registerUser(user1, Binary, root);
        registerUser(user2, Binary, root);
        registerUser(user3, Binary, user1);
        registerUser(user4, Binary, user1);
        registerUser(user5, Binary, user2);
        registerUser(user6, Binary, root);
        assertEq(smartBinancePlus.getUser(user6).referrer, user2);
    }

    function test_binaryMoreThan2Directs2() public {
        registerUser(user1, Binary, root);
        registerUser(user2, Binary, root);
        registerUser(user3, Binary, user1);
        registerUser(user4, Binary, user1);
        registerUser(user5, Binary, user2);
        registerUser(user6, Binary, user2);
        registerUser(user7, Binary, root);
        assertEq(smartBinancePlus.getUser(user7).referrer, user3);
    }

    function test_inOrderInvites() public {
        registerUser(user1, Binary, root);
        registerUser(user2, Binary, root);
        registerUser(user3, Binary, user1);
        // registerUser(user4, Binary, user1);
        registerUser(user5, Binary, user2);
        registerUser(user6, Binary, user2);
        registerUser(user7, InOrder, user6);
        assertEq(smartBinancePlus.getUser(user1).directs, 1);
        registerUser(user8, Binary, user7);
        assertEq(smartBinancePlus.getUser(user1).directs, 2);
        assertEq(smartBinancePlus.getUser(user7).directs, 0);
    }

    function test_rewardTypes() public {
        registerUser(user1, Binary, root);
        registerUser(user2, Binary, root);

        registerUser(user3, InOrder, user1);
        fundDai(user4);
        vm.prank(user4);
        vm.expectRevert("Referrer is in binary plan and has an in-order hand");
        smartBinancePlus.register(InOrder, user1);
        registerUser(user4, Binary, user1);

        registerUser(user5, Binary, user2);
        registerUser(user6, Binary, user2);
        registerUser(user7, InOrder, user3);
        registerUser(user8, InOrder, user3);

        assertEq(smartBinancePlus.getUser(root).balancePoints, 3);
        assertEq(smartBinancePlus.getUser(user1).balancePoints, 1);
        assertEq(smartBinancePlus.getUser(user2).balancePoints, 1);
        assertEq(smartBinancePlus.getUser(user3).balancePoints, 1);

        uint256 pointWorth = smartBinancePlus.getPointWorth();

        uint256 bal1Owner = dai.balanceOf(root);
        uint256 bal1User1 = dai.balanceOf(user1);
        uint256 bal1User2 = dai.balanceOf(user2);
        uint256 bal1User3 = dai.balanceOf(user3);

        vm.warp(2 hours);
        smartBinancePlus.distributeRewards();

        uint256 bal2Owner = dai.balanceOf(root);
        uint256 bal2User1 = dai.balanceOf(user1);
        uint256 bal2User2 = dai.balanceOf(user2);
        uint256 bal2User3 = dai.balanceOf(user3);

        assertEq(bal2User1 - bal1User1, pointWorth * 75 / 100);
        assertEq(bal2User3 - bal1User3, pointWorth * 50 / 100);

        uint256 remainings = (pointWorth * 25 / 100) + (pointWorth * 50 / 100);
        uint256 share = remainings / 2;
        assertEq(bal2Owner - bal1Owner, (pointWorth * 3) + share);
        assertEq(bal2User2 - bal1User2, pointWorth + share);
    }

    function test_revertWithTwoInOrderDirect() public {
        registerUser(user1, InOrder, root);
        fundDai(user2);
        vm.prank(user2);
        vm.expectRevert("Referrer is in binary plan and has an in-order hand");
        smartBinancePlus.register(InOrder, root);
    }

    function test_adminChangeCycle() public {
        vm.warp(100 days);
        // Owner requests change
        vm.prank(owner);
        smartBinancePlus.changeRewardCycle(2 hours);
        // Admin confirms
        vm.warp(block.timestamp + 10 minutes);
        vm.prank(admin);
        smartBinancePlus.changeRewardCycle(2 hours);
        assertEq(smartBinancePlus.REWARD_CYCLE_DURATION(), 2 hours);
    }

    function test_adminChangeCycle_revertSameUser() public {
        vm.warp(100 days);
        vm.prank(owner);
        smartBinancePlus.changeRewardCycle(2 hours);
        vm.warp(block.timestamp + 10 minutes);
        vm.prank(owner);
        vm.expectRevert("Request should be accepted from other author");
        smartBinancePlus.changeRewardCycle(2 hours);
    }

    function test_adminWithdrawEmergency() public {
        vm.warp(100 days);
        // Fund contract with DAI
        fundDai(address(smartBinancePlus));
        uint256 contractBal = dai.balanceOf(address(smartBinancePlus));
        // Owner requests withdraw
        vm.prank(owner);
        smartBinancePlus.withdrawEmergancy();
        // Admin confirms
        vm.warp(block.timestamp + 10 minutes);
        vm.prank(admin);
        smartBinancePlus.withdrawEmergancy();
        // All DAI should be sent to owner
        assertEq(dai.balanceOf(owner), contractBal);
        assertEq(dai.balanceOf(address(smartBinancePlus)), 0);
    }

    function test_adminWithdrawEmergency_revertSameUser() public {
        vm.warp(100 days);
        fundDai(address(smartBinancePlus));
        vm.prank(owner);
        smartBinancePlus.withdrawEmergancy();
        vm.warp(block.timestamp + 10 minutes);
        vm.prank(owner);
        vm.expectRevert("Request should be accepted from other author");
        smartBinancePlus.withdrawEmergancy();
    }

    function test_sendNewMessage() public {
        string memory msg1 = "Hello, world!";
        vm.prank(owner);
        smartBinancePlus.sendNewMessage(msg1);
        assertEq(smartBinancePlus.ownerMessage(), msg1);
        string memory msg2 = "Another message";
        vm.prank(owner);
        smartBinancePlus.sendNewMessage(msg2);
        assertEq(smartBinancePlus.ownerMessage(), msg2);
    }

    function test_ownerHasCatAccess() public {
        address drCat = address(smartBinancePlus.drCat());
        vm.prank(owner);
        IERC20(drCat).transferFrom(drCat, owner, 5000e18);
    }
}
