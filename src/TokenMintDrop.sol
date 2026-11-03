// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";

contract TokenMintDrop is Ownable, ERC721, ERC2981 {

    using SafeERC20 for IERC20;

    IERC20 public immutable payToken;    // каким токеном платят
    uint256 public immutable price;      // сколько стоит один NFT (в единицах токена)
    uint256 public totalSupply;

    constructor(IERC20 token, uint256 _price) Ownable(msg.sender) ERC721("TokenMintDrop", "TMD") {
        _setDefaultRoyalty(msg.sender, 500); 
        payToken = token;
        price = _price;
    }

    function mint() external {
        payToken.safeTransferFrom(msg.sender, address(this), price);
        uint256 id = totalSupply;
        totalSupply = id + 1;
        _safeMint(msg.sender, id);
    }

    function withdraw() onlyOwner external {
        uint256 bal = payToken.balanceOf(address(this));
        payToken.safeTransfer(owner(), bal);
    }
    
    function supportsInterface(bytes4 id) public view override(ERC721, ERC2981) returns (bool) {
      return super.supportsInterface(id);
    }
}