// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test as ForgeTest} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {MyNFTCollection} from "../src/MyNFTCollection.sol"; // Adjust path as needed

contract NFTTest is ForgeTest {
    MyNFTCollection nft;
    address user = makeAddr("user");
    uint256 mintPrice = 0.005 ether;

    function setUp() public {
        nft = new MyNFTCollection(address(0x1234567890123456789012345678901234567890));
        vm.deal(user, 1 ether); // Give user some ETH
    }

    function test_Mint() public {
        // Switch to user context
        vm.startPrank(user);

        // Record balances before minting
        uint256 userBalanceBefore = user.balance;
        uint256 contractBalanceBefore = address(nft).balance;
        uint256 tokenBalanceBefore = nft.balanceOf(user, 1);

        // Mint NFT
        nft.mint{value: mintPrice * 1e18}(1 ether); // 1 token with 18 decimals

        // Verify token balance increased
        assertEq(nft.balanceOf(user, 1), tokenBalanceBefore + 1, "Token not minted");

        // Verify ETH transferred correctly
        assertEq(user.balance, userBalanceBefore - mintPrice, "Wrong ETH deducted");
        assertEq(address(nft).balance, contractBalanceBefore + mintPrice, "Wrong ETH received");

        vm.stopPrank();
    }

    function test_MintFailsWithoutEnoughETH() public {
        vm.startPrank(user);
        
        // Try to mint with less than required ETH
        vm.expectRevert();
        nft.mint{value: 0.004 ether}(1 ether);

        vm.stopPrank();
    }

    function test_MintFailsWithZeroAmount() public {
        vm.startPrank(user);
        
        // Try to mint with zero amount
        vm.expectRevert();
        nft.mint{value: mintPrice}(0);

        vm.stopPrank();
    }
}