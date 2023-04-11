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
    address public designatedSigner;
    
    uint256 public entriesPerRavenDale;
    uint256 public entriesPerFCFS;
    uint256 public entriesPerVaultList;
    uint256 public entryPrice;
    uint256 public signatureExpiryTime;
    
    
    address[] public fcfsParticipants;
    address[] public ravenDaleParticipants;
    address[] public vaultListParticipants;
    
    
    mapping(address => bool) private isVaultListParticipant;
    mapping(address => bool) private isRavenDaleParticipant;
    mapping(address => bool) private isFCFSParticipant;
    
    mapping(bytes => bool) private isSignatureUsed;
    mapping(address => uint256[]) private ravenDaleNFTLocked;
    mapping(address => uint256) private fcfsUserEntries;
    mapping(address => uint256) private ravenDaleUserEntries;
    mapping(address => uint256) private vaultListUserEntries;
    
    function initialize (address _ravenDaleNFTAddress) external initializer {
        __Ownable_init();
        __WhiteList_init();
        ravenDaleNFT = IERC721Upgradeable(_ravenDaleNFTAddress);
        State = currentState.NOT_STARTED;
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function FCFS(whitelist calldata signature, uint256 entries) external payable {
        require(getSigner(signature) == designatedSigner, "Invalid signature");
        require(entriesPerFCFS >= entries + fcfsUserEntries[msg.sender], "Invalid amount");
        require(signature.listType == 1, "Invalid list type");
        require(msg.value == entryPrice * entries, "Invalid amount");
        require(signature.userAddress == msg.sender, "Invalid user address");
        require(block.timestamp < signature.nonce + signatureExpiryTime, "Expired Nonce");
        require(!isSignatureUsed[signature.signature], "Nonce already used");
        require(State == currentState.STARTED, "Participation not started");
        require(ravenDaleNFT.balanceOf(msg.sender) == 0, "Please enter free participation first");
        
        if(isFCFSParticipant[msg.sender] == false){
            fcfsParticipants.push(msg.sender);
            isFCFSParticipant[msg.sender] = true;
        }
        
        isSignatureUsed[signature.signature] = true;
        fcfsUserEntries[msg.sender] += entries;
    }
    
    function VaultList(whitelist calldata signature, uint256 entries) external payable {
        require(getSigner(signature) == designatedSigner, "Invalid signature");
        require(entriesPerVaultList >= entries + vaultListUserEntries[msg.sender], "Invalid amount");
        require(signature.listType == 2, "Invalid list type");
        require(msg.value == entryPrice * entries, "Invalid amount");
        require(signature.userAddress == msg.sender, "Invalid user address");
        require(block.timestamp < signature.nonce + signatureExpiryTime, "Expired Nonce");
        require(!isSignatureUsed[signature.signature], "Nonce already used");
        require(State == currentState.STARTED, "Participation not started");
        require(ravenDaleNFT.balanceOf(msg.sender) == 0, "Please enter free participation first");
        
        if(isVaultListParticipant[msg.sender] == false){
            vaultListParticipants.push(msg.sender);
            isVaultListParticipant[msg.sender] = true;
        }
        
        isSignatureUsed[signature.signature] = true;
        vaultListUserEntries[msg.sender] += entries;
    }
    
    /**
        * @notice This function is used to participate in the free mint for RavenDale NFT holders
        * @notice and also for the VaultList mint for the users who have staked their NFTs
        * @dev While calling this function, first pass all the RavenDale NFTs user own and pass 0 as entries
        * @dev After that, pass empty array for vaultList and pass the number of entries user wants to participate in the mint
        * @param tokenIds Array of tokenIds of the NFTs
        * @param entries Number entry to the mint
    */
    function RavenDaleParticipation(uint256[] calldata tokenIds, uint256 entries) external payable{
        require(State == currentState.STARTED, "Free participation not started");
        if (entries == 0 && tokenIds.length > 0) {
        uint256 ravenDaleNFTBalance = ravenDaleNFT.balanceOf(msg.sender);
        require(ravenDaleNFTBalance > 0, "You don't own any NFT");
        require(ravenDaleNFTBalance == tokenIds.length, "You are not staking all NFT");
        ravenDaleUserEntries[msg.sender] += entriesPerRavenDale * tokenIds.length;
        if(isRavenDaleParticipant[msg.sender] == false){
            ravenDaleParticipants.push(msg.sender);
            isRavenDaleParticipant[msg.sender] = true;
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ravenDaleNFT.ownerOf(tokenIds[i]) == msg.sender, "You are not the owner of the NFT");
            ravenDaleNFTLocked[msg.sender].push(tokenIds[i]);
            ravenDaleNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }
        else if(entries > 0 && tokenIds.length == 0) {
        
        require(ravenDaleNFT.balanceOf(msg.sender) == 0, "Please enter free participation first");
        uint256 entriesLeft = getEntriesLeft(msg.sender);
        require(entriesLeft >= entries, "Invalid amount");
        require(msg.value == entryPrice * entries, "Invalid amount");
        vaultListUserEntries[msg.sender] += entries;
        if(isVaultListParticipant[msg.sender] == false){
                vaultListParticipants.push(msg.sender);
                isVaultListParticipant[msg.sender] = true;
            }
        }
        
        else {
            revert("Invalid input");
        }
    }
    
    function getEntriesLeft(address user) public view returns(uint256){
        uint256 totalTokenStaked = ravenDaleNFTLocked[user].length;
        uint256 totalVaultEntries = vaultListUserEntries[user];
        return (entriesPerVaultList * totalTokenStaked - totalVaultEntries);
    }
    
    function refundParticipation(address[] calldata users, uint256[] calldata amountsToRefund) external {
        require(State == currentState.ENDED, "Free participation not ended");
        for (uint256 i = 0; i < users.length; i++)
                payable(users[i]).transfer(amountsToRefund[i]);
    }
    
    function withdrawNFT(address[] calldata users, uint256[] calldata tokenIds) external onlyOwner{
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
    
    // Setters
    
    function startParticipation() external onlyOwner {
        State = currentState.STARTED;
    }
    
    function endParticipation() external onlyOwner {
        State = currentState.ENDED;
    }
    
    function setEntryPrice(uint256 _entryPrice) external onlyOwner {
        entryPrice = _entryPrice;
    }
    
    function setEntriesPerVaultList(uint256 _entriesPerVaultList) external onlyOwner {
        entriesPerVaultList = _entriesPerVaultList;
    }
    
    function setSignatureExpiryTime(uint256 _signatureExpiryTime) external onlyOwner {
        signatureExpiryTime = _signatureExpiryTime;
    }
    
    function setEntriesPerFCFS(uint256 _entriesPerFCFS) external onlyOwner {
        entriesPerFCFS = _entriesPerFCFS;
    }
    
    function setEntriesPerRavenDale(uint256 _entriesPerRavenDale) external onlyOwner {
        entriesPerRavenDale = _entriesPerRavenDale;
    }
    
    function setDesignatedSigner(address _designatedSigner) external onlyOwner {
        designatedSigner = _designatedSigner;
    }
    
    function setNFTAddress(address _ravenDaleNFTAddress) external onlyOwner {
        ravenDaleNFT = IERC721Upgradeable(_ravenDaleNFTAddress);
    }
    
    // Getters

    function getSignatureUsed(bytes memory nonce) external view returns (bool) {
        return isSignatureUsed[nonce];
    }
    
    function getVaultListParticipants() external view returns (address[] memory) {
        return vaultListParticipants;
    }
    
    function getRavenDaleParticipants() external view returns (address[] memory) {
        return ravenDaleParticipants;
    }
    
    function getFCFSParticipants() external view returns (address[] memory) {
        return fcfsParticipants;
    }
    
    function getFCFSUserEntries(address user) external view returns (uint256) {
        return fcfsUserEntries[user];
    }
    
    function getRavenDaleNFTEntries(address user) external view returns (uint256[] memory) {
        return ravenDaleNFTLocked[user];
    }
    
    function getVaultListUserEntries(address user) external view returns (uint256) {
        return vaultListUserEntries[user];
    }
    
    function getRavenDaleUserEntries(address user) external view returns (uint256) {
        return ravenDaleUserEntries[user];
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
    

