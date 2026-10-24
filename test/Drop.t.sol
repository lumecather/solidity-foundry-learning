// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Drop} from "../src/Drop.sol";

contract DropTest is Test {
    Drop public drop;

    uint256 constant PRICE = 0.01 ether;

    address alice = makeAddr("alice");
    
    uint256 constant SUPPLY = 10;

    function setUp() public {
        drop = new Drop(PRICE, SUPPLY);
        deal(alice, 1 ether);
    }

    function test_TokenURI_BeforeReveal_SameForAll() public {
        drop.mint{value: PRICE}();
        drop.mint{value: PRICE}();

        assertEq(drop.tokenURI(0), drop.tokenURI(1));
    }

    function test_TokenURI_AfterReveal() public {
        drop.mint{value: PRICE}();
        drop.mint{value: PRICE}();

        drop.reveal("ipfs://abc/");

        assertEq(drop.tokenURI(0), "ipfs://abc/0.json");
        assertEq(drop.tokenURI(1), "ipfs://abc/1.json");
    }

    function test_Reverts_MaxSupply_And_AlreadyRevealed() public {
        Drop small = new Drop(PRICE, 2);

        small.mint{value: PRICE}();
        small.mint{value: PRICE}();

        vm.expectRevert(Drop.MaxSupplyReached.selector);
        small.mint{value: PRICE}();

        small.reveal("ipfs://abc/");

        vm.expectRevert(Drop.AlreadyRevealed.selector);
        small.reveal("ipfs://xyz/");
    }

    function test_RevealNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(Drop.NotOwner.selector);
        drop.reveal("ipfs://abc/");
        vm.prank(alice);
        vm.expectRevert(Drop.NotOwner.selector);
        drop.withdraw();

    }

}
