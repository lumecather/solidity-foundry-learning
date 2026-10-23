// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract MintLimiter {
    uint256 public constant MAX_PER_WALLET = 3;

    mapping(address => uint256) public minted;

    error LimitReached(address user);

    event Minted(address indexed user, uint256 total);
    
    function mint()  external {

        uint256 current = minted[msg.sender];
        if (current >= MAX_PER_WALLET) revert LimitReached(msg.sender);
        uint256 newTotal = current + 1;
        minted[msg.sender] = newTotal;
        emit Minted(msg.sender, newTotal);
        
    }

}