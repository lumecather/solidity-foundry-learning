// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {TokenMintDrop} from "../src/TokenMintDrop.sol";
import {TestUSD} from "../src/TestUSD.sol";

contract TokenMintDropTest is Test {
    TestUSD usd;
    TokenMintDrop drop;
    address alice = makeAddr("alice");
    uint256 constant PRICE = 10e18;

    function setUp() public {
        usd = new TestUSD();
        drop = new TokenMintDrop(usd, PRICE);
        usd.mint(alice, 100e18);
    }

    function test_Mint() public {
        vm.startPrank(alice);
        usd.approve(address(drop), PRICE);
        drop.mint();
        assertEq(drop.ownerOf(0), alice);
        assertEq(usd.balanceOf(address(drop)), PRICE);
        assertEq(usd.balanceOf(alice), 90e18);
    }


    function test_MintWitchoutApprove() public {
        vm.startPrank(alice);
        vm.expectRevert();
        drop.mint();
    }

    function test_withdraw() public {
        vm.startPrank(alice);
        usd.approve(address(drop), PRICE);
        drop.mint();
        vm.stopPrank();
        assertEq(usd.balanceOf(address(drop)), PRICE);
        drop.withdraw();
        assertEq(usd.balanceOf(address(drop)), 0);
        assertEq(usd.balanceOf(address(this)), PRICE);
    }
}