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
//..........▓▒▒ Once you open the Vault ~ imagination is the only limit ▒▒▓...........
//....................................................................................
//....................................dream.a.little..................................
//....................................................................................

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IWaltsVault} from "./Interfaces/IWaltsVault.sol";
import {Signer} from "./utils/Signer.sol";

contract WaltsVaultMintController is OwnableUpgradeable, Signer {
	
	IWaltsVault public RAVENDALE;
	IWaltsVault public WALTS_VAULT;
	
	address public TREASURY;
	address public AUTHORISED_SIGNER;
	
	uint8 public MAX_MINTS_PER_TOKEN_RD;
	uint8 public MAX_MINTS_PER_SPOT_VL;
	
	uint16 public MAX_MINTS_PER_ADDR_PUBLIC;
	uint16 public MAX_AMOUNT_FOR_SALE;
	uint16 public SIGNATURE_VALIDITY;
	
	uint32 public START_TIME_RD;
	uint32 public END_TIME_RD;
	uint32 public START_TIME_VL;
	uint32 public END_TIME_VL;
	uint32 public START_TIME_PUBLIC;
	uint32 public END_TIME_PUBLIC;
 
	uint256 public PRICE;
	
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
		
        RAVENDALE = IWaltsVault(0xf83A99E084C1D575AF8e12FF492F5E6C7b768b48);
		WALTS_VAULT = IWaltsVault(0x97EaE183E6CB0D192d5820494d694312bd5436b7);
                
		TREASURY = 0x97EaE183E6CB0D192d5820494d694312bd5436b7; 
        AUTHORISED_SIGNER = 0x97EaE183E6CB0D192d5820494d694312bd5436b7; 
		SIGNATURE_VALIDITY = uint16(5 minutes);
		
        PRICE = 0.0928 ether;
		MAX_MINTS_PER_TOKEN_RD = uint8(1);
		MAX_MINTS_PER_SPOT_VL = uint8(1);
		MAX_MINTS_PER_ADDR_PUBLIC = uint16(2);
		MAX_AMOUNT_FOR_SALE = uint16(5928);
		
		START_TIME_RD = uint32(1682830652);
        END_TIME_RD = START_TIME_RD + uint32(8 hours);
        START_TIME_VL = START_TIME_RD;
        END_TIME_VL = END_TIME_RD;
        START_TIME_PUBLIC = END_TIME_VL;
        END_TIME_PUBLIC = START_TIME_PUBLIC + uint32(100 days);
	}
	
	function mint(
        uint256 amountRD,
		uint256 amountVL,
		uint256 amountPUBLIC,
		uint256[] calldata tokensToLockRD,
		orderInfo memory spotsVL
	) external payable {
        uint256 amountTOTAL = amountRD + amountVL + amountPUBLIC;

        require(PRICE * amtTOTAL == msg.value, "mint: unacceptable payment");
        require(MAX_AMOUNT_FOR_SALE >= WALTS_VAULT.totalSupply() + amtTOTAL, "mint: unacceptable amount");

        if(tokensToLockRD.length){
            _ravendaleMint(amountRD, tokensToLockRD);
		}
		
		if(amountVL){
            _vaultListMint(amountVL, spotsDataVL);
		}
		
		if(amountPUBLIC){
            _publicMint(amountPUBLIC);
		}
	}


    // ======== INTERNAL FUNCTIONS ======== //

	function _ravendaleMint(
		uint256 amountRD,
		uint256[] calldata tokensToLockRD
	) internal {
		require(START_TIME_VL <= block.timestamp, "ravendale: sale not started");
		for(uint256 i=0; i<tokensToLockRD.length; i++){
			tokensLockedBy[msg.sender].push(tokensToLockRD[i]);
			lockerOf[tokensToLockRD[i]] = msg.sender;
			
			RAVENDALE.safeTransferFrom(msg.sender, address(this), tokensToLockRD[i]);
			WALTS_VAULT.safeTransferFrom(address(this), msg.sender, tokensToLockRD[i]);
			
			emit RavendaleClaim(msg.sender, tokensToLockRD[i]);
		}
		
		if(amountRD){
			require(END_TIME_VL >= block.timestamp, "ravendale: sale over");
			require(MAX_MINTS_PER_TOKEN_RD * tokensToLockRD.length >= amountRD, "ravendale: unacceptable amount");
			
//			WALTS_VAULT.airdrop(receivers, uint256(tokensToMint));
			rdMintsBy[msg.sender] += amountRD;
			emit RavendaleMint(msg.sender, amountRD);
		}
	}

	function _vaultListMint(
		uint256 amtVL,
		orderInfo memory spotsVL
	) internal {
		require(START_TIME_VL <= block.timestamp, "vault list: sale not started");
		require(block.timestamp <= END_TIME_VL, "vault list: sale over");
		
		require(block.timestamp < spotsVL.nonce + SIGNATURE_VALIDITY, "vault list: expired nonce");
		require(getSigner(spotsVL) == AUTHORISED_SIGNER, "vault list: unauthorised signer");
		require(!isSignatureUsed[spotsVL.signature], "vault list: used signature");		
		require(AUTHORISED_SIGNER == getSigner(spotsDataVL), "vault list: unauthorised signer");
		require(!isSignatureUsed[spotsDataVL.signature], "vault list: used signature");
		
		require(spotsDataVL.userAddress == msg.sender, "vault list: unauthorised address");
		require(MAX_MINTS_PER_SPOT_VL * spotsDataVL.allocatedSpots >= vlMintsBy[msg.sender] + amountVL, "vault list: unacceptable amount");
	
		isSignatureUsed[spotsVL.signature] = true;
		vlMintsBy[msg.sender] += amtVL;
		
//		WALTS_VAULT.airdrop([msg.sender], [amtVL]);
	
		emit VaultListMint(msg.sender, amountVL);
	}
	
	function _publicMint(
		uint256 amountPUBLIC
	) internal {
		require(START_TIME_PUBLIC <= block.timestamp, "public: sale not started");
		require(END_TIME_PUBLIC >= block.timestamp, "public: sale over");
		
		publicMintsBy[msg.sender] += amtPUBLIC;
//		WALTS_VAULT.airdrop([msg.sender], [amtPUBLIC]);
		require(MAX_MINTS_PER_ADDR_PUBLIC >= publicMintsBy[msg.sender] + amountPUBLIC, "public: unacceptable amount");
		
		emit PublicMint(msg.sender, amountPUBLIC);
	}

	// ======== OWNER FUNCTIONS ======== //
        
	function releaseRavendale(
		address[] calldata lockers
	) external onlyOwner {
		for(uint256 j=0; j<lockers.length; j++){
			uint256[] memory tokensToRelease = tokensLockedBy[lockers[j]];
				for(uint256 i=0; i<tokensToReturn.length; i++){
				RAVENDALE.safeTransferFrom(address(this), lockers[j], tokensToReturn[i]);
				lockerOf[tokensToReturn[i]] = address(0);
				delete tokensLockedBy[lockers[j]];
				emit ReleaseRavendale(lockers[j], tokensToRelease[i]);
			}
		}
	}
	
	function withdraw() external onlyOwner {
		payable(TREASURY).transfer(address(this).balance);
	}
	
    function setRavendaleAddr(address _ravendale) external onlyOwner {
		RAVENDALE = IWaltsVault(_ravendale);
	}

    function setWaltsVaultAddr(address _waltsVault) external onlyOwner {
        WALTS_VAULT = IWaltsVault(_waltsVault);
    }
	
	function setTreasury(address _treasury) external onlyOwner {
		TREASURY = _treasury;
	}
	
	function setAuthorisedSigner(address _signer) external onlyOwner {
		AUTHORISED_SIGNER = _signer;
	}
	
	function setSignatureValidityTime(uint16 validityTime) external onlyOwner {
		SIGNATURE_VALIDITY = validityTime;
	
	function setPrice(uint256 _price) external onlyOwner {
		PRICE = _price;
	}
	
	function setMaxAmtForSale(uint16 _amount) external onlyOwner {
		MAX_AMOUNT_FOR_SALE = _amount;
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
}
