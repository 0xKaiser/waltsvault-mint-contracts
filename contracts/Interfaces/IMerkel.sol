// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IMerkel is IERC20Upgradeable{
	function mint(address to_, uint256 amount) external;
}
