// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";

contract VaultHandler is Test {
    Vault vault;
    address[] public actors;

    constructor(Vault _vault) {
        vault = _vault;
        actors.push(makeAddr("a"));
        actors.push(makeAddr("b"));
        actors.push(makeAddr("c"));
    }

    function _actor(uint256 seed) internal view returns (address) {
        return actors[seed % actors.length];
    }

    function deposit(uint256 seed, uint256 amount) external {
        address a = _actor(seed);
        amount = bound(amount, 0, 10 ether);
        deal(a, amount);
        vm.prank(a);
        vault.deposit{value: amount}();
    }


    function withdraw(uint256 seed, uint256 amount) external {
        address a = _actor(seed);   
        uint256 maxBalance = vault.balances(a);
        amount = bound(amount, 0, maxBalance);
        vm.prank(a);
        vault.withdraw(amount);
    }

    function transfer(uint256 seed, uint256 toSeed, uint256 amount) external {
        address a = _actor(seed);
        address b = _actor(toSeed);
        uint256 maxBalance = vault.balances(a);
        amount = bound(amount, 0, maxBalance);
        vm.prank(a);
        vault.transfer(b, amount);
    }

    function sumBalances() external view returns (uint256 s) {
        for (uint256 i = 0; i < actors.length; i++) s += vault.balances(actors[i]);
    }
}

contract VaultInvariantTest is Test {
    Vault vault;
    VaultHandler handler;

    function setUp() public {
        vault = new Vault();
        handler = new VaultHandler(vault);
        targetContract(address(handler));
    }

    function invariant_test() public view {
        assertEq(handler.sumBalances(), address(vault).balance);
    }

}