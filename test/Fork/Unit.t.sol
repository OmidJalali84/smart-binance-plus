// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SmartBinancePlus, DrCat} from "../../src/SmartBinancePlus.sol";

interface IBinancePlus {
    function register(SmartBinancePlus.Plan plan, address referrer) external;
    function fetchAllUsers() external view returns (SmartBinancePlus.User[] memory);
    function getUser(address user) external view returns (SmartBinancePlus.User memory);
    function allUsers() external view returns (address[] memory);
    function ROOT() external view returns (address);
    function drCat() external view returns (DrCat);
}

contract Unit is Test {
    IBinancePlus public smartBinancePlus;
    IERC20 public dai;

    function setUp() public {
        dai = IERC20(0x320f0Ed6Fc42b0857e2b598B5DA85103203cf5d3);
        smartBinancePlus = IBinancePlus(0x6816e01315B129efd79CF66318F50233E5c2Fa49);
    }

    function test_forkRegisterUser() public {
        vm.startPrank(0x66A0d45e9D07dC6DD7089498bD2B291A9075e883);
        console.log(address(smartBinancePlus.drCat()));
        // smartBinancePlus.register(SmartBinancePlus.Plan.InOrder, 0xdaa646493D2F7d8fdb111E4366A57728A4e1cAb4);
        vm.stopPrank();
    }
}
