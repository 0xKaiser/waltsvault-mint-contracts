// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
contract TestToken300423 is ERC721EnumerableUpgradeable{
	uint256 public supply;
	uint256 public maxSupply;
	
	function initialize(string memory name, string memory symbol) public initializer {
		__ERC721_init(name, symbol);
		maxSupply = 20;
	}
	
	function mint(address to, uint256 tokenAmount) public {
		for(uint256 i = 0; i < tokenAmount; i++) {
			supply++;
			require(supply <= maxSupply, "Max supply reached");
			_mint(to, supply);
		}
	}
	
	function setMaxSupply(uint256 _maxSupply) public {
		maxSupply = _maxSupply;
	}
	
}
