// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
interface IOrdinalsPass is IERC721Upgradeable {
    
    function getTotalSupply() external view returns (uint256);
    function mint(address _to, uint256 _tokenAmount) external;

}
