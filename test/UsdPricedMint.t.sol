// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {UsdPricedMint} from "../src/UsdPricedMint.sol";

contract UsdPricedMintTest is Test {
    UsdPricedMint drop;
    address alice = makeAddr("alice");

    function setUp() public {
        vm.createSelectFork("mainnet", 19_000_000);
        drop = new UsdPricedMint(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        deal(alice, 1 ether);
    }

    function test_mint() public {
        uint256 need = drop.requiredWei();
        vm.prank(alice);
        drop.mint{value: need}();
        assertEq(drop.ownerOf(0), alice);
    }

    function test_mint2() public {
        uint256 need = drop.requiredWei();
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(UsdPricedMint.NotEnoughFundsReceived.selector, need - 1));
        drop.mint{value: need - 1}();
    }

    function test_mint3() public {
        uint256 need = drop.requiredWei();
        vm.warp(block.timestamp + 4 hours);
        vm.prank(alice);
        vm.expectRevert(UsdPricedMint.StalePrice.selector);
        drop.mint{value: need}();
    }
}