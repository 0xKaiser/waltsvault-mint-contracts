// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
contract MockERC721 is ERC721{
    uint256 public supply;
    
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}
    
    function mint(address to, uint256 tokenAmount) public {
        for(uint256 i = 0; i < tokenAmount; i++) {
            supply++;
            _mint(to, supply);
        }
    }
    
}
