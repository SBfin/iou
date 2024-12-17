// SPDX License Identifier MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Collection is ERC1155, Ownable(msg.sender) {
    uint256 public constant TOKEN_ID = 1; // Example token ID
    uint256 public constant MINT_PRICE = 0.005 ether; // Minting price
    address govToken;
    
    constructor(address _govToken) ERC1155("https://myapi.com/api/token/{id}.json") {
        govToken = _govToken;
    }

    function mint(uint256 amount) external payable {
        require(msg.value >= MINT_PRICE * amount, "Insufficient ETH sent");
        // send eth 
        _mint(msg.sender, TOKEN_ID, amount, "");
        // send eth to the govTOken
        (bool success, ) = govToken.call{value: 1 ether}("");
        require(success, "Call failed, transfer not successful");
    }

    // Function to withdraw funds from the contract
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

