// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MintLimiter} from "../src/MintLimiter.sol";


contract MintLimiterTest is Test {
    MintLimiter public limiter;

    function setUp() public {
        limiter = new MintLimiter();
    }

    function test_ThreeMintsSucceed() public {
        limiter.mint();
        limiter.mint();
        limiter.mint();
        assertEq(limiter.minted(address(this)), 3);
    }

    function test_FourthMintReverts()  public {

        limiter.mint();
        limiter.mint();
        limiter.mint();
        assertEq(limiter.minted(address(this)), 3);
        vm.expectRevert(abi.encodeWithSelector(MintLimiter.LimitReached.selector, address(this)));
        limiter.mint();
        
    }

    function test_LimitIsPerAddress()  public {
        limiter.mint();
        limiter.mint();
        limiter.mint();
        assertEq(limiter.minted(address(this)), 3);
        address alice = makeAddr("alice");
        vm.prank(alice);
        limiter.mint();
        assertEq(limiter.minted(alice), 1);
        assertEq(limiter.minted(address(this)), 3);
    }

    function test_MintEmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit MintLimiter.Minted(address(this), 1);
        limiter.mint();
    }
}