// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaidMint} from "../src/PaidMint.sol";

contract PaidMintTest is Test {
    
    PaidMint public pmint;

    uint256 constant PRICE = 0.01 ether;

    address alice = makeAddr("alice");

    function setUp() public {
        pmint = new PaidMint(PRICE);
        deal(alice, 1 ether);
    }

    receive() external payable {}

    function test_PaidMint() public {
        vm.prank(alice);
        pmint.mint{value: 0.01 ether}();
        assertEq(pmint.minted(alice), 1);
        assertEq(address(pmint).balance, PRICE);
    }

    function test_PaidMintOverPrice() public {
        uint256 mintPrice = pmint.mintPrice(); 

        uint256 initialBalance = alice.balance;

        vm.prank(alice);
        pmint.mint{value: 1 ether}();
        assertEq(pmint.minted(alice), 1);

        uint256 expectedBalance = initialBalance - mintPrice;
        assertEq(alice.balance, expectedBalance);
        assertEq(address(pmint).balance, PRICE);
    } 


    function test_getmoney() public {
        vm.prank(alice);
        pmint.mint{value: 0.01 ether}();
        assertEq(pmint.minted(alice), 1);
        vm.expectRevert(abi.encodeWithSelector(PaidMint.NotOwner.selector));
        vm.prank(alice);
        pmint.withdraw();
        assertEq(address(pmint).balance, pmint.mintPrice());

        uint256 before = address(this).balance;

        pmint.withdraw();
        assertEq(address(pmint).balance, 0);
        assertEq(address(this).balance, before + PRICE);

    }


}