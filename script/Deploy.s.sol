// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {MyNFTCollection} from "../src/MyNFTCollection.sol";
import {RevToken} from "../src/RevToken.sol";
import "forge-std/console.sol";

contract Deploy is Script {
    function run() external {
        // Load environment variables
        uint256 deployerKey = vm.envUint("PK");

        // Begin broadcasting transactions using the deployer's private key
        vm.startBroadcast(deployerKey);

        // Deploy the Rev token
        RevToken revToken = new RevToken("My REV Token", "RT");
        console.log("address govToken", address(revToken));

        // Deploy the NFT collection, passing the Rev token address
        MyNFTCollection myNFT = new MyNFTCollection(address(revToken));

        // mint 10 rev token to a test address on anvil
        revToken.mintRevTokens(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 10);

        vm.stopBroadcast();

        // Log deployed contract addresses
        console.log("RevToken deployed at:", address(revToken));
        console.log("MyNFTCollection deployed at:", address(myNFT));
    }
}