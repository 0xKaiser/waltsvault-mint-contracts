// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

//....................................................................................
//....................................................................................
//....................................................................................
//.............................▒██▓.....................................[K0K0'23].....
//........▓█████▒.............▓██▓....................................................
//.......▓██▓▒▓██▓...▒██▓....▓██▓.....................................................
//.......███▒..███▒..▒███....███...▓███.....▓███....▓███████████.▓██..▓██████▓........
//........▓▓▒...███..▓███...▓██▒...████▓.....███....▒▓...███...▓.▓▓..███▒..▓█▓........
//..............▓██▒.████▒.▒███...▒█████.....███.........███.........███▒.............
//..............▒███▒█████.███▒...███▒██▓....███.........███..........▓███▓▒..........
//...............█████████▓███....██▓.███....███.........███.........▓▒.▒▓███▓........
//...............▒████▓▒█████▒...▓███████▒...███.........███........▓██▓...▒███.......
//................████▒.█████....███▓▓▓███...███.........███........███▒....███.......
//................▓███..▓███▒...▓██▒...▓██▒..████████▓...███.........████▓████▒.......
//................▒███..▒███...▒▓▓▓▒...▓▓▓▓.▒▓▓▓▓▓▓▓▓▓..▒▓▓▓▒.........▒▓▓▓▓▓▒.........
//................▓███..▓███..........................................................
//....................................................................................
//...........▒▒▒▒..........▒███▒......................................................
//.........▒██████▓.......▒██▓........................................................
//.........███..▒██▓......███.........................................................
//.........▓██▒..▓██▒....▓██▒...████....▓██▒....███..▓██▒.....█▓▓▓███▓▓█▓.............
//................███...▒██▓...▒████▒...▓██▒....▓██..▓██▒.........██▓.................
//................▓██▒..▓██▒...▓█████...▓██▒....▓██..▓██▒.........██▓.................
//.................███.▒██▓...▒██▒▒██▒..▓██▒....▓██..▓██▒.........██▓.................
//.................▓██▒███....▓██▒.██▓..▓██▒....▓██..▓██▒.........██▓.................
//.................▒█████▓....████████▒.▒██▓....███..▓██▒.........██▓.................
//..................█████....▓██▒..▒██▓..███▒..▓██▒..▓██▒.........██▓.................
//..................▓███▓...▒███....███▒..▓██████▒...▓████████▒...███.................
//..................▒███▒...▒▒▒▒....▒▒▒▒....▒▒▒......▒▒▒▒▒▒▒▒▒....▒▒▒.................
//..................▓▓▓▓▒.............................................................
//....................................................................................
//....................................................................................
//................▓▒▒ a ~ land ~ far ~ far ~ away ~ yet ~ so ~ near ▒▒▓...............
//....................................................................................
//....................................dream.a.little..................................
//....................................................................................


import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IMerkel} from "./Interfaces/IMerkel.sol";
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
	
	address public treasury;
	address public designatedSigner;
	uint256 public totalWithdrawal;
	uint256 public PRICE_PER_RES;
	uint256 public MAX_RES_PER_ADDR_FCFS;
	uint256 public MAX_RES_PER_ADDR_VL;
	uint256 public MAX_AMT_FOR_RES;
	uint256 public SIGNATURE_VALIDITY;
	
	address[] private FCFS_Reservers_List;
	address[] private VL_Reservers_List;
	mapping(address => uint256) public resByAddr_FCFS;
	mapping(address => uint256) public resByAddr_VL;
	mapping(address => uint256[]) private tokensLockedBy;
	mapping(uint256 => address) public lockerOf;
	mapping(bytes => bool) private isSignatureUsed;
	mapping(address => bool) public hasClaimedRefund;
	mapping(address => bool) public controllers;
	
	function initialize(
		address _ravendaleAddr,
		address _designatedSigner,
		address _treasury
	) external initializer {
		__Ownable_init();
		__Signer_init();
		state = currentState.NOT_LIVE;
		designatedSigner = _designatedSigner;
		treasury = _treasury;
		PRICE_PER_RES = 0.0928 ether;
		MAX_RES_PER_ADDR_FCFS = 2;
		MAX_RES_PER_ADDR_VL = 2;
		MAX_AMT_FOR_RES = 7928;
		SIGNATURE_VALIDITY = 5 minutes;
		ravendale = IERC721Upgradeable(_ravendaleAddr);
	}
	
	/**
		* @dev Function is used to place an order for reservation
        * @param tokensToLock Array of tokenIds to lock
        * @param info Order info
        * @param amt_VL Amount of tokens to reserve in Vault List
        * @param amt_FCFS Amount of tokens to reserve in First Come First Serve List
     */
	function placeOrder(
		uint256[] calldata tokensToLock,
		orderInfo memory info,
		uint256 amt_VL,
		uint256 amt_FCFS
	) external payable {
		
		if(tokensToLock.length > 0){
			
			for(uint256 i=0; i<tokensToLock.length; i++){
				tokensLockedBy[msg.sender].push(tokensToLock[i]);
				lockerOf[tokensToLock[i]] = msg.sender;
				ravendale.safeTransferFrom(msg.sender, address(this), tokensToLock[i]);
				
				emit LockRavendale(msg.sender, tokensToLock[i]);
			}
		}
		
		require(msg.value == (amt_FCFS + amt_VL) * PRICE_PER_RES, "Incorrect payment");
		
		if(amt_VL > 0){
			uint256 maxAllowedAmt_VL = (tokensToLock.length + tokensLockedBy[msg.sender].length
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
	
	/**
		* @dev Function is used to claim the refund for the unallocated tokens
        * @param info Order info
     */
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
	/**
		* @dev Function is used to release the Ravendale tokens to the reservers
        * @param lockers Array of reservers
     */
	function releaseRavendale(
		address[] calldata lockers
	) external onlyOwner {
		for(uint256 j=0; j<lockers.length; j++){
			uint256[] memory tokensToReturn = tokensLockedBy[lockers[j]];
			for(uint256 i=0; i<tokensToReturn.length; i++){
				ravendale.safeTransferFrom(address(this), lockers[j], tokensToReturn[i]);
				lockerOf[tokensToReturn[i]] = address(0);
				delete tokensLockedBy[lockers[j]];
				emit ReleaseRavendale(lockers[j], tokensToReturn[i]);
			}
		}
	}
	
	/**
		* @dev Function is used to withdraw the funds from the contract
     */
	function withdraw() external onlyOwner {
		uint256 pending = MAX_AMT_FOR_RES * PRICE_PER_RES - totalWithdrawal;
		if (pending > address(this).balance) {
			pending = address(this).balance;
		}
		totalWithdrawal += pending;
		payable(treasury).transfer(pending);
	}
	
	/**
		* @dev Function is used to start the reservation
     */
	function openReservation() external onlyOwner {
		state = currentState.LIVE;
		emit OpenReservation();
	}
	
	/**
		* @dev Function is used to close the reservation
     */
	function closeReservation() external onlyOwner {
		state = currentState.OVER;
		emit CloseReservation();
	}
	
	/**
		* @dev Function is used to start the refund process
     */
	function openRefundClaim() external onlyOwner {
		state = currentState.REFUND;
		emit OpenRefundClaim();
	}
	
	// Setters
	/**
		* @dev Function is used to set the max reservation per address
        * @param maxResPerAddr_VL Max reservation per address for Vault List
        * @param maxResPerAddr_FCFS Max reservation per address for First Come First Serve
     */
	function setMaxResPerAddr(
		uint256 maxResPerAddr_VL,
		uint256 maxResPerAddr_FCFS
	) external onlyOwner {
		MAX_RES_PER_ADDR_VL = maxResPerAddr_VL;
		MAX_RES_PER_ADDR_FCFS = maxResPerAddr_FCFS;
	}
	
	/**
		* @dev Function is used to set the controllers address
        * @param _controllers Address of the controllers
     */
	function toggleControllers(address _controllers) external onlyOwner {
		controllers[_controllers] = !controllers[_controllers];
	}
	
	/**
		* @dev Function is used to set the treasury address
        * @param _treasury the treasury address
     */
	function setTreasury(address _treasury) external onlyOwner {
		treasury = _treasury;
	}
	
	/**
		* @dev Function is used to set the reservation price
        * @param resPrice Max allowed amount for Vault List
     */
	function setReservationPrice(uint256 resPrice) external onlyOwner {
		PRICE_PER_RES = resPrice;
	}
	
	/**
		* @dev Function is used to set the designated signer address
        * @param _designatedSigner Address of the designated signer
     */
	function setDesignatedSigner(address _designatedSigner) external onlyOwner {
		designatedSigner = _designatedSigner;
	}
	
	/**
		* @dev Function is used to set the Ravendale address
        * @param ravendaleAddr Address of the Walts Vault NFT
     */
	function setRavendale(address ravendaleAddr) external onlyOwner {
		ravendale = IERC721Upgradeable(ravendaleAddr);
	}
	
	/**
		* @dev Function is used to set the max amount for reservation
        * @param maxAmtForRes Max allowed amount for reservation
     */
	function setMaxAmtForRes(uint256 maxAmtForRes) external onlyOwner {
		require(state == currentState.NOT_LIVE);
		MAX_AMT_FOR_RES = maxAmtForRes;
	}
	
	/**
		* @dev Function is used to set the max amount for signature verification
        * @param validityTime Time for which the signature is valid
     */
	function setSignatureValidityTime(uint256 validityTime) external onlyOwner {
		SIGNATURE_VALIDITY = validityTime;
	}
	
	// Getter
	function getTokensLockedByAddr(address addr) external view returns(uint256[] memory){
		return tokensLockedBy[addr];
	}
	
	function getTotalTokensLocked(address addr) external view returns(uint256){
		require(controllers[msg.sender], "Not controllers");
		return tokensLockedBy[addr].length;
	}
	
	function getTokenLockedByIndex(address addr, uint256 index) external view returns(uint256){
		require(controllers[msg.sender], "Not controllers");
		return tokensLockedBy[addr][index];
	}
	
	function getAllVL_Reservers() external view returns(address[] memory){
		require(controllers[msg.sender], "Not controllers");
		return VL_Reservers_List;
	}
	
	function getTotalVL_Reservers() external view returns(uint256){
		require(controllers[msg.sender], "Not controllers");
		return VL_Reservers_List.length;
	}
	
	function getVL_ReserverByIndex(uint256 index) external view returns(address){
		require(controllers[msg.sender], "Not controllers");
		return VL_Reservers_List[index];
	}
	
	function getAllFCFS_Reservers() external view returns(address[] memory){
		require(controllers[msg.sender], "Not controllers");
		return FCFS_Reservers_List;
	}
	
	function getTotalFCFS_Reservers() external view returns(uint256){
		require(controllers[msg.sender], "Not controllers");
		return FCFS_Reservers_List.length;
	}
	
	function getFCFS_ReserverByIndex(uint256 index) external view returns(address){
		require(controllers[msg.sender], "Not controllers");
		return FCFS_Reservers_List[index];
	}
	
	function getBalAndLockedTokensOf(address user) external view returns(uint256, uint256){
		return (ravendale.balanceOf(user), tokensLockedBy[user].length);
	}
	
	// Internal
	/**
		* @dev Function is used to verify the signature of the order info
        * @param info Order info
     */
	function verifyOrderInfoSignature(orderInfo memory info) internal view {
		require(getSignerOrder(info) == designatedSigner, "Unauthorised signer");
		require(block.timestamp < info.nonce + SIGNATURE_VALIDITY, "Expired nonce");
		require(!isSignatureUsed[info.signature], "Used signature");
		require(info.userAddress == msg.sender, "Invalid address");
	}
	
	/**
		* @dev Function is used to verify the signature of the refund info
        * @param info Refund info
     */
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
