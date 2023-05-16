// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

////....................................................................................
////....................................................................................
////.............................▒██▓.....................................[K0K0'23].....
////........▓█████▒.............▓██▓....................................................
////.......▓██▓▒▓██▓...▒██▓....▓██▓.....................................................
////.......███▒..███▒..▒███....███...▓███.....▓███....▓███████████.▓██..▓██████▓........
////........▓▓▒...███..▓███...▓██▒...████▓.....███....▒▓...███...▓.▓▓..███▒..▓█▓........
////..............▓██▒.████▒.▒███...▒█████.....███.........███.........███▒.............
////..............▒███▒█████.███▒...███▒██▓....███.........███..........▓███▓▒..........
////...............█████████▓███....██▓.███....███.........███.........▓▒.▒▓███▓........
////...............▒████▓▒█████▒...▓███████▒...███.........███........▓██▓...▒███.......
////................████▒.█████....███▓▓▓███...███.........███........███▒....███.......
////................▓███..▓███▒...▓██▒...▓██▒..████████▓...███.........████▓████▒.......
////................▒███..▒███...▒▓▓▓▒...▓▓▓▓.▒▓▓▓▓▓▓▓▓▓..▒▓▓▓▒.........▒▓▓▓▓▓▒.........
////................▓███..▓███..........................................................
////....................................................................................
////...........▒▒▒▒..........▒███▒......................................................
////.........▒██████▓.......▒██▓........................................................
////.........███..▒██▓......███.........................................................
////.........▓██▒..▓██▒....▓██▒...████....▓██▒....███..▓██▒.....█▓▓▓███▓▓█▓.............
////................███...▒██▓...▒████▒...▓██▒....▓██..▓██▒.........██▓.................
////................▓██▒..▓██▒...▓█████...▓██▒....▓██..▓██▒.........██▓.................
////.................███.▒██▓...▒██▒▒██▒..▓██▒....▓██..▓██▒.........██▓.................
////.................▓██▒███....▓██▒.██▓..▓██▒....▓██..▓██▒.........██▓.................
////.................▒█████▓....████████▒.▒██▓....███..▓██▒.........██▓.................
////..................█████....▓██▒..▒██▓..███▒..▓██▒..▓██▒.........██▓.................
////..................▓███▓...▒███....███▒..▓██████▒...▓████████▒...███.................
////..................▒███▒...▒▒▒▒....▒▒▒▒....▒▒▒......▒▒▒▒▒▒▒▒▒....▒▒▒.................
////..................▓▓▓▓▒.............................................................
////....................................................................................
////....................................................................................
////..........▓▒▒ Once you open the Vault ~ imagination is the only limit ▒▒▓...........
////....................................................................................
////....................................dream.a.little..................................
////....................................................................................

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IWaltsVaultNFT} from "./Interfaces/IWaltsVaultNFT.sol";
import {IMerkel} from "./Interfaces/IMerkel.sol";
import {Signer} from "./utils/Signer.sol";

contract WaltsVaultMintController is OwnableUpgradeable, Signer, PausableUpgradeable {
	
	IWaltsVaultNFT public ravendale;
	IWaltsVaultNFT public waltsVault;
	
	address public TREASURY;
	address public AUTHORISED_SIGNER;
	
	uint8 public MAX_MINTS_PER_TOKEN_RD;
	uint8 public MAX_MINTS_PER_SPOT_VL;
	
	uint16 public MAX_MINTS_PER_ADDR_PUBLIC;
	uint16 public MAX_AMOUNT_FOR_SALE;
	uint16 public AVAILABLE_AMOUNT_FOR_VL;
	uint16 public SIGNATURE_VALIDITY;
	
	uint32 public START_TIME_RD;
	uint32 public END_TIME_RD;
	uint32 public START_TIME_VL;
	uint32 public END_TIME_VL;
	uint32 public START_TIME_PUBLIC;
	uint32 public END_TIME_PUBLIC;
 
	uint256 public PRICE;
	
	uint16 public amountSold;
	mapping(address => uint256) public rdMintsBy;
	mapping(address => uint256) public vlMintsBy;
	mapping(address => uint256) public publicMintsBy;
    mapping(address => uint256[]) private tokensLockedBy;
	mapping(uint256 => address) public lockerOf;
    mapping(bytes => bool) private isSignatureUsed;
	
	event RavendaleClaim(address indexed _claimer, uint256 indexed _tokenId);
	event RavendaleMint(address _minter, uint256 indexed _amount);
	event VaultListMint(address _minter, uint256 indexed _amount);
	event PublicMint(address _minter, uint256 indexed _amount);
	event ReleaseRavendale(address indexed _receiver, uint256 indexed _tokenId);
	
	
	function initialize() external initializer {
		__Ownable_init();
		__Signer_init();
		__Pausable_init();
		
		ravendale = IWaltsVaultNFT(0xf83A99E084C1D575AF8e12FF492F5E6C7b768b48);
		waltsVault = IWaltsVaultNFT(0x9980b3aA61114B07A7604FfDC7C7D04bb6D8d735);
                
		TREASURY = 0x2F86b325E8FfeE20703C93A8F28Ab7a5Dd711b7E;
        AUTHORISED_SIGNER = 0xA4CC419dB3F709B2E2f3f9Eb06B6cEC14DeDdDC6;
		SIGNATURE_VALIDITY = uint16(5 minutes);
		
        PRICE = 0.0628 ether;
		MAX_MINTS_PER_TOKEN_RD = uint8(1);
		MAX_MINTS_PER_SPOT_VL = uint8(1);
		MAX_MINTS_PER_ADDR_PUBLIC = uint16(2);
		MAX_AMOUNT_FOR_SALE = uint16(5960);
		AVAILABLE_AMOUNT_FOR_VL = MAX_AMOUNT_FOR_SALE - uint16(928);
		
		START_TIME_RD = uint32(1683118800);
        END_TIME_RD = START_TIME_RD + uint32(8 hours);
        START_TIME_VL = START_TIME_RD;
        END_TIME_VL = END_TIME_RD;
        START_TIME_PUBLIC = END_TIME_VL;
        END_TIME_PUBLIC = START_TIME_PUBLIC + uint32(100 days);
	}
	
	function mint(
        uint16 amountRD,
		uint16 amountVL,
		uint16 amountPUBLIC,
		uint256[] calldata tokensToLockRD,
		signedData memory spotsDataVL
	) external payable whenNotPaused {
        uint256 amountTOTAL = amountRD + amountVL + amountPUBLIC;

        require(PRICE * amountTOTAL == msg.value, "mint: unacceptable payment");

        require(MAX_AMOUNT_FOR_SALE  >= amountSold + amountTOTAL, "mint: unacceptable amount");

        if(tokensToLockRD.length > 0){
            _ravendaleMint(amountRD, tokensToLockRD);
		}
		
		if(amountVL > 0){
            _vaultListMint(amountVL, spotsDataVL);
		}
		
		if(amountPUBLIC > 0){
            _publicMint(amountPUBLIC);
		}

		amountSold += uint16(amountTOTAL);
	}


    // ======== INTERNAL FUNCTIONS ======== //

	function _ravendaleMint(
		uint16 amountRD,
		uint256[] calldata tokensToLockRD
	) internal {
		require(START_TIME_VL <= block.timestamp, "ravendale: sale not started");
		for(uint256 i=0; i<tokensToLockRD.length; i++){
			tokensLockedBy[msg.sender].push(tokensToLockRD[i]);
			lockerOf[tokensToLockRD[i]] = msg.sender;
			
			ravendale.safeTransferFrom(msg.sender, address(this), tokensToLockRD[i]);
			waltsVault.safeTransferFrom(address(this), msg.sender, tokensToLockRD[i]);
			
			emit RavendaleClaim(msg.sender, tokensToLockRD[i]);
		}
		
		if(amountRD > 0){
			require(END_TIME_VL >= block.timestamp, "ravendale: sale over");
			require(MAX_MINTS_PER_TOKEN_RD * tokensToLockRD.length >= amountRD, "ravendale: unacceptable amount");
			rdMintsBy[msg.sender] += amountRD;
			
			(address[] memory receiver, uint256[] memory AmountRD) = _getArray(msg.sender, amountRD);
			waltsVault.airdrop(receiver, AmountRD);
			
			emit RavendaleMint(msg.sender, amountRD);
		}
		
		AVAILABLE_AMOUNT_FOR_VL += uint16(tokensToLockRD.length) - amountRD;
	}

	function _vaultListMint(
		uint16 amountVL,
		signedData memory spotsDataVL
	) internal {
		require(START_TIME_VL <= block.timestamp, "vault list: sale not started");
		require(block.timestamp <= END_TIME_VL, "vault list: sale over");
		require(amountVL <= AVAILABLE_AMOUNT_FOR_VL, "vault list: unavailable amount");
		
		require(block.timestamp < spotsDataVL.nonce + SIGNATURE_VALIDITY, "vault list: expired nonce");
		require(getSigner(spotsDataVL) == AUTHORISED_SIGNER, "vault list: unauthorised signer");
		require(!isSignatureUsed[spotsDataVL.signature], "vault list: used signature");
		require(spotsDataVL.userAddress == msg.sender, "vault list: unauthorised address");
	
		require(MAX_MINTS_PER_SPOT_VL * spotsDataVL.allocatedSpots >= vlMintsBy[msg.sender] + amountVL, "vault list: unacceptable amount");
	
		isSignatureUsed[spotsDataVL.signature] = true;
		vlMintsBy[msg.sender] += amountVL;
		AVAILABLE_AMOUNT_FOR_VL -= amountVL;
		
		(address[] memory receiver, uint256[] memory AmountVL) = _getArray(spotsDataVL.userAddress, amountVL);
		waltsVault.airdrop(receiver, AmountVL);
	
		emit VaultListMint(msg.sender, amountVL);
	}
	
	function _publicMint(
		uint16 amountPUBLIC
	) internal {
		require(START_TIME_PUBLIC <= block.timestamp, "public: sale not started");
		require(END_TIME_PUBLIC >= block.timestamp, "public: sale over");
		require(MAX_MINTS_PER_ADDR_PUBLIC >= publicMintsBy[msg.sender] + amountPUBLIC, "public: unacceptable amount");
		publicMintsBy[msg.sender] += amountPUBLIC;
		
		(address[] memory receiver, uint256[] memory amount) = _getArray(msg.sender, amountPUBLIC);
		waltsVault.airdrop(receiver, amount);
		
		emit PublicMint(msg.sender, amountPUBLIC);
	}
	
	
	function _getArray(address userAddress, uint256 totalTokens) internal pure returns (address[] memory addressArray, uint256[] memory tokenArray) {
		addressArray = new address[](1);
		tokenArray = new uint256[](1);
		addressArray[0] = userAddress;
		tokenArray[0] = totalTokens;
	}
	

	// ======== OWNER FUNCTIONS ======== //
	
	/**
       * @notice The function is used to pause/ unpause mint functions
    */
	function togglePause() external onlyOwner {
		if (paused()) {
			_unpause();
		} else {
			_pause();
		}
	}
        
	function releaseRavendale(
		address[] calldata lockers
	) external onlyOwner {
		for(uint256 j=0; j<lockers.length; j++){
			uint256[] memory tokensToRelease = tokensLockedBy[lockers[j]];
			delete tokensLockedBy[lockers[j]];
				for(uint256 i=0; i<tokensToRelease.length; i++){
					lockerOf[tokensToRelease[i]] = address(0);
					ravendale.safeTransferFrom(address(this), lockers[j], tokensToRelease[i]);
					emit ReleaseRavendale(lockers[j], tokensToRelease[i]);
			}
		}
	}
	
	function withdraw() external onlyOwner {
		payable(TREASURY).transfer(address(this).balance);
	}
	
    function setRavendaleAddr(address _ravendale) external onlyOwner {
	    ravendale = IWaltsVaultNFT(_ravendale);
	}

    function setWaltsVaultAddr(address _waltsVault) external onlyOwner {
        waltsVault = IWaltsVaultNFT(_waltsVault);
    }
	
	function setTreasury(address _treasury) external onlyOwner {
		TREASURY = _treasury;
	}
	
	function setAuthorisedSigner(address _signer) external onlyOwner {
		AUTHORISED_SIGNER = _signer;
	}
	
	function setSignatureValidityTime(uint16 validityTime) external onlyOwner {
		SIGNATURE_VALIDITY = validityTime;
	}
	
	function setPrice(uint256 _price) external onlyOwner {
		PRICE = _price;
	}
	
	function setMaxAmtForSale(uint16 _amount) external onlyOwner {
		MAX_AMOUNT_FOR_SALE = _amount;
	}
	
	function setMaxMintsPerTokenRD(uint8 _amount) external onlyOwner {
		MAX_MINTS_PER_TOKEN_RD = _amount;
	}
	
	function setMaxMintsPerSpotVL(uint8 _amount) external onlyOwner {
		MAX_MINTS_PER_SPOT_VL = _amount;
	}
	
	function setMaxMintsPerAddrPublic(uint16 _amount) external onlyOwner {
		MAX_MINTS_PER_ADDR_PUBLIC = _amount;
	}
	
	function setStartEndTime(
		uint32 _startVL,
		uint32 _endVL,
		uint32 _startPB,
		uint32 _endPB,
		uint32 _startRD,
		uint32 _endRD
	) external onlyOwner {
		START_TIME_VL = _startVL;
		END_TIME_VL = _endVL;
		START_TIME_PUBLIC = _startPB;
		END_TIME_PUBLIC = _endPB;
		START_TIME_RD = _startRD;
		END_TIME_RD = _endRD;
	}
	
	// ======== READ FUNCTIONS ======== //

	function getTokensLockedByAddr(address addr) external view returns(uint256[] memory){
		return tokensLockedBy[addr];
	}
	
	function getTotalTokensLocked(address addr) external view returns(uint256){
		return tokensLockedBy[addr].length;
	}
	
	function getTokenLockedByIndex(address addr, uint256 index) external view returns(uint256){
		return tokensLockedBy[addr][index];
	}
	

	// ======== AUXILIARY FUNCTIONS ======== //

	function onERC721Received(
		address,
		address,
		uint256,
		bytes memory
	) public pure virtual returns (bytes4) {
		return this.onERC721Received.selector;
	}

	// ======== UPGRADE #01 ======== //
	
	function releaseRavendale() external {
		uint256[] memory tokensToRelease = tokensLockedBy[msg.sender];
		require(tokensToRelease.length > 0, "no tokens to release");
		delete tokensLockedBy[msg.sender];
		unchecked {
			for (uint256 i = 0; i < tokensToRelease.length; i++) {
				lockerOf[tokensToRelease[i]] = address(0);
				ravendale.safeTransferFrom(address(this), msg.sender, tokensToRelease[i]);
				emit ReleaseRavendale(msg.sender, tokensToRelease[i]);
			}
		}
	}
	
	
	// ======== UPGRADE #02 ======== //
	
	IMerkel public merkelToken;
	
	struct ravendaleClaimInfo {
		uint32 lastClaimTime;
		uint256 totalClaimed;
	}
	
	struct waltsVaultClaimInfo {
		uint8 rarity;
		uint32 lastClaimTime;
		uint256 totalClaimed;
		uint256 totalValueToClaim;
		uint256 minimumClaimAmount;
	}
	
	event ClaimedMerkel(address indexed claimer, uint256 indexed tokenId, uint256 indexed amount);
	event TokenBurnt(address indexed user, uint256 indexed tokenId);
	event StakeRavendale(address indexed user, uint256 indexed tokenId);
	
	uint256 public vestingStartTime;
	uint256 public merkelAllocationPerToken;
	uint256 public minClaimInterval;
	uint256 public minAmtClaimedPerInterval;
	uint256 public baseAmount;
	uint256 public minimumInterval;
	uint256 public vestingPeriod;
	bool public isBurningEnabled;
	
	
	mapping(uint256 => ravendaleClaimInfo) public ravendaleClaimInfoByTokenId;
	mapping(uint256 => waltsVaultClaimInfo) public waltsVaultClaimInfoByTokenId;
	mapping(address => uint16[]) private tokensBurntByUser;
	mapping(uint256=>uint256) public rarityMultiplier;
	uint256[] public packedMultipliers;
	
	
	// Claim Merkle tokens
	function getRarity(uint256 tokenId) internal view returns(uint256) {
		uint256 arrIndex = (tokenId-1) / 64;
		uint256 bitIndex = ((tokenId-1) % 64) * 4;
		
		uint256 arrElem = packedMultipliers[arrIndex];
		uint256 temp = arrElem << bitIndex;
		uint256 rarity = temp >> 252;
		return rarity;
	}
	
	/**
		* @dev Function is used to claim Merkel tokens
    */
	function ravendaleClaim() internal returns(uint256 totalUnclaimed) {
		for (uint256 i=0; i<tokensLockedBy[msg.sender].length; i++){
			uint256 tokenId = tokensLockedBy[msg.sender][i];
			require(lockerOf[tokenId] == msg.sender, "Not Locked");
			if (ravendaleClaimInfoByTokenId[tokenId].lastClaimTime == 0){
				ravendaleClaimInfoByTokenId[tokenId].lastClaimTime = uint32(vestingStartTime);
			}
			uint256 timePassed = block.timestamp - ravendaleClaimInfoByTokenId[tokenId].lastClaimTime;
			uint256 totalIntervalsPassed = timePassed / minClaimInterval;
			uint256 totalToClaim = totalIntervalsPassed * minAmtClaimedPerInterval;
			if (totalToClaim > merkelAllocationPerToken - ravendaleClaimInfoByTokenId[tokenId].totalClaimed){
				totalToClaim = merkelAllocationPerToken - ravendaleClaimInfoByTokenId[tokenId].totalClaimed;
			}
			ravendaleClaimInfoByTokenId[tokenId].lastClaimTime += uint32(totalIntervalsPassed * minClaimInterval);
			ravendaleClaimInfoByTokenId[tokenId].totalClaimed += totalToClaim;
			totalUnclaimed += totalToClaim;
			emit ClaimedMerkel(msg.sender, tokenId, totalToClaim);
		}
		require(totalUnclaimed > 0, "Nothing to claim");
		return totalUnclaimed;
	}
	
	/**
         * @dev Claims unclaimed Merkel token by the user
    */
	function waltsVaultClaim() internal returns(uint256 totalClaimed) {
		for(uint256 i=0; i<tokensBurntByUser[msg.sender].length;i++){
			uint16 tokenId = tokensBurntByUser[msg.sender][i];
			waltsVaultClaimInfo storage info = waltsVaultClaimInfoByTokenId[tokenId];
			uint256 timeElapsed = block.timestamp - info.lastClaimTime;
			uint256 totalClaim = timeElapsed / minimumInterval;
			uint256 totalValueToClaim = totalClaim * info.minimumClaimAmount;
			if(totalValueToClaim > info.totalValueToClaim - info.totalClaimed) {
				totalValueToClaim = info.totalValueToClaim - info.totalClaimed;
			}
			info.lastClaimTime = uint32(block.timestamp);
			info.totalClaimed += totalValueToClaim;
			totalClaimed += totalValueToClaim;
			emit ClaimedMerkel(msg.sender, tokenId, totalValueToClaim);
		}
		require(totalClaimed > 0, "Nothing to Claim");
		return totalClaimed;
	}
	
	/**
	  * @dev Function is used to get the unclaimed balance of a user
        * @param user The user address
        * @return The unclaimed balance
     */
	function getUnclaimedRavendaleBalance(address user) internal view returns(uint256) {
		uint256 totalUnclaimed;
		for (uint256 i=0; i<tokensLockedBy[user].length; i++){
			uint256 tokenId = tokensLockedBy[user][i];
			uint256 lastClaimTime;
			if (ravendaleClaimInfoByTokenId[tokenId].lastClaimTime == 0){
				lastClaimTime = vestingStartTime;
			} else {
				lastClaimTime = ravendaleClaimInfoByTokenId[tokenId].lastClaimTime;
			}
			uint256 timePassed = block.timestamp - lastClaimTime;
			uint256 totalIntervalsPassed = timePassed / minClaimInterval;
			uint256 totalToClaim = totalIntervalsPassed * minAmtClaimedPerInterval;
			if (totalToClaim > merkelAllocationPerToken - ravendaleClaimInfoByTokenId[tokenId].totalClaimed){
				totalToClaim = merkelAllocationPerToken - ravendaleClaimInfoByTokenId[tokenId].totalClaimed;
			}
			totalUnclaimed += totalToClaim;
		}
		return totalUnclaimed;
	}
	
	/**
		* @return Total unclaimed Merkel token by the user
         * @param user Address of the user
    */
	function getUnclaimedWaultVaultBalance(address user) internal view returns(uint256) {
		uint256 totalUnclaimed;
		for(uint256 i = 0; i < tokensBurntByUser[user].length; i++) {
			uint16 tokenId = tokensBurntByUser[user][i];
			waltsVaultClaimInfo memory info = waltsVaultClaimInfoByTokenId[tokenId];
			uint256 timeElapsed = block.timestamp - info.lastClaimTime;
			uint256 totalClaim = timeElapsed / minimumInterval;
			uint256 totalValueToClaim = totalClaim * info.minimumClaimAmount;
			if(totalValueToClaim > info.totalValueToClaim - info.totalClaimed) {
				totalValueToClaim = info.totalValueToClaim - info.totalClaimed;
			}
			totalUnclaimed += totalValueToClaim;
		}
		return totalUnclaimed;
	}
	
	function claimMerkelTokens() external {
		uint256 totalUnclaimed;
		if (tokensLockedBy[msg.sender].length > 0){
			totalUnclaimed += ravendaleClaim();
		}
		
		if(tokensBurntByUser[msg.sender].length > 0) {
			totalUnclaimed += waltsVaultClaim();
		}
		
		require(totalUnclaimed > 0, "Nothing to claim");
		merkelToken.transfer(msg.sender, totalUnclaimed);
	}
	
	/**
	     * @dev Burns the WaltsVault NFT and registers the user for claiming Merkel token
         * @param tokenIds Array of tokenIds
    */
	function burnToClaim(uint256[] calldata tokenIds) external {
		require(isBurningEnabled, "Burning is not enabled");
		for(uint256 i = 0; i < tokenIds.length; i++) {
			require(waltsVault.ownerOf(tokenIds[i]) == msg.sender, "Not Owner");
			uint256 rarity = getRarity(tokenIds[i]);
			uint256 totalAmount = baseAmount * rarityMultiplier[rarity];
			tokensBurntByUser[msg.sender].push(uint16(tokenIds[i]));
			waltsVaultClaimInfoByTokenId[tokenIds[i]] = waltsVaultClaimInfo({
				rarity: uint8(rarity),
				lastClaimTime: uint32(block.timestamp),
				totalClaimed: 0,
				totalValueToClaim: totalAmount,
				minimumClaimAmount: totalAmount / vestingPeriod
			});
			waltsVault.burnToken(tokenIds[i]);
			emit TokenBurnt(msg.sender, tokenIds[i]);
		}
	}
	
	function stakeRavendales(uint256[] calldata tokenIds) external {
		for(uint256 i = 0; i < tokenIds.length; i++) {
			require(ravendale.ownerOf(tokenIds[i]) == msg.sender, "Not Owner");
			require(lockerOf[tokenIds[i]] == address(0), "Already Locked");
			lockerOf[tokenIds[i]] = msg.sender;
			tokensLockedBy[msg.sender].push(tokenIds[i]);
			ravendale.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
			emit StakeRavendale(msg.sender, tokenIds[i]);
		}
	}
	
	
	function setMerkelToken(address _merkelToken) external onlyOwner {
		merkelToken = IMerkel(_merkelToken);
	}
	
	function setPackedMultipliers(uint256[] calldata _packedData) external {
		for (uint i=0; i<_packedData.length; i++){
			packedMultipliers.push(_packedData[i]);
		}
	}
	
	
	// Getter
	function getTotalUnclaimedBalance(address user) external view returns(uint256) {
		return getUnclaimedRavendaleBalance(user) + getUnclaimedWaultVaultBalance(user);
	}
	
}
