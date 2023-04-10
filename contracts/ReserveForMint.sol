// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {OwnableUpgradeable} from
"@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC721Upgradeable} from
"@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {Whitelist} from "./utils/WhiteListSigner.sol";

contract ReserveForMint is OwnableUpgradeable, Whitelist {

    IERC721Upgradeable public ravendale;
    enum currentstate {NOT_STARTED, STARTED, ENDED}
    currentstate public state;
    
    uint256 public resPerRavendale;
    uint256 public resPrice;
    address public designatedSigner;
    
    address[] public addrPaid;
    address[] public addrRavendale;
    
    mapping(bytes => bool) private isSignatureUsed;
    mapping(address => uint256) private resByAddr;
    mapping(address => bool) private isRavendaleClaimer;
    
    function initialize (address _ravendaleAddr) external initializer {
        __Ownable_init();
        __WhiteList_init();
        ravendale = IERC721Upgradeable(_ravendaleAddr);
        state = currentstate.NOT_STARTED;
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function paidReserve(whitelist memory signature, uint256 amount) external payable {
        require(state == currentstate.STARTED, "Participation not started");
        require(getSigner(signature) == designatedSigner, "Invalid signature");
        require(block.timestamp < signature.nonce + 3 minutes, "Expired Nonce");
        require(!isSignatureUsed[signature.signature], "Nonce already used");
        require(signature.userAddress == msg.sender, "Invalid user address");
        require(signature.amountAllowed >= amount + resByAddr[msg.sender], "Invalid amount");
        require(msg.value == entryresPrice * amount, "Invalid value");
        require(ravendale.balanceOf(msg.sender) == 0, "Must claim first");
        
        isSignatureUsed[signature.signature] = true;
        resByAddr[msg.sender] += amount;
        addrPaid.push(msg.sender);
    }
    
    function ravendaleReserve(uint256[] memory tokenIds) external {
        uint256 ravendaleBalance = ravendale.balanceOf(msg.sender);
        
        require(state == currentstate.STARTED, "Not started");
        require(ravendaleBalance > 0, "You don't own any Ravendale");
        require(ravendaleBalance == tokenIds.length, "You are not locking all Ravendales");
        resByAddr[msg.sender] += resPerRavendale * tokenIds.length;
        
        if(isRavendaleClaimer[msg.sender] == false){
            addrRavendale.push(msg.sender);
            isRavendaleClaimer[msg.sender] = true;
        }
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ravendale.transferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }
    
    function refund(address[] memory to, uint256[] memory val) external {
        require(state == currentstate.ENDED, "Free participation not ended");
        
        for (uint256 i = 0; i < addrs.length; i++) {
            payable(to[i]).transfer(val[i]);
        }
    }
    
    /**
        * @dev Restock the contract with ETH for refunding users
    */
    function restockContractForRefund() external payable onlyOwner {
        require(state == currentstate.ENDED, "Free participation not ended");
    }
    
    // Setters
    
    function startReservation() external onlyOwner {
        state = currentstate.STARTED;
    }
    
    function endReservation() external onlyOwner {
        state = currentstate.ENDED;
    }
    
    function setResPrice(uint256 _resPrice) external onlyOwner {
        resPrice = _entryresPrice;
    }
    
    function setResPerRavendale(uint256 _resPerRavendale) external onlyOwner {
        resPerRavendale = _resPerRavendale;
    }
    
    function setDesignatedSigner(address _designatedSigner) external onlyOwner {
        designatedSigner = _designatedSigner;
    }
    
    function setRavendale(address _ravendaleAddr) external onlyOwner {
        ravendale = IERC721Upgradeable(_ravendaleAddr);
    }
    
    // Getters
    
    function getBuyers() external view returns (address[] memory) {
        return addrPaid;
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
    

