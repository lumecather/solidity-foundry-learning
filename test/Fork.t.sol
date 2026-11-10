// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {TokenMintDrop} from "../src/TokenMintDrop.sol";
import "forge-std/console.sol";

interface IBAYC { function totalSupply() external view returns (uint256); }

contract ForkTest is Test {
    address constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 constant BLOCK = 19_000_000;   // январь 2024

    function setUp() public {
        vm.createSelectFork("mainnet", BLOCK);
    }

    function test_ReadBAYC() public view {
        uint256 supply = IBAYC(BAYC).totalSupply();
        address owner0 = IERC721(BAYC).ownerOf(0);

        assertEq(supply, 10_000);
        console.log("BAYC #0 owner:", owner0);
    }


    function test_DropWithRealUSDC() public {
        TokenMintDrop drop = new TokenMintDrop(IERC20(USDC), 10e6);
        address alice = makeAddr("alice");
        deal(USDC, alice, 100e6);
        vm.startPrank(alice);
        IERC20(USDC).approve(address(drop), 10e6);
        drop.mint();
        assertEq(drop.ownerOf(0), alice);
        assertEq(IERC20(USDC).balanceOf(address(drop)), 10e6);
        assertEq(IERC20(USDC).balanceOf(alice), 90e6);
    }

}