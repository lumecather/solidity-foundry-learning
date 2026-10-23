// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {NFTRegistry} from "../src/Registry.sol";
import {console} from "forge-std/console.sol";


contract NFTRegistryTest is Test {
    NFTRegistry public registry;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    string constant LONG = "ipfs://QmSomeVeryLongCidForTheMetadataFolder1234567890/0.json";

    function setUp() public {
        registry = new NFTRegistry();
        registry.mint(); // токен 0, владелец address(this)
    }

    // ==========================================
    // MINT
    // ==========================================

    function test_Mint_SetsOwnerAndNotRevealed() public view {
        (address owner, bool isRevealed) = registry.tokens(0);
        assertEq(owner, address(this));
        assertFalse(isRevealed);
        assertEq(registry.totalTokens(), 1);
    }

    function test_Mint_EmitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit NFTRegistry.TokenCreated(1, alice);
        vm.prank(alice);
        registry.mint();
    }

    function test_MintFromDifferentAddresses_OwnersCorrect() public {
        vm.prank(alice);
        uint256 aliceId = registry.mint();
        vm.prank(bob);
        uint256 bobId = registry.mint();

        assertEq(aliceId, 1);
        assertEq(bobId, 2);

        (address owner0,) = registry.tokens(0);
        (address owner1,) = registry.tokens(aliceId);
        (address owner2,) = registry.tokens(bobId);
        assertEq(owner0, address(this));
        assertEq(owner1, alice);
        assertEq(owner2, bob);
        assertEq(registry.totalTokens(), 3);
    }

    // ==========================================
    // REVEAL
    // ==========================================

    function test_RevealBroken_DoesNotChangeStorage() public {
        registry.revealBroken(0);
        (, bool isRevealed) = registry.tokens(0);
        assertFalse(isRevealed); // изменилась только копия в memory
    }

    function test_RevealBroken_RevertsForMissingToken() public {
        vm.expectRevert(abi.encodeWithSelector(NFTRegistry.TokenDoesNotExist.selector, 999));
        registry.revealBroken(999);
    }

    function test_RevealFixed_ChangesStorage() public {
        registry.revealFixed(0);
        (, bool isRevealed) = registry.tokens(0);
        assertTrue(isRevealed);
    }

    function test_RevealFixed_RevertsForNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(NFTRegistry.NotYourToken.selector, 0));
        registry.revealFixed(0);
    }

    function test_RevealFixed_RevertsForMissingToken() public {
        vm.expectRevert(abi.encodeWithSelector(NFTRegistry.TokenDoesNotExist.selector, 999));
        registry.revealFixed(999);
    }

    // ==========================================
    // SET URI
    // ==========================================

    function test_SetUriCalldata_ByOwner() public {
        registry.setUriCalldata(0, "ipfs://abc");
        assertEq(registry.tokenURIs(0), "ipfs://abc");
    }

    function test_SetUriMemory_ByOwner() public {
        registry.setUriMemory(0, "ipfs://xyz");
        assertEq(registry.tokenURIs(0), "ipfs://xyz");
    }

    function test_SetUriCalldata_RevertsForNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(NFTRegistry.NotYourToken.selector, 0));
        registry.setUriCalldata(0, "ipfs://evil");
    }

    function test_SetUriMemory_RevertsForNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(NFTRegistry.NotYourToken.selector, 0));
        registry.setUriMemory(0, "ipfs://evil");
    }

    function test_SetUriCalldata_RevertsForMissingToken() public {
        vm.expectRevert(abi.encodeWithSelector(NFTRegistry.TokenDoesNotExist.selector, 999));
        registry.setUriCalldata(999, "ipfs://abc");
    }

    function test_SetUriMemory_RevertsForMissingToken() public {
        vm.expectRevert(abi.encodeWithSelector(NFTRegistry.TokenDoesNotExist.selector, 999));
        registry.setUriMemory(999, "ipfs://abc");
    }

    // ==========================================
    // FUZZ
    // ==========================================

    // Любой адрес, кроме владельца, не может менять токен 0
    function testFuzz_NotOwnerCannotSetUri(address caller) public {
        vm.assume(caller != address(this));
        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSelector(NFTRegistry.NotYourToken.selector, 0));
        registry.setUriCalldata(0, "ipfs://evil");
    }

    // Любой tokenId >= totalTokens даёт TokenDoesNotExist
    function testFuzz_MissingTokenReverts(uint256 tokenId) public {
        vm.assume(tokenId >= registry.totalTokens());
        vm.expectRevert(abi.encodeWithSelector(NFTRegistry.TokenDoesNotExist.selector, tokenId));
        registry.revealFixed(tokenId);
    }

    function test_Gas_SetUriCalldata() public {
        uint256 before = gasleft();
        registry.setUriCalldata(0, LONG);
        console.log("calldata gas:", before - gasleft());
    }

    function test_Gas_SetUriMemory() public {
        uint256 before = gasleft();
        registry.setUriMemory(0, LONG);
        console.log("memory gas:", before - gasleft());
    }
}