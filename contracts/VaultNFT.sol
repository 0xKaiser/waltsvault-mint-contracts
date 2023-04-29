// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721AUpgradeable} from "./utils/ERC721AUpgradeable.sol";
import {RevokableOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableOperatorFiltererUpgradeable.sol";
import {RevokableDefaultOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableDefaultOperatorFiltererUpgradeable.sol";
import {UpdatableOperatorFilterer} from "./OpenseaRegistries/UpdatableOperatorFilterer.sol";
import {RaritySigner} from "./utils/RaritySigner.sol";
import {IMerkel} from "./Interfaces/IMerkel.sol";

contract VaultNFT is
    OwnableUpgradeable,
    ERC721AUpgradeable,
    RevokableDefaultOperatorFiltererUpgradeable,
    RaritySigner
{
    
    IMerkel public merkel;
    
    event ClaimedMerkel(address indexed claimer, uint256 indexed tokenId, uint256 indexed amount);
    event TokenBurnt(address indexed user, uint256 indexed tokenId);
    struct claimInfo {
        uint8 rarity;
        uint32 lastClaimTime;
        uint256 totalClaimed;
        uint256 totalValueToClaim;
        uint256 minimumClaimAmount;
    }
    
    string public baseURI;
    address public designatedSigner;
    bool public isBurningEnabled;
    uint32 public nonceValidityTime;
    uint256 public baseAmount;
    uint256 public minimumInterval;
    uint256 public vestingPeriod;
    uint256 public maxSupply;
    mapping(address => bool) public isController;
    mapping(uint16 => claimInfo) public claimInfos;
    // rarity => multiplier
    mapping(uint8 => uint256) public rarityMultiplier;
    mapping(address => uint16[]) private tokensBurntByUser;
    mapping(bytes => bool) public isSignatureUsed;

    modifier onlyController(address from) {
        require(isController[from], "Not a Controller");
        _;
    }
    
    function initialize(string memory name, string memory symbol, address _designatedSigner) external
    initializer {
        __Ownable_init();
        __ERC721A_init(name,symbol);
        __RevokableDefaultOperatorFilterer_init();
        __Signer_init();
        maxSupply = 8888;
        nonceValidityTime = 3 minutes;
        vestingPeriod = 90;
        designatedSigner = _designatedSigner;
    }
    
    /**
        * @dev This function is used to airdrop NFTs by minting them
        * @param to The address of the recipient
        * @param amount The amount of NFTs to mint
    */
    function airdrop(
        address[] calldata to, 
        uint256[] calldata amount
    ) external onlyController(msg.sender) {
        require(to.length == amount.length, "Invalid Input");
        for(uint256 i = 0; i < to.length; i++) {
            require(maxSupply >= totalSupply()+ amount[i]);
            _mint(to[i],amount[i]);
        }
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    // Contract Setters
    function setNonceValidityTime(uint32 _nonceValidityTime) public onlyOwner {
        nonceValidityTime = _nonceValidityTime;
    }
    
    /**
	  * @dev This function is used to set the rarity multiplier for each rarity
        * @param rarity The rarity of the NFT
        * @param multiplier The multiplier for the rarity
    */
    function setRarityMultiplier(uint8 rarity, uint256 multiplier) public onlyOwner {
        rarityMultiplier[rarity] = multiplier;
    }
    
    /**
        * @dev This function is used to set the minimum interval between two claims
        * @param _minimumInterval The minimum interval between two claims
    */
    function setMinimumInterval(uint256 _minimumInterval) public onlyOwner {
        minimumInterval = _minimumInterval;
    }
    
    /**
        * @dev This function is used to set the vesting period for the Merkel token
        * @param _vestingPeriod The vesting period for the Merkel token
    */
    function setVestingPeriod(uint256 _vestingPeriod) public onlyOwner {
        vestingPeriod = _vestingPeriod;
    }
    
    /**
        * @dev This function is used to set the base amount for the Merkel token
        * @param _baseAmount The base amount for the Merkel token
    */
    function setBaseAmount(uint256 _baseAmount) public onlyOwner {
        baseAmount = _baseAmount;
    }
    
    /**
        * @dev This function is used to set the Merkel token contract address
        * @param _merkel The Merkel token contract address
    */
    function setMerkel(address _merkel) public onlyOwner {
        merkel = IMerkel(_merkel);
    }
    
    function toggleBurningStatus() public onlyOwner {
        isBurningEnabled = !isBurningEnabled;
    }
    
    function setDesignatedSigner(address _designatedSigner) public onlyOwner {
        designatedSigner = _designatedSigner;
    }
    
    /**
        * @dev This function is used to toggle the controller status of an address
        * @param controller The address of the controller
    */
    function toggleController(address controller) public onlyOwner {
        isController[controller] = !isController[controller];
    }
    
    /**
        * @dev This function is used set the base token URI
        * @param newBaseURI The new base URI
    */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(bytes(newBaseURI).length > 0);
        baseURI = newBaseURI;
    }
    
    /**
        * @dev This function is used to set the maxSupply of the token
        * @param _maxSupply The maxSupply of the token
    */
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }
    
    // Claim Merkel
    /**
         * @dev Burns the WaltsVault NFT and registers the user for claiming Merkel token
         * @param info Array of claimInfo
    */
    function burnToClaim(rarityInfo[] memory info) external {
        require(isBurningEnabled, "Burning is not enabled");
        for(uint256 i = 0; i < info.length; i++) {
            require(getRaritySigner(info[i]) == designatedSigner, "Invalid Signature");
            require(!isSignatureUsed[info[i].signature], "Signature Already Used");
            require(info[i].nonce + nonceValidityTime > uint32(block.timestamp), "Invalid Nonce");
            require(ownerOf(uint256(info[i].tokenId)) == msg.sender, "Not Owner");
            isSignatureUsed[info[i].signature] = true;
            uint256 totalAmount = baseAmount * rarityMultiplier[info[i].rarity];
            tokensBurntByUser[msg.sender].push(info[i].tokenId);
            claimInfos[info[i].tokenId] = claimInfo({
                rarity: uint8(info[i].rarity),
                lastClaimTime: uint32(block.timestamp),
                totalClaimed: 0,
                totalValueToClaim: totalAmount,
                minimumClaimAmount: totalAmount / vestingPeriod
            });
            _burn(info[i].tokenId);
            emit TokenBurnt(msg.sender, info[i].tokenId);
        }
    }
    
    /**
         * @dev Claims unclaimed Merkel token by the user
    */
    function claimMerkelCoins() external {
        uint totalClaimed;
        for(uint256 i=0; i<tokensBurntByUser[msg.sender].length;i++){
            uint16 tokenId = tokensBurntByUser[msg.sender][i];
            claimInfo storage info = claimInfos[tokenId];
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
        merkel.mint(msg.sender, totalClaimed);
    }
    
    // Contract Getters
    /**
		* @return Total unclaimed Merkel token by the user
         * @param user Address of the user
    */
    function getUnclaimedBalance(address user) public view returns(uint256) {
        uint256 totalUnclaimed;
        for(uint256 i = 0; i < tokensBurntByUser[user].length; i++) {
            uint16 tokenId = tokensBurntByUser[user][i];
            claimInfo memory info = claimInfos[tokenId];
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
    
    /**
		* @return Array of tokens burnt by the user
         * @param user Address of the user
    */
    function getTokensBurnt(address user) public view returns(uint16[] memory) {
        return tokensBurntByUser[user];
    }
    
    
    // OpenSea Operator Filterer
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
    
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    function owner()
        public
        view
        virtual
        override (OwnableUpgradeable, RevokableOperatorFiltererUpgradeable)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }
    
    function transferOwnership(address newOwner) public override {
        super.transferOwnership(newOwner);
    }
    
   
}
