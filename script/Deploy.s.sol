// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {MyNFTCollection} from "../src/MyNFTCollection.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";
import "forge-std/console.sol";

contract Deploy is Script {
    function run() external {
        // Load environment variables
        uint256 deployerKey = vm.envUint("PK");

        // Begin broadcasting transactions using the deployer's private key
        vm.startBroadcast(deployerKey);

        // Deploy the governance token
        GovernanceToken governanceToken = new GovernanceToken("My Governance Token", "MGT");
        console.log("address govToken", address(governanceToken));

        // Deploy the NFT collection, passing the governance token address
        MyNFTCollection myNFT = new MyNFTCollection(address(governanceToken));

        vm.stopBroadcast();

        // Log deployed contract addresses
        console.log("GovernanceToken deployed at:", address(governanceToken));
        console.log("MyNFTCollection deployed at:", address(myNFT));
    }
}