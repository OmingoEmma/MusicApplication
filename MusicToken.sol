// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MusicToken is ERC20, Ownable, Pausable {
    uint256 public constant INITIAL_SUPPLY = 1000000 * 10 ** 18;

    constructor(address owner) ERC20("MusicToken", "MUS") Ownable(owner) {
        require(owner != address(0), "Owner cannot be zero address");
        _mint(owner, INITIAL_SUPPLY);
    }

    function burn(uint256 amount) public whenNotPaused {
        _burn(msg.sender, amount);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
