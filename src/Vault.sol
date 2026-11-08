// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Vault {
    mapping(address => uint256) public balances;

    error Insufficient();
    error TransferFailed();

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        if (balances[msg.sender] < amount) revert Insufficient();
        balances[msg.sender] -= amount;
        (bool ok, ) = msg.sender.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }

    function transfer(address to, uint256 amount) external {
        uint256 fromBal = balances[msg.sender];
        if (fromBal < amount) revert Insufficient();
        balances[msg.sender] = fromBal - amount;
        uint256 toBal = balances[to];
        balances[to] = toBal + amount;
    }
}
