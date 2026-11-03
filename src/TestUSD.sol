// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TestUSD is ERC20 {
    constructor() ERC20("TestUSD", "TUSD") {
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}