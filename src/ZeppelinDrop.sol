// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract ZeppelinDrop is ERC721, EIP712 {
    uint256 public constant MAX_PER_WALLET = 3;


    uint256 public immutable mintPrice;
    uint256 public immutable maxSupply;
    address public immutable owner;
    address public signer;

    uint256 public totalSupply;
    bool public revealed;
    string public baseURI = "notrevealedyet";

    mapping(address => uint256) public minted;

    bytes32 constant MINT_TYPEHASH = keccak256("Mint(address to,uint256 deadline)");

    bytes32 public merkleRoot;                    // корень дерева
    mapping(address => bool) public allowlistClaimed; // кто уже минтил по allowlist

    mapping(address => bool) public signatureClaimed;
    error Expired();
    error BadSignature();

    error NotInAllowlist();
    error AlreadyClaimed();

    error LimitReached(address user);
    error NotEnoughFundsReceived(uint256 funds);
    error TransferFailed();
    error NotOwner();
    error AlreadyRevealed();
    error MaxSupplyReached();

    constructor(uint256 price, uint256 supply) ERC721("Zeppelin Drop", "ZDROP") EIP712("MyToken", "1") {
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

    function signatureMint(uint256 deadline, bytes calldata signature) external payable {

        if (block.timestamp > deadline) revert Expired();

        if (signatureClaimed[msg.sender]) revert AlreadyClaimed();

        address who = ECDSA.recover(mintDigest(msg.sender, deadline), signature);

        if (who != signer) revert BadSignature();

        signatureClaimed[msg.sender] = true;

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


    function setSigner(address signerr) external {
        if (msg.sender != owner) revert NotOwner();
        signer = signerr;
    }

    function mintDigest(address to, uint256 deadline) public view returns (bytes32 digest) {
        return(_hashTypedDataV4(keccak256(abi.encode(MINT_TYPEHASH, to, deadline))));
    }
    
}