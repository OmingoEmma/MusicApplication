// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MusicToken.sol";

contract MusicApplication is ReentrancyGuard, Ownable {
    MusicToken public musicToken;

    struct Music {
        string title;
        address artist;
        uint256 price;
        uint8 rating;
        uint256 totalRatings;
        uint256 raterCount;
        bytes32 contentHash;
        string state; // "New", "Purchased", "Accessible"
    }

    uint256 public musicCount;
    mapping(uint256 => Music) public musicLibrary;

    event MusicUploaded(uint256 indexed musicId, string title, address indexed artist);
    event MusicPurchased(uint256 indexed musicId, address indexed buyer);
    event MusicRated(uint256 indexed musicId, address indexed rater, uint8 rating);

    constructor(address _tokenAddress, address _owner) Ownable(_owner) {
        require(_tokenAddress != address(0), "Invalid token address");
        musicToken = MusicToken(_tokenAddress);
    }

    function uploadMusic(
        string memory _title,
        uint256 _price,
        bytes32 _contentHash
    ) external {
        require(bytes(_title).length > 0, "Title is required");
        require(_price > 0, "Price must be greater than zero");

        musicCount++;
        musicLibrary[musicCount] = Music({
            title: _title,
            artist: msg.sender,
            price: _price,
            rating: 0,
            totalRatings: 0,
            raterCount: 0,
            contentHash: _contentHash,
            state: "New"
        });

        emit MusicUploaded(musicCount, _title, msg.sender);
    }

    function purchaseMusic(uint256 _musicId) external nonReentrant {
        Music storage music = musicLibrary[_musicId];
        require(keccak256(bytes(music.state)) == keccak256(bytes("New")), "Music not available for purchase");

        uint256 price = music.price;
        require(musicToken.transferFrom(msg.sender, music.artist, price), "Token transfer failed");

        music.state = "Purchased";

        emit MusicPurchased(_musicId, msg.sender);
    }
}
