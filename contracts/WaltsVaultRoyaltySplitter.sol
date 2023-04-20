// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "hardhat/console.sol";

contract WaltsVaultFundsSplitter is OwnableUpgradeable{
    
    IERC721EnumerableUpgradeable public nft;
    IERC20Upgradeable public weth;
    
    event FundsReleased(address to, uint256 indexed ethAmount, uint256 indexed wethAmount);
    event FundsReceived(address from, uint256 amount);
    
    uint256 public creatorPercentage;
    uint256 public nftHolderPercentage;
    uint256 public ETH_FUNDS_STORED_FOR_CREATOR;
    uint256 public ETH_FUNDS_STORED_FOR_HOLDERS;
    uint256 public WETH_FUNDS_STORED_FOR_CREATOR;
    uint256 public WETH_FUNDS_STORED_FOR_HOLDERS;
    uint256 public TOTAL_ETH_FUNDS_RELEASED;
    uint256 public TOTAL_WETH_FUNDS_RELEASED;
    uint256 public TOTAL_ETH_RELEASED_TO_CREATOR;
    uint256 public TOTAL_WETH_RELEASED_TO_CREATOR;
    
    uint256 public ETHBalanceState;
    uint256 public WETHBalanceState;
    
    mapping (uint256 => uint256) public ETHFundsReleasedPerToken;
    mapping (uint256 => uint256) public WETHFundsReleasedPerToken;
    
    // This modifier updates the funds stored for the creator and the holders
    modifier updateStoredFunds() {
        uint256 fundsReceived = address(this).balance;
            uint256 value = fundsReceived - ETHBalanceState;
            ETH_FUNDS_STORED_FOR_CREATOR += value * creatorPercentage / 100;
            ETH_FUNDS_STORED_FOR_HOLDERS += value * nftHolderPercentage / 100;
        
        
        fundsReceived = weth.balanceOf(address(this));
            value = fundsReceived - WETHBalanceState;
            WETH_FUNDS_STORED_FOR_CREATOR += value * creatorPercentage / 100;
            WETH_FUNDS_STORED_FOR_HOLDERS += value * nftHolderPercentage / 100;
        
        _;
    }
    
    function initialize(address _nft, address _weth) public initializer {
        __Ownable_init();
        creatorPercentage = 50;
        nftHolderPercentage = 50;
        nft = IERC721EnumerableUpgradeable(_nft);
        weth = IERC20Upgradeable(_weth);
    }
    
    function setWETHAddress(address WETH) external onlyOwner {
        weth = IERC20Upgradeable(WETH);
    }
    
    function setNFTAddress(address NFT) external onlyOwner {
        nft = IERC721EnumerableUpgradeable(NFT);
    }
    
    function setCreatorPercentage(uint256 _creatorPercentage) public onlyOwner {
        creatorPercentage = _creatorPercentage;
    }
    
    function setNFTHolderPercentage(uint256 _nftHolderPercentage) public onlyOwner {
        nftHolderPercentage = _nftHolderPercentage;
    }
    
    function releasableETHFundsForToken(uint256 tokenId) public view returns(uint256) {
        uint256 fundsReceived = ETH_FUNDS_STORED_FOR_HOLDERS + TOTAL_ETH_FUNDS_RELEASED;
        return pendingFundsForNFTHolder(fundsReceived, ETHFundsReleasedPerToken[tokenId]);
    }
    
    function releasableWETHFundsForToken(uint256 tokenId) public view returns(uint256) {
        uint256 fundsReceived = WETH_FUNDS_STORED_FOR_HOLDERS + TOTAL_WETH_FUNDS_RELEASED;
        return pendingFundsForNFTHolder(fundsReceived, WETHFundsReleasedPerToken[tokenId]);
    }
    
    // This function fetched the NFT balance of the user and the tokenIds of the NFTs
    // This function is written with consideration that the NFT contract will be ERC721Enumerable
    function getUserData(address user) internal view returns(uint256[] memory tokenIds) {
        uint256 tokenCount = nft.balanceOf(user);
        tokenIds = new uint256[](tokenCount);
        for(uint256 i=0;i<tokenCount;i++) {
            tokenIds[i] = nft.tokenOfOwnerByIndex(user, i);
        }
    }
    
    // This function is called to withdraw funds both for creators and holders
    function claimFunds() external updateStoredFunds {
        if(msg.sender == owner()) 
            withdrawForCreators();
        else
            withdrawForHolders();
        
        postWithdrawal();
    }
    
    // This function is called to withdraw funds for NFT holders
    function withdrawForHolders() internal {
        uint256 ethFundsReleased;
        uint256 wethFundsReleased;
        uint256[] memory tokens = getUserData(msg.sender);
        for (uint256 i=0; i< tokens.length; i++) {
            uint256 tokenId = tokens[i];
            uint256 ethAmount = releasableETHFundsForToken(tokenId);
            uint256 wethAmount = releasableWETHFundsForToken(tokenId);
            
            ETHFundsReleasedPerToken[tokenId] += ethAmount;
            WETHFundsReleasedPerToken[tokenId] += wethAmount;
            ethFundsReleased += ethAmount;
            wethFundsReleased += wethAmount;
        }
        
        if (ethFundsReleased == 0 && wethFundsReleased == 0) {
            revert ("No outstanding funds left to release");
        }
        
        TOTAL_ETH_FUNDS_RELEASED += ethFundsReleased;
        TOTAL_WETH_FUNDS_RELEASED += wethFundsReleased;
        
        WETH_FUNDS_STORED_FOR_HOLDERS -= wethFundsReleased;
        ETH_FUNDS_STORED_FOR_HOLDERS -= ethFundsReleased;
        
        weth.transfer(msg.sender, wethFundsReleased);
        payable(msg.sender).transfer(ethFundsReleased);
        
        emit FundsReleased(msg.sender, ethFundsReleased, wethFundsReleased);
        
    }
    
    // This function is called to send the funds stored for the creator to the owner
    function withdrawForCreators() internal {
        uint256 ethAmount = ETH_FUNDS_STORED_FOR_CREATOR;
        uint256 wethAmount = WETH_FUNDS_STORED_FOR_CREATOR; 
        ETH_FUNDS_STORED_FOR_CREATOR = 0;
        WETH_FUNDS_STORED_FOR_CREATOR = 0;
        
        TOTAL_ETH_RELEASED_TO_CREATOR += ethAmount;
        TOTAL_WETH_RELEASED_TO_CREATOR += wethAmount;
        
        if (ethAmount == 0 && wethAmount == 0) {
            revert ("No outstanding funds left to release");
        }
        
        payable(msg.sender).transfer(ethAmount);
        weth.transfer(msg.sender, wethAmount);
        
        emit FundsReleased(msg.sender, ethAmount, wethAmount);
    }    
    
    // This function is called after every withdrawal to update the state variables
    function postWithdrawal() internal {
        ETHBalanceState = address(this).balance;
        WETHBalanceState = weth.balanceOf(address(this));
    }
    
    // This function returns the pending funds for a particular NFT token
    function pendingFundsForNFTHolder( uint256 fundsReceived, uint256 fundsReleased) internal view returns(uint256) {
        return (fundsReceived * 1) / nft.totalSupply() - fundsReleased;
    }
    
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
}
