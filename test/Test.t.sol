// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test as ForgeTest} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {MyNFTCollection} from "../src/MyNFTCollection.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";

contract NFTTest is ForgeTest {
    MyNFTCollection nft;
    GovernanceToken governanceToken;
    address user = makeAddr("user");
    uint256 mintPrice = 0.005 ether;

    function setUp() public {
        governanceToken = new GovernanceToken("GovernanceToken", "GT");
        nft = new MyNFTCollection(address(governanceToken));
        vm.deal(user, 1 ether); // Give user some ETH
    }

    function test_Mint() public {
        // Switch to user context
        vm.startPrank(user);

        // Record balances before minting
        uint256 userBalanceBefore = user.balance;
        uint256 contractBalanceBefore = address(governanceToken).balance;
        uint256 tokenBalanceBefore = nft.balanceOf(user, nft.TOKEN_ID());
        uint256 nTokensBought = 1;
        uint256 amountValue = nTokensBought*mintPrice;

        // Mint NFT - just mint 1 token instead of 10^18
        nft.mint{value: mintPrice*nTokensBought}(nTokensBought);

        // Verify token balance increased
        
        assertEq(
            nft.balanceOf(user, nft.TOKEN_ID()),
            tokenBalanceBefore + 1,
            "Token not minted"
        );

        // Verify ETH transferred correctly
        assertEq(user.balance, userBalanceBefore - mintPrice, "Wrong ETH deducted");
        assertEq(address(governanceToken).balance, contractBalanceBefore + mintPrice*nTokensBought, "Wrong ETH received");
        
        vm.stopPrank();
    }

}