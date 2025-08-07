// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SmartBinancePlus} from "../../src/SmartBinancePlus.sol";

interface IBinancePlus {
    function register(uint256 plan, address referrer) external;
    function fetchAllUsers() external view returns (SmartBinancePlus.User[] memory);
    function getUser(address user) external view returns (SmartBinancePlus.User memory);
    function allUsers() external view returns (address[] memory);
    function ROOT() external view returns (address);
}

contract Unit is Test {
    IBinancePlus public smartBinancePlus;
    IERC20 public dai;

    function setUp() public {
        dai = IERC20(0x320f0Ed6Fc42b0857e2b598B5DA85103203cf5d3);
        smartBinancePlus = IBinancePlus(0x875252976F071b6dF4A55408FCf21C3820caCD7B);
    }

    function test_forkRegisterUser() public {
        vm.startPrank(0x1448E471fc4E92f829aEE11Af18b58d6aDb6046D);
        // smartBinancePlus.register(0, 0xcc2262f2208E742374Df872D3969D151b294b238);
        console.log(smartBinancePlus.ROOT());
        vm.stopPrank();
    }
}
