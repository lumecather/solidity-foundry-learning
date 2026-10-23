// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NFTRegistry {

    struct Token {
        address owner;
        bool isRevealed;
    }

    Token[] public tokens;
    mapping(uint256 => string) public tokenURIs;

    event TokenCreated(uint256 indexed tokenId, address indexed owner);

    error TokenDoesNotExist(uint256 tokenId);
    error NotYourToken(uint256 tokenId);

    // Проверяет только, что токен существует
    modifier tokenExists(uint256 tokenId) {
        if (tokenId >= tokens.length) revert TokenDoesNotExist(tokenId);
        _;
    }

    // Проверяет, что токен существует И msg.sender его владелец
    modifier onlyTokenOwner(uint256 tokenId) {
        if (tokenId >= tokens.length) revert TokenDoesNotExist(tokenId);
        if (tokens[tokenId].owner != msg.sender) revert NotYourToken(tokenId);
        _;
    }

    function mint() external returns (uint256 tokenId) {
        tokenId = tokens.length;
        tokens.push(Token({owner: msg.sender, isRevealed: false}));
        emit TokenCreated(tokenId, msg.sender);
    }

    // Демо бага: меняется копия в memory, в блокчейн ничего не пишется
    function revealBroken(uint256 tokenId) external tokenExists(tokenId) {
        Token memory tokenCopy = tokens[tokenId];
        tokenCopy.isRevealed = true;
    }

    // Правильно: ссылка на storage. Раскрывать должен владелец
    function revealFixed(uint256 tokenId) external onlyTokenOwner(tokenId) {
        tokens[tokenId].isRevealed = true;
    }

    function setUriCalldata(uint256 tokenId, string calldata _uri)
        external
        onlyTokenOwner(tokenId)
    {
        tokenURIs[tokenId] = _uri;
    }

    function setUriMemory(uint256 tokenId, string memory _uri)
        external
        onlyTokenOwner(tokenId)
    {
        tokenURIs[tokenId] = _uri;
    }

    function totalTokens() external view returns (uint256) {
        return tokens.length;
    }
}