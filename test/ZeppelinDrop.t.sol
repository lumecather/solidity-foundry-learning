// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ZeppelinDrop} from "../src/ZeppelinDrop.sol";

contract ZeppelinDropTest is Test {
    ZeppelinDrop public drop;

    uint256 constant PRICE = 0.01 ether;

    address alice = makeAddr("alice");
    
    uint256 constant SUPPLY = 10;

    function setUp() public {
        drop = new ZeppelinDrop(PRICE, SUPPLY);
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
        ZeppelinDrop small = new ZeppelinDrop(PRICE, 2);

        small.mint{value: PRICE}();
        small.mint{value: PRICE}();

        vm.expectRevert(ZeppelinDrop.MaxSupplyReached.selector);
        small.mint{value: PRICE}();

        small.reveal("ipfs://abc/");

        vm.expectRevert(ZeppelinDrop.AlreadyRevealed.selector);
        small.reveal("ipfs://xyz/");
    }

    function test_RevealNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(ZeppelinDrop.NotOwner.selector);
        drop.reveal("ipfs://abc/");
        vm.prank(alice);
        vm.expectRevert(ZeppelinDrop.NotOwner.selector);
        drop.withdraw();

    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }


    function test_Safetransfer() public {
        drop.mint{value: PRICE}();
        drop.safeTransferFrom(address(this), alice, 0);
        assertEq(drop.ownerOf(0), alice);
    }


}
