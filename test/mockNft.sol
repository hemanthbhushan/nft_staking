// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract mockNft is ERC721 {
    constructor()
        ERC721("mockNft", "mockNft")
    {}

    function safeMint(address to, uint256 tokenId) public  {
        _safeMint(to, tokenId);
    }
}
