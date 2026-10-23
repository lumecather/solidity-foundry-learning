// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract Drop {

    uint256 public immutable mintPrice;

    uint256 public immutable maxSupply;

    address public immutable owner;

    constructor(uint256 price, uint256 supply) {
        mintPrice = price;
        owner = msg.sender;
        maxSupply = supply;
    }

    bool public revealed = false;

    uint256 public totalSupply;

    string public baseURI = "notrevealedyet";

    uint256 public constant MAX_PER_WALLET = 3;

    mapping(uint256 => address) public tokenOwners;

    mapping(address => uint256) public minted;

    error LimitReached(address user);

    error NotEnoughFundsReceived(uint256 funds);

    event Minted(address indexed user, uint256 id);

    error TransferFailed();

    error NotOwner();

    error TokenDoesNotExist();

    error AlreadyRevealed();

    error MaxSupplyReached();
    
    function mint() external payable {

        if (totalSupply >= maxSupply) revert MaxSupplyReached();
        
        uint256 amountReceived = msg.value;

        if (amountReceived < mintPrice) revert NotEnoughFundsReceived(amountReceived);

        uint256 current = minted[msg.sender];
        if (current >= MAX_PER_WALLET) revert LimitReached(msg.sender);

        uint256 newTotal = current + 1;
        minted[msg.sender] = newTotal;
        tokenOwners[totalSupply] = msg.sender;
        totalSupply++;
        emit Minted(msg.sender, totalSupply - 1);

        if (amountReceived > mintPrice) {
            (bool success, ) = msg.sender.call{value: amountReceived - mintPrice}("");
            if (!success) revert TransferFailed();
        }      
    }

    function withdraw() external {
        if (msg.sender != owner) revert NotOwner();
        
        (bool success, ) = owner.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    function reveal(string calldata newURI) external {
        if (msg.sender != owner) revert NotOwner();
        if (revealed) revert AlreadyRevealed();
        revealed = true;
        
        baseURI = newURI;
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        if (tokenOwners[id] == address(0)) revert TokenDoesNotExist();

        if (!revealed) return baseURI;

        return string.concat(baseURI, Strings.toString(id), ".json");
}

}
