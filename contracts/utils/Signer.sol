//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
contract Signer is EIP712Upgradeable {
    string private constant SIGNING_DOMAIN = "Walts_Vault";
    string private constant SIGNATURE_VERSION = "1";

    struct allowList {
        uint256 nonce;
        uint256 allocatedSpots;
        address userAddress;
        bytes signature;
    }

    struct returnList {
        uint256 nonce;
        uint256 tokensAllocated;
        address userAddress;
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
    @param _allowList allowList object
    */
    function getSignerForAllowList(allowList memory _allowList) public view returns (address) {
        return _verifyAllowList(_allowList);

    }
    /**
    @dev This function is used to get signer address of signature
    @param _returnList returnList object
    */
    function getSignerForReturnList(returnList memory _returnList) public view returns (address) {
        return _verifyReturnList(_returnList);

    }
    
    /**
    @dev This function is used to generate hash message
    @param _allowList allowList object to create hash
    */
    function _allowListHash(allowList memory _allowList) internal view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("allowList(uint256 nonce,uint256 allocatedSpots,address userAddress)"),
                    _allowList.nonce,
                    _allowList.allocatedSpots,
                    _allowList.userAddress
                )
            )
        );
    }
    
    /**
    @dev This function is used to generate hash message
    @param _returnList returnList object to create hash
    */
    function _returnListHash(returnList memory _returnList) internal view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("returnList(uint256 nonce,uint256 tokensAllocated,address userAddress)"),
                    _returnList.nonce,
                    _returnList.tokensAllocated,
                    _returnList.userAddress
                )
            )
        );
    }

    /**
    @dev This function is used to verify signature
    @param _allowList allowList object to verify
    */
    function _verifyAllowList(allowList memory _allowList) internal view returns (address) {
        bytes32 digest = _allowListHash(_allowList);
        return ECDSAUpgradeable.recover(digest, _allowList.signature);
    }
    
    /**
    @dev This function is used to verify signature
    @param _returnList returnList object to verify
    */
    function _verifyReturnList(returnList memory _returnList) internal view returns (address) {
        bytes32 digest = _returnListHash(_returnList);
        return ECDSAUpgradeable.recover(digest, _returnList.signature);
    }
}