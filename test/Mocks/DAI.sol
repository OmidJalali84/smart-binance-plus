// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DAI is ERC20 {
    constructor(address receiver, uint256 amount) ERC20("DAI", "DAI") {
        _mint(receiver, amount);
    }
}
