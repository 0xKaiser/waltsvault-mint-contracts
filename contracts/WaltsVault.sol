// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721AUpgradeable} from "./utils/ERC721AUpgradeable.sol";
import {RevokableOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableOperatorFiltererUpgradeable.sol";
import {RevokableDefaultOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableDefaultOperatorFiltererUpgradeable.sol";
import {RaritySigner} from "./utils/RaritySigner.sol";
import {IMerkel} from "./Interfaces/IMerkel.sol";

contract WaltsVault is
    OwnableUpgradeable,
    ERC721AUpgradeable,
    RaritySigner,
    RevokableDefaultOperatorFiltererUpgradeable
{
    
    string public baseURI;
    uint256 public maxSupply;
    
    mapping(address => bool) public isController;
   
    modifier onlyController(address from) {
        require(isController[from], "Not a Controller");
        _;
    }
    
    function initialize(string memory name, string memory symbol) external
    initializer {
        __Ownable_init();
        __ERC721A_init(name,symbol);
        __RevokableDefaultOperatorFilterer_init();
        __Signer_init();
        maxSupply = 8888;
    }
    
    function airdrop(
        address[] calldata to, 
        uint256[] calldata amount
    ) external onlyController(msg.sender) {
        require(to.length == amount.length, "Invalid Input");
        
        for(uint256 i = 0; i < to.length; i++) {
            require(maxSupply >= totalSupply() + amount[i]);
            _mint(to[i],amount[i]);
        }
    }
    
    // Contract Setters
    
    function toggleController(address controller) public onlyOwner {
        isController[controller] = !isController[controller];
    }
    
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(bytes(newBaseURI).length > 0);
        baseURI = newBaseURI;
    }
    
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }
    
    // OpenSea Operator Filterer
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
    
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
    
    function owner()
        public
        view
        override (OwnableUpgradeable, RevokableOperatorFiltererUpgradeable)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
