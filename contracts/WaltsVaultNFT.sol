// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721AUpgradeable} from "./utils/ERC721AUpgradeable.sol";
import {RevokableOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableOperatorFiltererUpgradeable.sol";
import {RevokableDefaultOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableDefaultOperatorFiltererUpgradeable.sol";
import {UpdatableOperatorFilterer} from "./OpenseaRegistries/UpdatableOperatorFilterer.sol";
import {IMerkel} from "./Interfaces/IMerkel.sol";
import {RaritySigner} from "./utils/RaritySigner.sol";

contract WaltsVault is
    OwnableUpgradeable,
    ERC721AUpgradeable,
    RevokableDefaultOperatorFiltererUpgradeable,
    RaritySigner
{
    IMerkel public merkel;
    
    struct claimInfo {
        uint8 rarity;
        uint32 lastClaimTime;
        uint256 totalReleased;
        uint256 totalValueToClaim;
        uint256 minimumReleaseAmount;
    }
    
    mapping(uint16 => claimInfo) public claimInfos;
    // rarity => multiplier
    mapping(uint8 => uint256) public rarityMultiplier;
    mapping(address => bool) public isController;
    mapping(address => uint16[]) private tokensBurntByUser;
    mapping(bytes => bool) public isSignatureUsed;
    
    string public baseURI;
    address public designatedSigner;
    uint32 public nonceValidityTime;
    uint256 public baseAmount;
    uint256 public maxSupply;
    uint256 public minimumInterval;
    uint256 public vestingPeriod;


    modifier onlyController(address from) {
        require(isController[from], "Not a Controller");
        _;
    }
    
    function initialize(string memory name, string memory symbol, address _merkel, address _designatedSigner) external
    initializer {
        __Ownable_init();
        __ERC721A_init(name,symbol);
        __RevokableDefaultOperatorFilterer_init();
        __Signer_init();
        merkel = IMerkel(_merkel);
        designatedSigner = _designatedSigner;
        maxSupply = 1000;
        minimumInterval = 1 days;
        vestingPeriod = 60;
        baseAmount = 10_000 ether;
    }
    
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
    
    // Claim Merkel
    
    /**
         * @dev Burns the WaltsVault NFT and registers the user for claiming Merkel token
         * @param info Array of claimInfo
    */
    function burnToClaim(rarityInfo[] memory info) external {
    
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
                totalReleased: 0,
                totalValueToClaim: totalAmount,
                minimumReleaseAmount: totalAmount / vestingPeriod
            });
            _burn(info[i].tokenId);
        }
    }
    
    /**
         * @dev Claims unclaimed Merkel token by the user
    */
    function claimMerkelCoins() external {
        uint totalClaimed;
        for(uint256 i=0; i<tokensBurntByUser[msg.sender].length;i++){
            uint16 tokenId = tokensBurntByUser[msg.sender][i];
            claimInfo memory info = claimInfos[tokenId];
            uint256 timeElapsed = block.timestamp - info.lastClaimTime;
            uint256 totalClaim = timeElapsed / minimumInterval;
            uint256 totalValueToClaim = totalClaim * info.minimumReleaseAmount;
            if(totalValueToClaim > info.totalValueToClaim - info.totalReleased) {
                totalValueToClaim = info.totalValueToClaim - info.totalReleased;
            }
            info.lastClaimTime = uint32(block.timestamp);
            info.totalReleased += totalValueToClaim;
            totalClaimed += totalValueToClaim;
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
            uint256 totalValueToClaim = totalClaim * info.minimumReleaseAmount;
            if(totalValueToClaim > info.totalValueToClaim - info.totalReleased) {
                totalValueToClaim = info.totalValueToClaim - info.totalReleased;
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
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    // Contract Setters
    
    function toggleController(address controller) public onlyOwner {
        isController[controller] = !isController[controller];
    }
    
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(bytes(newBaseURI).length > 0);
        baseURI = newBaseURI;
    }
    
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }
    
    function setRarityMultiplier(uint8 rarity, uint256 multiplier) public onlyOwner {
        rarityMultiplier[rarity] = multiplier;
    }
    
    function setMinimumInterval(uint256 _minimumInterval) public onlyOwner {
        minimumInterval = _minimumInterval;
    }
    
    function setInstalmentPeriod(uint256 _vestingPeriod) public onlyOwner {
        vestingPeriod = _vestingPeriod;
    }
    
    function settotalAmount(uint256 _baseAmount) public onlyOwner {
        baseAmount = _baseAmount;
    }
    
    function setDesignatedSigner(address _designatedSigner) public onlyOwner {
        designatedSigner = _designatedSigner;
    }
    
    function setMerkel(address _merkel) public onlyOwner {
        merkel = IMerkel(_merkel);
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
}
