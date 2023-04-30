//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
contract Signer is EIP712Upgradeable {
    string private constant SIGNING_DOMAIN = "Walts_Vault";
    string private constant SIGNATURE_VERSION = "1";

    struct orderInfo {
        uint256 nonce;
        uint256 allocatedSpots;
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
    @param _orderInfo orderInfo object
    */
    function getSigner(orderInfo memory _orderInfo) public view returns (address) {
        return _verifyOrder(_orderInfo);

    }
    
    /**
    @dev This function is used to generate hash message
    @param _orderInfo orderInfo object to create hash
    */
    function _orderInfoHash(orderInfo memory _orderInfo) internal view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("orderInfo(uint256 nonce,uint256 allocatedSpots,address userAddress)"),
                    _orderInfo.nonce,
                    _orderInfo.allocatedSpots,
                    _orderInfo.userAddress
                )
            )
        );
    }

    /**
    @dev This function is used to verify signature
    @param _orderInfo orderInfo object to verify
    */
    function _verifyOrder(orderInfo memory _orderInfo) internal view returns (address) {
        bytes32 digest = _orderInfoHash(_orderInfo);
        return ECDSAUpgradeable.recover(digest, _orderInfo.signature);
    }
}