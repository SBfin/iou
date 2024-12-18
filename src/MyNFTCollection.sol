// SPDX License Identifier MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";
interface IRevenueDistributor {
    function distributeRevenue() external payable;
}

contract MyNFTCollection is ERC1155, Ownable {
    uint256 public constant TOKEN_ID = 1; // Single type of NFT in this collection
    uint256 public price = 0.005 ether;
    address public governanceTokenAddress;

    constructor(address _governanceTokenAddress) ERC1155("ipfs://my_metadata_uri/{id}.json") Ownable(msg.sender) {
        require(_governanceTokenAddress != address(0), "Invalid governance token address");
        governanceTokenAddress = _governanceTokenAddress;
    }

    function mint(uint256 amount) external payable {
        require(msg.value == price * amount, "Incorrect payment");

        // Mint the NFTs to the caller
        _mint(msg.sender, TOKEN_ID, amount, "");

        // Forward the entire revenue to the governance token contract
        (bool success, ) = governanceTokenAddress.call{value: msg.value}(
            abi.encodeWithSignature("distributeRevenue()")
        );
        console.log("Revenue distribution success: ", success);
        require(success, "Revenue distribution failed");
    }

    // Owner can update price if needed
    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }
}
