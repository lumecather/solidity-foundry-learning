// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract BulkPricing {
    uint256 public constant BASE = 0.01 ether;

    function price(uint256 qty) public pure returns (uint256) {
        if (qty >= 10) return (qty - 9) * BASE * 80 / 100 + 4 * BASE + 5 * BASE * 90 / 100;
        if (qty >= 5) return (qty - 4) * BASE * 90 / 100 + 4 * BASE;
        return qty * BASE;
    }
}