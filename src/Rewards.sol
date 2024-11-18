// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Rewards is Ownable {
    IERC20 public token;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public lastClaimTime;
    uint256 public rewardAmount;
    uint256 public claimInterval;

    event Whitelisted(address indexed user);
    event Claimed(address indexed user, uint256 amount);
    event BalanceAdded(address indexed from, uint256 amount);

    constructor(
        IERC20 _token,
        uint256 _rewardAmount,
        uint256 _claimInterval
    ) Ownable(msg.sender) {
        rewardAmount = _rewardAmount;
        claimInterval = _claimInterval;
        token = _token;
    }

    function addTokens(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        emit BalanceAdded(msg.sender, amount);
    }

    function addToWhitelist(address[] calldata _user) external onlyOwner {
        for (uint256 i = 0; i < _user.length; i++) {
            _addToWhitelist(_user[i]);
        }
    }

    function _addToWhitelist(address _user) internal {
        require(!whitelist[_user], "User is already whitelisted");
        whitelist[_user] = true;
        emit Whitelisted(_user);
    }

    function removeFromWhitelist(address[] calldata _user) public onlyOwner {
        for (uint256 i = 0; i < _user.length; i++) {
            _removeFromWhitelist(_user[i]);
        }
    }
    
    function _removeFromWhitelist(address _user) internal {
        require(whitelist[_user], "User is not whitelisted");
        whitelist[_user] = false;
    }

    function claimReward() public {
        require(whitelist[msg.sender], "You are not whitelisted");
        require(
            block.timestamp >= lastClaimTime[msg.sender] + claimInterval,
            "You can only claim once per interval"
        );

        lastClaimTime[msg.sender] = block.timestamp;
        token.transfer(msg.sender, rewardAmount);
        emit Claimed(msg.sender, rewardAmount);
    }

    function canClaimReward(address _user) public view returns (bool) {
        return
            whitelist[_user] &&
            (block.timestamp >= lastClaimTime[_user] + claimInterval);
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
    function withdrawTokens(
        IERC20 _token,
        address recipient,
        uint256 amount
    ) public onlyOwner {
        _token.transfer(recipient, amount);
    }
}
