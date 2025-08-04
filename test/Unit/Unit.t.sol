// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SmartBinancePlus} from "../../src/SmartBinancePlus.sol";
import {DAI} from "../Mocks/DAI.sol";

contract Unit is Test {
    SmartBinancePlus public smartBinancePlus;
    DAI public dai;

    SmartBinancePlus.Plan Binary = Binary;
    SmartBinancePlus.Plan InOrder = SmartBinancePlus.Plan.InOrder;

    address daiHolder = address(100);
    address owner = address(101);
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
        smartBinancePlus = new SmartBinancePlus(address(this), address(dai), owner);
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
        registerUser(user1, Binary, owner);
    }

    function test_registerReverts() public {
        fundDai(user1, 10000 ether);
        vm.startPrank(user1);
        vm.expectRevert("Referrer is not active");
        smartBinancePlus.register(Binary, user2);

        smartBinancePlus.register(Binary, owner);

        vm.expectRevert("User is already active");
        smartBinancePlus.register(Binary, owner);

        vm.expectRevert("User is already active");
        smartBinancePlus.register(Binary, user1);
        vm.stopPrank();
    }

    function test_registerBinary() public {
        registerUser(user1, Binary, owner);

        SmartBinancePlus.User memory uplineInfo = smartBinancePlus.getUser(owner);
        SmartBinancePlus.User memory userInfo = smartBinancePlus.getUser(user1);

        assertEq(userInfo.referrer, owner);
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
        registerUser(user1, Binary, owner);
        assertEq(smartBinancePlus.getUser(owner).balancePoints, 0);
        registerUser(user2, Binary, owner);
        assertEq(smartBinancePlus.getUser(owner).balancePoints, 1);
        registerUser(user3, Binary, user1);
        assertEq(smartBinancePlus.getUser(owner).balancePoints, 1);
        assertEq(smartBinancePlus.getUser(user1).balancePoints, 0);
        registerUser(user4, Binary, user1);
        assertEq(smartBinancePlus.getUser(owner).balancePoints, 1);
        assertEq(smartBinancePlus.getUser(user1).balancePoints, 1);
        registerUser(user5, Binary, user2);
        assertEq(smartBinancePlus.getUser(owner).balancePoints, 2);
        assertEq(smartBinancePlus.getUser(user2).balancePoints, 0);
        registerUser(user6, Binary, user2);
        assertEq(smartBinancePlus.getUser(owner).balancePoints, 3);
        assertEq(smartBinancePlus.getUser(user2).balancePoints, 1);

        assertEq(smartBinancePlus.totalCyclePoints(), 5);
        assertEq(smartBinancePlus.getPointWorth(), 6 * 90 ether / 5);
    }

    function test_claimingRewards() public {
        registerUser(user1, Binary, owner);
        assertEq(smartBinancePlus.getUser(owner).balancePoints, 0);
        registerUser(user2, Binary, owner);
        assertEq(smartBinancePlus.getUser(owner).balancePoints, 1);
        registerUser(user3, Binary, user1);
        assertEq(smartBinancePlus.getUser(owner).balancePoints, 1);
        assertEq(smartBinancePlus.getUser(user1).balancePoints, 0);
        registerUser(user4, Binary, user1);
        assertEq(smartBinancePlus.getUser(owner).balancePoints, 1);
        assertEq(smartBinancePlus.getUser(user1).balancePoints, 1);
        registerUser(user5, Binary, user2);
        assertEq(smartBinancePlus.getUser(owner).balancePoints, 2);
        assertEq(smartBinancePlus.getUser(user2).balancePoints, 0);
        registerUser(user6, Binary, user2);
        assertEq(smartBinancePlus.getUser(owner).balancePoints, 3);
        assertEq(smartBinancePlus.getUser(user2).balancePoints, 1);

        assertEq(smartBinancePlus.totalCyclePoints(), 5);
        uint256 pointWorth = 6 * 90 ether / 5;
        assertEq(smartBinancePlus.getPointWorth(), pointWorth);

        uint256 bal1Contract = dai.balanceOf(address(smartBinancePlus));
        uint256 bal1owner = dai.balanceOf(owner);
        uint256 bal1user1 = dai.balanceOf(user1);
        uint256 bal1user2 = dai.balanceOf(user2);
        uint256 bal1user3 = dai.balanceOf(user3);
        uint256 bal1user4 = dai.balanceOf(user4);
        uint256 bal1user5 = dai.balanceOf(user5);
        uint256 bal1user6 = dai.balanceOf(user6);
        vm.warp(2 hours);
        smartBinancePlus.distributeRewards();

        uint256 bal2Contract = dai.balanceOf(address(smartBinancePlus));
        uint256 bal2owner = dai.balanceOf(owner);
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
}
