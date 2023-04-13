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
            require(state != currentstate.NOT_STARTED);

            for(uint i=0; i<tokensToLock.length; i++){
                ravendale.safeTransferFrom(msg.sender, address(this), tokensToLock[i]);
                tokensLockedByAddr.push[tokensToLock[i]];
                lockerAddrOf[tokensToLock[i]] = msg.sender;
            }
        }
        
        require(msg.value == (amt_FCFS + amt_VL) * resPrice);        
        
        if(amt_VL > 0){
            uint maxAllowedAmt_VL = (tokensToLock.length + tokensLockedByAddr.length 
                            + signature.spots) * maxResPerSpot_VL;
            
            require(state == currentstate.STARTED);
            require(maxAllowedAmt_VL >= resByAddr_VL[msg.sender] + amt_VL);
            
            verifySignature(signature);
            
            resByAddr_VL[msg.sender] += amt_VL;
        }

        if(amt_FCFS > 0){
            require(state == currentstate.STARTED);
            require(maxResPerAddr_FCFS >= resByAddr_FCFS[msg.sender] + amt_FCFS);
            
            resByAddr_FCFS[msg.sender] += amt_FCFS;
        }
    }
    
    function claimRefund(
        whitelist memory signature,
        uint256 amtAllocated,
    ) external {
        require(state == currentstate.ENDED, "Free participation not ended");
        
        verifySignature(signature);
        
        amtUnallocated = resByAddr_VL + resByAddr_FCFS - amtAllocated;        
        payable(msg.sender).transfer(amtUnallocated * resPrice);
    }

    function verifySignature(whitelist memory signature) internal {
        require(getSigner(signature) == designatedSigner, "Invalid signature");
        require(block.timestamp < signature.nonce + 3 minutes, "Expired Nonce");
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
        resPrice = _entryresPrice;
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
    

