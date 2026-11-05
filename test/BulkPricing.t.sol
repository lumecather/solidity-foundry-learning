// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {BulkPricing} from "../src/BulkPricing.sol";

contract BulkPricingTest is Test {
    BulkPricing bp;

    function setUp() public {
        bp = new BulkPricing();
    }

    function testFuzz_price(uint256 qty) public view {
        qty = bound(qty, 1, 1000);

        uint256 p = bp.price(qty);
        uint256 full = qty * bp.BASE();

        assertLe(p, full);
    }

    function testFuzz_price2(uint256 qty) public view {
        qty = bound(qty, 1, 1000);

        uint256 p1 = bp.price(qty);
        uint256 p2 = bp.price(qty + 1);

        assertLe(p1, p2);
    }
}