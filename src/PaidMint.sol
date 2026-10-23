// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


contract PaidMint {

    uint256 public immutable mintPrice;

    address public immutable owner;

    constructor(uint256 price) {
        mintPrice = price;
        owner = msg.sender;
    }

    uint256 public constant MAX_PER_WALLET = 3;

    mapping(address => uint256) public minted;

    error LimitReached(address user);

    error NotEnoughtFundsReceived(uint256 funds);

    event Minted(address indexed user, uint256 total);

    error TransferFailed();

    error NotOwner();
    
    function mint() external payable {
        
        uint256 amountReceived = msg.value;

        if (amountReceived < mintPrice) revert NotEnoughtFundsReceived(amountReceived);

        uint256 current = minted[msg.sender];
        if (current >= MAX_PER_WALLET) revert LimitReached(msg.sender);
        uint256 newTotal = current + 1;
        minted[msg.sender] = newTotal;

        emit Minted(msg.sender, newTotal);

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

}
