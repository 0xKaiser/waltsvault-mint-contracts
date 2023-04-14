// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Ownable} from
"@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from
"@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Signer} from "./utils/Signer.sol";

contract ReserveForMint is Ownable, Signer {

    IERC721 public ravendale;
    
    enum currentstate {NOT_STARTED, STARTED, WITHDRAW, ENDED, REFUND, RETURN}
    currentstate public state;
    
    address public designatedSigner;
    uint256 public signatureExpiryTime = 3 minutes;
    uint public resPrice = 0.01 ether;
    uint public maxResPerAddr_FCFS = 2;
    uint public maxResPerSpot_VL = 2;
    uint256 constant public totalTokensAllocated = 1000;

    mapping(bytes => bool) private checkState;
    mapping(bytes => bool) private isSignatureUsed;
    mapping(address => uint) public resByAddr_FCFS;
    mapping(address => uint) public resByAddr_VL;
    mapping(address => uint[]) private tokensLockedByAddr;
    mapping(uint => address) public lockerAddrOf;
    mapping(address => bool) public refundClaimed;
    
    modifier onlyOnce(currentstate newState) {
        require(!checkState[abi.encodePacked(newState)], "Already started");
        _;
    }
    
    constructor(address _ravendaleAddr) {
        __Signer_init();
        ravendale = IERC721(_ravendaleAddr);
        state = currentstate.NOT_STARTED;
    }
    
    function placeOrder(
        uint256[] calldata tokensToLock,
        allowList memory signature,
        uint256 amt_VL,
        uint256 amt_FCFS
    ) external payable {
        if(tokensToLock.length > 0){
            require(state != currentstate.NOT_STARTED,"Participation not started yet");
            for(uint i=0; i<tokensToLock.length; i++){
                tokensLockedByAddr[msg.sender].push(tokensToLock[i]);
                lockerAddrOf[tokensToLock[i]] = msg.sender;
                ravendale.safeTransferFrom(msg.sender, address(this), tokensToLock[i]);
            }
        }
        
        require(msg.value == (amt_FCFS + amt_VL) * resPrice, "Incorrect amount sent");
        
        if(amt_VL > 0){
            uint maxAllowedAmt_VL = (tokensToLock.length + tokensLockedByAddr[msg.sender].length
                            + signature.allocatedSpots) * maxResPerSpot_VL;
            
            require(state == currentstate.STARTED,"Participation not started yet");
            require(maxAllowedAmt_VL >= resByAddr_VL[msg.sender] + amt_VL, "Exceeds max allowed reservation");
            
            verifyAllowListSignature(signature);
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
        returnList memory signature
    ) external {
        require(state == currentstate.REFUND, "Refund not started yet");
        require(!refundClaimed[msg.sender], "Refund already claimed");
        verifyReturnListSignature(signature);
        isSignatureUsed[signature.signature] = true;
        refundClaimed[msg.sender] = true;
        uint256 amtUnallocated = resByAddr_VL[msg.sender] + resByAddr_FCFS[msg.sender] - signature.tokensAllocated;
        payable(msg.sender).transfer(amtUnallocated * resPrice);
    }
    
    function returnRavendale(address[] calldata _user) external onlyOwner {
        require(state == currentstate.RETURN, "Return not started yet");
        for(uint256 j=0; j<_user.length; j++){
            uint[] memory tokensToReturn = tokensLockedByAddr[_user[j]];
            tokensToReturn = tokensLockedByAddr[_user[j]];
            for(uint i=0; i<tokensToReturn.length; i++){
                ravendale.safeTransferFrom(address(this), _user[j], tokensToReturn[i]);
            }
        }
    }

    function verifyAllowListSignature(allowList memory signature) internal view {
        require(getSignerForAllowList(signature) == designatedSigner, "Invalid signature");
        require(block.timestamp < signature.nonce + signatureExpiryTime, "Expired Nonce");
        require(!isSignatureUsed[signature.signature], "Nonce already used");
        require(signature.userAddress == msg.sender, "Invalid user address");
    }
    
    function verifyReturnListSignature(returnList memory signature) internal view {
        require(getSignerForReturnList(signature) == designatedSigner, "Invalid signature");
        require(block.timestamp < signature.nonce + signatureExpiryTime, "Expired Nonce");
        require(!isSignatureUsed[signature.signature], "Nonce already used");
        require(signature.userAddress == msg.sender, "Invalid user address");
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = totalTokensAllocated * resPrice;
        payable(msg.sender).transfer(balance);
    }
    
    function addETHForRefund() external payable onlyOwner {
        require(state == currentstate.ENDED, "Free participation not ended");
    }
    
    // Setters
    function setWithdraw() external onlyOwner onlyOnce(currentstate.WITHDRAW) {
        checkState[abi.encodePacked(currentstate.WITHDRAW)] = true;
        state = currentstate.WITHDRAW;
    }
    
    function openReservation() external onlyOwner onlyOnce(currentstate.STARTED) {
        checkState[abi.encodePacked(currentstate.STARTED)] = true;
        state = currentstate.STARTED;
    }
    
    function closeReservation() external onlyOwner onlyOnce(currentstate.ENDED) {
        checkState[abi.encodePacked(currentstate.ENDED)] = true;
        state = currentstate.ENDED;
    }
    
    function startRefund() external onlyOwner onlyOnce(currentstate.REFUND) {
        checkState[abi.encodePacked(currentstate.REFUND)] = true;
        state = currentstate.REFUND;
    }
    
    function startReturn() external onlyOwner onlyOnce(currentstate.RETURN) {
        checkState[abi.encodePacked(currentstate.RETURN)] = true;
        state = currentstate.RETURN;
    }
    
    function setReservationPrice(uint256 _resPrice) external onlyOwner {
        resPrice = _resPrice;
    }
    
    function setDesignatedSigner(address _designatedSigner) external onlyOwner {
        designatedSigner = _designatedSigner;
    }
    
    function setRavendale(address _ravendaleAddr) external onlyOwner {
        ravendale = IERC721(_ravendaleAddr);
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
    
    // Getters
    
    function getTokensLockedByAddr(address _addr) external view returns(uint[] memory){
        return tokensLockedByAddr[_addr];
    }
    
    function getTotalTokensLockedByUser() external view returns(uint){
        return tokensLockedByAddr[msg.sender].length;
    }
    
    function getTokensLockedByAddrAt(address _addr, uint _index) external view returns(uint){
        return tokensLockedByAddr[_addr][_index];
    }
    
}
    

