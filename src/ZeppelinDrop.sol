// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

contract ZeppelinDrop is ERC721 {
    uint256 public constant MAX_PER_WALLET = 3;


    uint256 public immutable mintPrice;
    uint256 public immutable maxSupply;
    address public immutable owner;

    uint256 public totalSupply;
    bool public revealed;
    string public baseURI = "notrevealedyet";

    mapping(address => uint256) public minted;

    bytes32 public merkleRoot;                    // корень дерева
    mapping(address => bool) public allowlistClaimed; // кто уже минтил по allowlist

    error NotInAllowlist();
    error AlreadyClaimed();

    error LimitReached(address user);
    error NotEnoughFundsReceived(uint256 funds);
    error TransferFailed();
    error NotOwner();
    error AlreadyRevealed();
    error MaxSupplyReached();

    constructor(uint256 price, uint256 supply) ERC721("Zeppelin Drop", "ZDROP") {
        mintPrice = price;
        maxSupply = supply;
        owner = msg.sender;
    }

    function _mintOne() internal {
        uint256 id = totalSupply;
        if (id >= maxSupply) revert MaxSupplyReached();
        if (msg.value < mintPrice) revert NotEnoughFundsReceived(msg.value);

        uint256 current = minted[msg.sender];
        if (current >= MAX_PER_WALLET) revert LimitReached(msg.sender);

        minted[msg.sender] = current + 1;
        totalSupply = id + 1;

        _safeMint(msg.sender, id);

        if (msg.value > mintPrice) {
            (bool success, ) = msg.sender.call{value: msg.value - mintPrice}("");
            if (!success) revert TransferFailed();
        }
    }

    function mint() external payable {
        _mintOne();
    }

    function allowlistMint(bytes32[] calldata proof) external payable {
        if (allowlistClaimed[msg.sender]) revert AlreadyClaimed();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool mproof = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!mproof) revert NotInAllowlist();
        allowlistClaimed[msg.sender] = true;
        _mintOne();
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

    function tokenURI(uint256 id) public view override returns (string memory) {
        _requireOwned(id);
        if (!revealed) return baseURI;
        return string.concat(baseURI, Strings.toString(id), ".json");
    }

    function setMerkleRoot(bytes32 root) external {
        if (msg.sender != owner) revert NotOwner();
        merkleRoot = root;
    }

    
}