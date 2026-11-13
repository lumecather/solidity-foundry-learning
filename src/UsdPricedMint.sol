// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
interface AggregatorV3Interface {
        function latestRoundData() external view returns (
            uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    }

contract UsdPricedMint is Ownable, ERC721, ERC2981 {
    uint256 public totalSupply;

    AggregatorV3Interface public immutable feed;
    uint256 public constant USD_PRICE = 20e8;
    uint256 public constant MAX_DELAY = 3 hours; 

    error StalePrice();
    error BadPrice();
    

    error TransferFailed();
    error NotEnoughFundsReceived(uint256 funds);

    constructor(address _feed) Ownable(msg.sender) ERC721("Drop", "DRP") {
        _setDefaultRoyalty(msg.sender, 500);
        feed = AggregatorV3Interface(_feed);
    }

    function requiredWei() public view returns (uint256) {
        (, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();

        if (answer <= 0) revert BadPrice();

        if (block.timestamp - updatedAt > MAX_DELAY) revert StalePrice();

        return USD_PRICE * 1e18 / uint256(answer);
    }

    function mint() external payable {
        if (msg.value < requiredWei()) revert NotEnoughFundsReceived(msg.value);
        uint256 id = totalSupply;
        totalSupply = id + 1;
        _safeMint(msg.sender, id);
    }

    function withdraw() onlyOwner external {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }
    
    function supportsInterface(bytes4 id) public view override(ERC721, ERC2981) returns (bool) {
      return super.supportsInterface(id);
    }
}