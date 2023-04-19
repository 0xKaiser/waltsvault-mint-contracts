// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
interface INFT is IERC721Upgradeable {
    function totalSupply() external view returns (uint256);
}
