// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MerkelSplitter is OwnableUpgradeable{

    IERC20Upgradeable public merkel;
    
    uint256 public claimStart;
    uint256 public lastClaim;
    uint256 public maxRelease;
    uint256 public totalReleased;
    uint256 public amountReleasedPerMonth;
    address[] public payee;
    mapping(address => uint256) public shares;
    
    function initialize(address _merkel) external initializer {
        __Ownable_init();
        merkel = IERC20Upgradeable(_merkel);
        claimStart = block.timestamp + 365 days;
        maxRelease = 100_000_000 ether;
        lastClaim = claimStart;
        amountReleasedPerMonth = 2_777_777 ether;
    }
    
    // 2_777_777 * 36 = 100_000_000
    
    function addPayee(address _payee, uint256 _shares) external onlyOwner {
        require(_payee != address(0), "Invalid Address");
        require(_shares > 0, "Invalid Shares");
        require(shares[_payee] == 0, "Payee already added");
        payee.push(_payee);
        shares[_payee] = _shares;
    }
    
    function removePayee(address _payee) external onlyOwner {
        require(_payee != address(0), "Invalid Address");
        require(shares[_payee] > 0, "Payee not added");
        shares[_payee] = 0;
        for(uint256 i = 0; i < payee.length; i++) {
            if(payee[i] == _payee) {
                payee[i] = payee[payee.length - 1];
                payee.pop();
                break;
            }
        }
    }
    
    function withdraw() external {
        require(block.timestamp >= claimStart, "Claim not started");
        require(block.timestamp >= lastClaim + 30 days, "Min 30 days between claims");
        
        uint256 totalShares = 0;
        for(uint256 i = 0; i < payee.length; i++) {
            totalShares += shares[payee[i]];
        }
        require(totalShares % 100 == 0, "Shares must be multiple of 100");
        
        uint256 lastClaimTime = lastClaim;
        lastClaim = block.timestamp;
        uint256 monthsPassed = (block.timestamp - lastClaimTime) / 30 days;
        for(uint256 i = 0; i < payee.length; i++) {
            uint256 payout = amountReleasedPerMonth * shares[payee[i]] / totalShares;
            totalReleased += payout * monthsPassed;
            require(totalReleased <= maxRelease, "Max Release Reached");
            merkel.transfer(payee[i], payout * monthsPassed);
        }

    }

}
