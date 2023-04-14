// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
contract MockERC721 is ERC721Upgradeable{

    function initialize(string memory name, string memory symbol) public initializer {
        __ERC721_init(name, symbol);
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
    
}
