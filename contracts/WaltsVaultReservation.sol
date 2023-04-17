// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import {Ownable} from
"@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from
"@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Signer} from "./utils/Signer.sol";

contract WaltsVaultReservation is Ownable, Signer {

    IERC721 public ravendale;
    
    event placeOrder_(
        address indexed user,
        uint256 indexed totalSpotsAccumulated
    );
    event claimRefund_(
        address indexed user,
        uint256 indexed amtUnallocated
    );
    event releaseRavendale_(
        address indexed user,
        uint256 indexed tokensToReturn
    );
    event openReservation_();
    event closeReservation_();
    event startRefund_();
    event startReturn_();
    
    enum currentState {NOT_LIVE, LIVE, WITHDRAW, OVER, REFUND, RETURN}
    currentState public state;
    
    address public designatedSigner;
    uint256 public SIGNATURE_VALIDITY = 3 minutes;
    uint public PRICE_PER_RES = 0.01 ether;
    uint public MAX_RES_PER_ADDR_FCFS = 2;
    uint public MAX_RES_PER_ADDR_VL = 2;
    uint256 constant public MAX_AMT_FOR_RES = 1000;

    mapping(bytes => bool) private isStateSet;
    mapping(bytes => bool) private isSignatureUsed;
    mapping(address => uint) public resByAddr_FCFS;
    mapping(address => uint) public resByAddr_VL;
    mapping(address => uint[]) private tokenLockedBy;
    mapping(uint => address) public lockerOf;
    mapping(address => bool) public hasClaimedRefund;
    
    modifier onlyOnce(currentState newState) {
        require(!isStateSet[abi.encodePacked(newState)], "State already started");
        _;
    }
    
    constructor(address _ravendaleAddr, address _designatedSigner) {
        __Signer_init();
        state = currentState.NOT_LIVE;
        designatedSigner = _designatedSigner;
        ravendale = IERC721(_ravendaleAddr);
    }
    
    function placeOrder(
        uint256[] calldata tokensToLock,
        orderInfo memory info,
        uint256 amt_VL,
        uint256 amt_FCFS
    ) external payable {
        
        if(tokensToLock.length > 0){
            require(state != currentState.NOT_LIVE,"Participation not started yet");
            for(uint i=0; i<tokensToLock.length; i++){
                tokenLockedBy[msg.sender].push(tokensToLock[i]);
                lockerOf[tokensToLock[i]] = msg.sender;
                ravendale.safeTransferFrom(msg.sender, address(this), tokensToLock[i]);
            }
        }
        
        require(msg.value == (amt_FCFS + amt_VL) * PRICE_PER_RES, "Incorrect amount sent");
        
        if(amt_VL > 0){
            uint maxAllowedAmt_VL = (tokensToLock.length + tokenLockedBy[msg.sender].length
                            + info.allocatedSpots) * MAX_RES_PER_ADDR_VL;
            
            require(state == currentState.LIVE,"Participation not started yet");
            require(maxAllowedAmt_VL >= resByAddr_VL[msg.sender] + amt_VL, "Exceeds max allowed reservation");
            
            verifyOrderInfoSignature(info);
            isSignatureUsed[info.signature] = true;
            
            resByAddr_VL[msg.sender] += amt_VL;
        }

        if(amt_FCFS > 0){
            require(state == currentState.LIVE,"Participation not started yet");
            require(MAX_RES_PER_ADDR_FCFS >= resByAddr_FCFS[msg.sender] + amt_FCFS, "Exceeds max allowed reservation");
            resByAddr_FCFS[msg.sender] += amt_FCFS;
        }
        
        uint256 totalSpotsAccumulated = amt_FCFS + amt_VL + tokensToLock.length;
        emit placeOrder_(msg.sender, totalSpotsAccumulated);
    }
    
    function claimRefund(
        refundInfo memory info
    ) external {
        require(state == currentState.REFUND, "Refund not started yet");
        require(!hasClaimedRefund[msg.sender], "Refund already claimed");
        verifyReturnInfoSignature(info);
        isSignatureUsed[info.signature] = true;
        hasClaimedRefund[msg.sender] = true;
        uint256 amtUnallocated = resByAddr_VL[msg.sender] + resByAddr_FCFS[msg.sender] - info.amtAllocated;
        payable(msg.sender).transfer(amtUnallocated * PRICE_PER_RES);
        emit claimRefund_(msg.sender, amtUnallocated);
    }
    
    function releaseRavendale(address[] calldata lockers) external onlyOwner {
        require(state == currentState.RETURN, "Return not started yet");
        for(uint256 j=0; j<lockers.length; j++){
            uint[] memory tokensToReturn = tokenLockedBy[lockers[j]];
            for(uint i=0; i<tokensToReturn.length; i++){
                ravendale.safeTransferFrom(address(this), lockers[j], tokensToReturn[i]);
                emit releaseRavendale_(lockers[j], tokensToReturn[i]);
            }
        }
        delete tokenLockedBy[msg.sender];
    }

    function verifyOrderInfoSignature(orderInfo memory info) internal view {
        require(getSignerForAllowList(info) == designatedSigner, "Invalid info");
        require(block.timestamp < info.nonce + SIGNATURE_VALIDITY, "Expired Nonce");
        require(!isSignatureUsed[info.signature], "Nonce already used");
        require(info.userAddress == msg.sender, "Invalid user address");
    }
    
    function verifyReturnInfoSignature(refundInfo memory info) internal view {
        require(getSignerForReturnList(info) == designatedSigner, "Invalid info");
        require(block.timestamp < info.nonce + SIGNATURE_VALIDITY, "Expired Nonce");
        require(!isSignatureUsed[info.signature], "Nonce already used");
        require(info.userAddress == msg.sender, "Invalid user address");
    }
    
    function withdraw() external onlyOwner {
        require(state == currentState.WITHDRAW, "Withdraw not started yet");
        uint256 balance = MAX_AMT_FOR_RES * PRICE_PER_RES;
        if (balance > address(this).balance) {
            balance = address(this).balance;
        }
        payable(msg.sender).transfer(balance);
    }
    
    // Setters
    function openWithdraw() external onlyOwner onlyOnce(currentState.WITHDRAW) {
        isStateSet[abi.encodePacked(currentState.WITHDRAW)] = true;
        state = currentState.WITHDRAW;
    }
    
    function openReservation() external onlyOwner onlyOnce(currentState.LIVE) {
        isStateSet[abi.encodePacked(currentState.LIVE)] = true;
        state = currentState.LIVE;
        emit openReservation_();
    }
    
    function closeReservation() external onlyOwner onlyOnce(currentState.OVER) {
        isStateSet[abi.encodePacked(currentState.OVER)] = true;
        state = currentState.OVER;
        emit closeReservation_();
    }
    
    function startRefund() external onlyOwner {
        isStateSet[abi.encodePacked(currentState.REFUND)] = true;
        state = currentState.REFUND;
        emit startRefund_();
    }
    
    function startReturn() external onlyOwner {
        isStateSet[abi.encodePacked(currentState.RETURN)] = true;
        state = currentState.RETURN;
        emit startReturn_();
    }
    
    function setReservationPrice(uint256 _PRICE_PER_RES) external onlyOwner {
        PRICE_PER_RES = _PRICE_PER_RES;
    }
    
    function setDesignatedSigner(address _designatedSigner) external onlyOwner {
        designatedSigner = _designatedSigner;
    }
    
    function setRavendale(address _ravendaleAddr) external onlyOwner {
        ravendale = IERC721(_ravendaleAddr);
    }
    
    // Getters
    
    function getTokensLockedByAddr(address _addr) external view returns(uint[] memory){
        return tokenLockedBy[_addr];
    }
    
    function getTotalTokensLockedByAddr(address _addr) external view returns(uint){
        return tokenLockedBy[_addr].length;
    }
    
    function getTokensLockedByAddrAt(address _addr, uint _index) external view returns(uint){
        return tokenLockedBy[_addr][_index];
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
    

