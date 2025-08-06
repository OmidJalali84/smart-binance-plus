// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

uint256 constant TOTAL_SUPPLY = 500_000_000e18;

contract DrCat is ERC20 {
    constructor(address _owner) ERC20("Dr. Cat", "CAT") {
        _mint(address(this), TOTAL_SUPPLY);
        _approve(address(this), _owner, 1e50);
        _approve(address(this), msg.sender, 1e50);
    }
}
