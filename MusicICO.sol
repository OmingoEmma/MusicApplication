// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MusicToken.sol";

contract MusicICO is ReentrancyGuard, Ownable {
    MusicToken public token;

    uint256 public tokenPrice = 0.001 ether; // Token price in Ether
    uint256 public hardCap = 700000 * 10 ** 18; // Maximum tokens to sell
    uint256 public softCap = 100000 * 10 ** 18; // Minimum funding goal
    uint256 public totalSold;
    uint256 public startTime;
    uint256 public endTime;

    mapping(address => uint256) public investments;

    enum ICOState { NotStarted, Active, Ended, Refunding }
    ICOState public icoState = ICOState.NotStarted;

    event ICOStarted(uint256 startTime, uint256 endTime);
    event ICOEnded(uint256 totalSold);
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event RefundsIssued(address indexed investor, uint256 amount);

    constructor(address _tokenAddress, address _owner) Ownable(_owner) {
        require(_tokenAddress != address(0), "Invalid token address");
        token = MusicToken(_tokenAddress);
    }

    function startICO(uint256 _duration) external onlyOwner {
        require(icoState == ICOState.NotStarted, "ICO already started");
        icoState = ICOState.Active;
        startTime = block.timestamp;
        endTime = startTime + _duration;
        emit ICOStarted(startTime, endTime);
    }

    function buyTokens() external payable nonReentrant {
        require(icoState == ICOState.Active, "ICO is not active");
        require(block.timestamp < endTime, "ICO has ended");
        require(msg.value > 0, "Ether value must be greater than zero");

        uint256 tokenAmount = (msg.value * 10 ** 18) / tokenPrice;
        require(totalSold + tokenAmount <= hardCap, "Exceeds hard cap");

        investments[msg.sender] += msg.value;
        totalSold += tokenAmount;

        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");
        emit TokensPurchased(msg.sender, tokenAmount, msg.value);
    }

    function endICO() external onlyOwner {
        require(icoState == ICOState.Active, "ICO is not active");
        icoState = ICOState.Ended;

        if (totalSold < softCap) {
            icoState = ICOState.Refunding;
        }
        emit ICOEnded(totalSold);
    }

    function claimRefund() external nonReentrant {
        require(icoState == ICOState.Refunding, "Refunds are not active");
        uint256 investment = investments[msg.sender];
        require(investment > 0, "No investment to refund");

        investments[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: investment}("");
        require(success, "Refund failed");

        emit RefundsIssued(msg.sender, investment);
    }

    function withdrawFunds() external onlyOwner {
        require(icoState == ICOState.Ended, "ICO is not ended");
        require(totalSold >= softCap, "Soft cap not reached");

        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}
