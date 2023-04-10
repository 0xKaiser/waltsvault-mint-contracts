// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {OwnableUpgradeable} from
"@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC721Upgradeable} from
"@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {Whitelist} from "./utils/WhiteListSigner.sol";

contract ParticipateInMint is OwnableUpgradeable, Whitelist {

    IERC721Upgradeable public ravenDaleNFT;
    enum currentState {NOT_STARTED, STARTED, ENDED}
    currentState public State;
    
    uint256 public entryPrice;
    address public designatedSigner;
    address[] public participants;
    
    mapping(bytes => bool) private isSignatureUsed;
    mapping(address => uint256) private userEntries;
    
    function initialize (address _ravenDaleNFTAddress) external initializer {
        __Ownable_init();
        __WhiteList_init();
        ravenDaleNFT = IERC721Upgradeable(_ravenDaleNFTAddress);
        State = currentState.NOT_STARTED;
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function depositETH(whitelist memory signature, uint256 entries) external payable {
        require(getSigner(signature) == designatedSigner, "Invalid signature");
        require(signature.entriesAllowed >= entries + userEntries[msg.sender], "Invalid amount");
        require(msg.value == entryPrice * entries, "Invalid amount");
        require(signature.userAddress == msg.sender, "Invalid user address");
        require(block.timestamp < signature.nonce + 3 minutes, "Expired Nonce");
        require(!isSignatureUsed[signature.signature], "Nonce already used");
        require(State == currentState.STARTED, "Participation not started");
        require(ravenDaleNFT.balanceOf(msg.sender) == 0, "Please enter free participation first");
        isSignatureUsed[signature.signature] = true;
        userEntries[msg.sender] += entries;
        participants.push(msg.sender);
    }
    
    function enterFreeParticipation(whitelist memory signature, uint256[] memory tokenIds, uint256 entries) external {
        require(getSigner(signature) == designatedSigner, "Invalid signature");
        uint256 ravenDaleNFTBalance = ravenDaleNFT.balanceOf(msg.sender);
        require(ravenDaleNFTBalance > 0, "You don't own any NFT");
        require(ravenDaleNFTBalance == tokenIds.length, "You are not staking all NFT");
        require(State == currentState.STARTED, "Free participation not started");
        require(block.timestamp < signature.nonce + 3 minutes, "Expired Nonce");
        require(!isSignatureUsed[signature.signature], "Nonce already used");
        require(signature.entriesAllowed >= (entries + userEntries[msg.sender]), "Invalid amount");
        isSignatureUsed[signature.signature] = true;
        userEntries[msg.sender] += entries;
        participants.push(msg.sender);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ravenDaleNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }
    
    function refundParticipation(address[] memory users) external {
        require(State == currentState.ENDED, "Free participation not ended");
        for (uint256 i = 0; i < users.length; i++) {
            uint256 entries = userEntries[users[i]];
            if (entries > 0) {
                payable(users[i]).transfer(entryPrice * entries);
                userEntries[users[i]] = 0;
            }
        }
    }
    
    function withdrawNFT(address[] memory users, uint256[] memory tokenIds) external onlyOwner{
        require(State == currentState.ENDED, "Participation not ended");
        for (uint256 i = 0; i < users.length; i++)
            ravenDaleNFT.transferFrom(address(this), users[i], tokenIds[i]);
    }
  
    
    /**
        * @dev Restock the contract with ETH for refunding users
    */
    function restockContractForRefund() external payable onlyOwner {
        require(State == currentState.ENDED, "Free participation not ended");
    }
    
    function startParticipation() external onlyOwner {
        State = currentState.STARTED;
    }
    
    function endParticipation() external onlyOwner {
        State = currentState.ENDED;
    }
    
    function setEntryPrice(uint256 _entryPrice) external onlyOwner {
        entryPrice = _entryPrice;
    }
    
    function setDesignatedSigner(address _designatedSigner) external onlyOwner {
        designatedSigner = _designatedSigner;
    }
    
    function setNFTAddress(address _ravenDaleNFTAddress) external onlyOwner {
        ravenDaleNFT = IERC721Upgradeable(_ravenDaleNFTAddress);
    }
    
    function getParticipants() external view returns (address[] memory) {
        return participants;
    }
    
    function getEntries(address user) external view returns (uint256) {
        return userEntries[user];
    }

    function getSignatureUsed(bytes memory nonce) external view returns (bool) {
        return isSignatureUsed[nonce];
    }
    
    
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `safeTransfer`. This function MAY throw to revert and reject the
    ///  transfer. This function MUST use 50,000 gas or less. Return of other
    ///  than the magic value MUST result in the transaction being reverted.
    ///  Note: the contract address is always the message sender.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
}
    

