// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {Signer} from "./utils/Signer.sol";

contract WaltsVaultReservation is OwnableUpgradeable, Signer {
    
    IERC721Upgradeable public ravendale;
    
    event LockRavendale(address indexed locker, uint256 indexed tokenId);
    event ReserveVaultList(address reserver, uint256 indexed reserveAmount);
    event Reserve(address reserver, uint256 indexed reserveAmount);
    event ClaimRefund(address indexed claimer, uint256 indexed refundAmount);
    
    event ReleaseRavendale(address indexed receiver, uint256 indexed tokenId);
    event OpenReservation();
    event CloseReservation();
    event OpenRefundClaim();
    
    enum currentState {NOT_LIVE, LIVE, OVER, REFUND}
    currentState public state;
    
    address public designatedSigner;
    uint256 public totalWithdrawal;

    uint public PRICE_PER_RES;
    uint public MAX_RES_PER_ADDR_FCFS;
    uint public MAX_RES_PER_ADDR_VL;
    uint256 public MAX_AMT_FOR_RES ;
    uint256 public SIGNATURE_VALIDITY;
    
    mapping(address => uint) public resByAddr_FCFS;
    mapping(address => uint) public resByAddr_VL;
    mapping(address => uint[]) private tokensLockedBy;
    mapping(uint => address) public lockerOf;
    
    address[] public FCFS_Reservers_List;
    address[] public VL_Reservers_List;
    
    mapping(bytes => bool) private isSignatureUsed;
    mapping(address => bool) public hasClaimedRefund;
    
    function initialize(
        address _ravendaleAddr,
        address _designatedSigner
    ) external initializer {
        __Ownable_init();
        __Signer_init();
        state = currentState.NOT_LIVE;
        designatedSigner = _designatedSigner;
        PRICE_PER_RES = 0.01 ether;
        MAX_RES_PER_ADDR_FCFS =2;
        MAX_RES_PER_ADDR_VL = 2;
        MAX_AMT_FOR_RES = 1000;
        ravendale = IERC721Upgradeable(_ravendaleAddr);
    }
    
    function placeOrder(
        uint256[] calldata tokensToLock,
        orderInfo memory info,
        uint256 amt_VL,
        uint256 amt_FCFS
    ) external payable {
        
        if(tokensToLock.length > 0){
            
            for(uint i=0; i<tokensToLock.length; i++){
                tokensLockedBy[msg.sender].push(tokensToLock[i]);
                lockerOf[tokensToLock[i]] = msg.sender;
                ravendale.safeTransferFrom(msg.sender, address(this), tokensToLock[i]);
                
                emit LockRavendale(msg.sender, tokensToLock[i]);
            }
        }
        
        require(msg.value == (amt_FCFS + amt_VL) * PRICE_PER_RES, "Incorrect payment");
        
        if(amt_VL > 0){
            uint maxAllowedAmt_VL = (tokensToLock.length + tokensLockedBy[msg.sender].length
                            + info.allocatedSpots) * MAX_RES_PER_ADDR_VL;
            
            require(state == currentState.LIVE, "Reservation not live");
            require(maxAllowedAmt_VL >= resByAddr_VL[msg.sender] + amt_VL, "Exceeding reservation allowance");
            verifyOrderInfoSignature(info);
            
            if(resByAddr_VL[msg.sender] == 0){
                VL_Reservers_List.push(msg.sender);
            }
            
            isSignatureUsed[info.signature] = true;
            resByAddr_VL[msg.sender] += amt_VL;
            
            emit ReserveVaultList(msg.sender, amt_VL);
        }

        if(amt_FCFS > 0){
            require(state == currentState.LIVE,"Reservation not live");
            require(MAX_RES_PER_ADDR_FCFS >= resByAddr_FCFS[msg.sender] + amt_FCFS, "Exceeding reservation allowance");
            
            if(resByAddr_FCFS[msg.sender] == 0){
                FCFS_Reservers_List.push(msg.sender);
            }
            
            resByAddr_FCFS[msg.sender] += amt_FCFS;
            
            emit Reserve(msg.sender, amt_FCFS);
        }
    }
    
    function claimRefund(
        refundInfo memory info
    ) external {
        require(state == currentState.REFUND, "Refund not started yet");
        require(!hasClaimedRefund[msg.sender], "Refund already claimed");
        verifyRefundInfoSignature(info);
        
        isSignatureUsed[info.signature] = true;
        hasClaimedRefund[msg.sender] = true;
        
        uint256 amtUnallocated = resByAddr_VL[msg.sender] + resByAddr_FCFS[msg.sender] - info.amtAllocated;
        uint256 refundAmount = amtUnallocated * PRICE_PER_RES;
        payable(msg.sender).transfer(refundAmount);
        
        emit ClaimRefund(msg.sender, refundAmount);
    }
    
    // Only Owner
    function releaseRavendale(
        address[] calldata lockers
    ) external onlyOwner {
        for(uint256 j=0; j<lockers.length; j++){
            uint[] memory tokensToReturn = tokensLockedBy[lockers[j]];
            
            for(uint i=0; i<tokensToReturn.length; i++){
                ravendale.safeTransferFrom(address(this), lockers[j], tokensToReturn[i]);
                emit ReleaseRavendale(lockers[j], tokensToReturn[i]);
            }
        }
        delete tokensLockedBy[msg.sender];
    }

    function withdraw() external onlyOwner {
        uint256 pending = MAX_AMT_FOR_RES * PRICE_PER_RES - totalWithdrawal;
        if (pending > address(this).balance) {
            pending = address(this).balance;
        }
        totalWithdrawal += pending;
        payable(msg.sender).transfer(pending);
    }
    
    function airdropReserveTokens(
        address waltsVault, 
        address[] calldata receivers, 
        uint256[] calldata tokenIds
    ) external onlyOwner {
        require(receivers.length == tokenIds.length, "Invalid input");
        for(uint i=0; i<receivers.length; i++){
            IERC721Upgradeable(waltsVault).safeTransferFrom(address(this), receivers[i], tokenIds[i]);
        }
    }
    
    function openReservation() external onlyOwner {
        state = currentState.LIVE;
        emit OpenReservation();
    }
    
    function closeReservation() external onlyOwner {
        state = currentState.OVER;
        emit CloseReservation();
    }
    
    function openRefundClaim() external onlyOwner {
        state = currentState.REFUND;
        emit OpenRefundClaim();
    }
    
    // Setters
    
    function setMaxResPerAddr(
        uint256 maxResPerAddr_VL, 
        uint256 maxResPerAddr_FCFS
    ) external onlyOwner {
        require(state == currentState.NOT_LIVE);
        MAX_RES_PER_ADDR_VL = maxResPerAddr_VL;
        MAX_RES_PER_ADDR_FCFS = maxResPerAddr_FCFS;
    }
    
    function setReservationPrice(uint256 resPrice) external onlyOwner {
        require(state == currentState.NOT_LIVE);
        PRICE_PER_RES = resPrice;
    }
    
    function setDesignatedSigner(address _designatedSigner) external onlyOwner {
        designatedSigner = _designatedSigner;
    }
    
    function setRavendale(address ravendaleAddr) external onlyOwner {
        ravendale = IERC721Upgradeable(ravendaleAddr);
    }
    
    function setMaxAmtForRes(uint256 maxAmtForRes) external onlyOwner {
        require(state == currentState.NOT_LIVE);
        MAX_AMT_FOR_RES = maxAmtForRes;
    }
    
    function setSignatureValidityTime(uint256 validityTime) external onlyOwner {
        SIGNATURE_VALIDITY = validityTime;
    }
    
    // Getter
    
    function getTokensLockedByAddr(address addr) external view returns(uint256[] memory){
        return tokensLockedBy[addr];
    }
    
    function getTotalTokensLocked(address addr) external view returns(uint256){
        return tokensLockedBy[addr].length;
    }
    
    function getTokenLockedByIndex(address addr, uint256 index) external view returns(uint256){
        return tokensLockedBy[addr][index];
    }
    
    function getAllVL_Reservers() external view returns(address[] memory){
        return VL_Reservers_List;
    }
    
    function getTotalVL_Reservers() external view returns(uint256){
        return VL_Reservers_List.length;
    }
    
    function getVL_ReserverByIndex(uint256 index) external view returns(address){
        return VL_Reservers_List[index];
    }
    
    function getAllFCFS_Reservers() external view returns(address[] memory){
        return FCFS_Reservers_List;
    }
    
    function getTotalFCFS_Reservers() external view returns(uint256){
        return FCFS_Reservers_List.length;
    }
    
    function getFCFS_ReserverByIndex(uint256 index) external view returns(address){
        return FCFS_Reservers_List[index];
    }

    function setStateForTesting(uint intState) external {
        if(intState == 1) state = currentState.NOT_LIVE;
        else if(intState == 2) state = currentState.LIVE;
        else if(intState == 3) state = currentState.OVER;
        else state = currentState.REFUND;
    }
    
    // Internal
    function verifyOrderInfoSignature(orderInfo memory info) internal view {
        require(getSignerOrder(info) == designatedSigner, "Unauthorised signer");
        require(block.timestamp < info.nonce + SIGNATURE_VALIDITY, "Expired nonce");
        require(!isSignatureUsed[info.signature], "Used signature");
        require(info.userAddress == msg.sender, "Invalid address");
    }
    
    function verifyRefundInfoSignature(refundInfo memory info) internal view {
        require(getSignerRefund(info) == designatedSigner, "Unauthorised signer");
        require(block.timestamp < info.nonce + SIGNATURE_VALIDITY, "Expired nonce");
        require(!isSignatureUsed[info.signature], "Used signature");
        require(info.userAddress == msg.sender, "Invalid address");
    }
    
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
    

