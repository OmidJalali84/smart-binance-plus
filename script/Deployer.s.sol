// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../src/SmartBinancePlus.sol";

contract Deploy is Script {
    address[] tokens;

    function run() external {
        // 1. Start broadcasting transactions
        vm.startBroadcast();

        new SmartBinancePlus(
            0x6Ac97c57138BD707680A10A798bAf24aCe62Ae9D,
            0x81878429C68350DdB41Aaaf05cF2f03bf37e72D5,
            0x320f0Ed6Fc42b0857e2b598B5DA85103203cf5d3,
            0x2F9CCd7955513fB47540eC62d3Aa8FF4EaE3101A
        );

        // 3. Stop broadcasting
        vm.stopBroadcast();
    }
}
