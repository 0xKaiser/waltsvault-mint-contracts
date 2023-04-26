// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract RaritySigner is EIP712Upgradeable {
	string private constant SIGNING_DOMAIN = "MerkelCoin";
	string private constant SIGNATURE_VERSION = "1";
	
	struct rarityInfo {
		uint8 rarity;
		uint16 tokenId;
		uint32 nonce;
		bytes signature;
	}
	
	/**
		 @notice This is initializer function is used to initialize values of contracts
    */
	function __Signer_init() internal initializer {
		__EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
	}
	
	/**
		 @dev This function is used to get signer address of signature
         @param _rarityInfo rarityInfo object
    */
	function getRaritySigner(rarityInfo memory _rarityInfo) public view returns (address) {
		return _verifySigner(_rarityInfo);
		
	}
	
	/**
		 @dev This function is used to generate hash message
         @param _rarityInfo rarityInfo object to create hash
    */
	function _rarityInfoHash(rarityInfo memory _rarityInfo) internal view returns (bytes32) {
		return
		_hashTypedDataV4(
			keccak256(
				abi.encode(
					keccak256("rarityInfo(uint8 rarity,uint16 tokenId,uint32 nonce)"),
					_rarityInfo.rarity,
					_rarityInfo.tokenId,
					_rarityInfo.nonce
				)
			)
		);
	}
	
	
	/**
		 @dev This function is used to verify signature
         @param _rarityInfo rarityInfo object to verify
    */
	function _verifySigner(rarityInfo memory _rarityInfo) internal view returns (address) {
		bytes32 digest = _rarityInfoHash(_rarityInfo);
		return ECDSAUpgradeable.recover(digest, _rarityInfo.signature);
	}
	

}
