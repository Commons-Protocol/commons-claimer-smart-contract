// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {console} from "forge-std/console.sol";
import {IERC20} from"@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Rewards is Ownable {
    IERC20 public token;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public lastClaimTime;
    uint256 public rewardAmount;
    uint256 public claimInterval;
    //todo: add epoch wise rewards
    event Whitelisted(address indexed user);
    event Claimed(address indexed user, uint256 amount);
    event BalanceAdded(address indexed from, uint256 amount);

 constructor(IERC20 _token, uint256 _rewardAmount, uint256 _claimInterval) Ownable(msg.sender) {
        rewardAmount = _rewardAmount;
        claimInterval = _claimInterval;
        token = _token; 
    }


    function addTokens(uint256 amount) external {
        require(token.allowance(msg.sender, address(this))> amount, "Insufficient allowance");
        token.transferFrom(msg.sender, address(this), amount);
        emit BalanceAdded(msg.sender,amount);
    }
    //todo: update it take numbers
    //todo: update epoch wise rewards
    function addToWhitelist(address _user) public onlyOwner {
        require(!whitelist[_user], "User is already whitelisted");
        whitelist[_user] = true;
        emit Whitelisted(_user);
    }

    function removeFromWhitelist(address _user) public onlyOwner {
        require(whitelist[_user], "User is not whitelisted");
        whitelist[_user] = false;
    }

    function claimReward() public {
        require(whitelist[msg.sender], "You are not whitelisted");
        require(block.timestamp >= lastClaimTime[msg.sender] + claimInterval, "You can only claim once per interval");
        require(address(this).balance >= rewardAmount, "Contract doesn't have enough balance");

        console.log("User %s is claiming reward", msg.sender);
        console.log("Last claim time: %s", lastClaimTime[msg.sender]);
        console.log("Current time: %s", block.timestamp);

        lastClaimTime[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(rewardAmount);
        emit Claimed(msg.sender, rewardAmount);

        console.log("Reward claimed successfully");
    }

    function canClaimReward(address _user) public view returns (bool) {
        return whitelist[_user] && (block.timestamp >= lastClaimTime[_user] + claimInterval);
    }

    function timeUntilNextClaim(address _user) public view returns (uint256) {
        if (!whitelist[_user]) return 0;
        uint256 nextClaimTime = lastClaimTime[_user] + claimInterval;
        if (block.timestamp >= nextClaimTime) return 0;
        return nextClaimTime - block.timestamp;
    }

    function setRewardAmount(uint256 _newAmount) public onlyOwner {
        rewardAmount = _newAmount;
    }

    function setClaimInterval(uint256 _newInterval) public onlyOwner {
        claimInterval = _newInterval;
    }


    function getContractBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // Function to withdraw any ERC20 tokens sent to the contract, specially useful for accidentally sent tokens
    function withdrawTokens(IERC20 _token, uint256 amount) public onlyOwner {
        require(_token.transfer(address(this), amount), "Transfer failed");
    }
}
