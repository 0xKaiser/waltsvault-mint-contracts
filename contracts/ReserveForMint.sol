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
    
    address public designatedSigner;
    uint256 public signatureExpiryTime;
    uint public resPrice;
    uint public maxResPerAddr_FCFS;
    uint public maxResPerSpot_VL;
    
    mapping(bytes => bool) private isSignatureUsed;
    
    mapping(address => uint) public resByAddr_FCFS;
    mapping(address => uint) public resByAddr_VL;
    mapping(address => uint[]) public tokensLockedByAddr;
    mapping(uint => address) public lockerAddrOf;
    
    function initialize (address _ravendaleAddr) external initializer {
        __Ownable_init();
        __WhiteList_init();
        ravendale = IERC721Upgradeable(_ravendaleAddr);
        state = currentstate.NOT_STARTED;
    }
    
    function placeOrder(
        uint256[] calldata tokensToLock,
        whitelist memory signature,
        uint256 amt_VL,
        uint256 amt_FCFS
    ) external payable {
        if(tokensToLock.length > 0){
            require(state != currentstate.NOT_STARTED,"Participation not started yet");
            for(uint i=0; i<tokensToLock.length; i++){
                require(ravendale.ownerOf(tokensToLock[i]) == msg.sender, "You are not the owner of the NFT");
                tokensLockedByAddr[msg.sender].push(tokensToLock[i]);
                lockerAddrOf[tokensToLock[i]] = msg.sender;
                ravendale.safeTransferFrom(msg.sender, address(this), tokensToLock[i]);
            }
        }
        
        require(msg.value == (amt_FCFS + amt_VL) * resPrice, "Incorrect amount sent");
        
        if(amt_VL > 0){
            uint maxAllowedAmt_VL = (tokensToLock.length + tokensLockedByAddr[msg.sender].length
                            + signature.amountAllocated) * maxResPerSpot_VL;
            
            require(state == currentstate.STARTED,"Participation not started yet");
            require(maxAllowedAmt_VL >= resByAddr_VL[msg.sender] + amt_VL, "Exceeds max allowed reservation");
            
            verifySignature(signature);
            isSignatureUsed[signature.signature] = true;
            
            resByAddr_VL[msg.sender] += amt_VL;
        }

        if(amt_FCFS > 0){
            require(state == currentstate.STARTED,"Participation not started yet");
            require(maxResPerAddr_FCFS >= resByAddr_FCFS[msg.sender] + amt_FCFS, "Exceeds max allowed reservation");
            resByAddr_FCFS[msg.sender] += amt_FCFS;
        }
    }
    
    function claimRefund(
        whitelist memory signature
    ) external {
        require(state == currentstate.ENDED, "Free participation not ended");
        verifySignature(signature);
        isSignatureUsed[signature.signature] = true;
        uint256 amtUnallocated = resByAddr_VL[msg.sender] + resByAddr_FCFS[msg.sender] - signature.amountAllocated;
        
        payable(msg.sender).transfer(amtUnallocated * resPrice);
    }

    function verifySignature(whitelist memory signature) internal view {
        require(getSigner(signature) == designatedSigner, "Invalid signature");
        require(block.timestamp < signature.nonce + signatureExpiryTime, "Expired Nonce");
        require(!isSignatureUsed[signature.signature], "Nonce already used");
        require(signature.userAddress == msg.sender, "Invalid user address");
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
        * @dev Restock the contract with ETH for refunding users
    */
    function restockContractForRefund() external payable onlyOwner {
        require(state == currentstate.ENDED, "Free participation not ended");
    }
    
    // Setters
    
    function openReservation() external onlyOwner {
        state = currentstate.STARTED;
    }
    
    function closeReservation() external onlyOwner {
        state = currentstate.ENDED;
    }
    
    function setReservationPrice(uint256 _resPrice) external onlyOwner {
        resPrice = _resPrice;
    }
    
    function setDesignatedSigner(address _designatedSigner) external onlyOwner {
        designatedSigner = _designatedSigner;
    }
    
    function setRavendale(address _ravendaleAddr) external onlyOwner {
        ravendale = IERC721Upgradeable(_ravendaleAddr);
    }
    
    // Getters
    
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
    

