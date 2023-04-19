// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
contract MockERC721 is ERC721EnumerableUpgradeable{
    uint256 public supply;
    
    function initialize(string memory name, string memory symbol) public initializer {
        __ERC721_init(name, symbol);
    }
    
    function mint(address to, uint256 tokenAmount) public {
        for(uint256 i = 0; i < tokenAmount; i++) {
            supply++;
            _mint(to, supply);
        }
    }
    
}
