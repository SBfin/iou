// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test as ForgeTest} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MyNFTCollection} from "../src/MyNFTCollection.sol";
import {RevToken} from "../src/RevToken.sol";

contract NFTTest is ForgeTest {
    MyNFTCollection nft;
    RevToken revToken;
    address user = makeAddr("user");
    uint256 mintPrice = 0.005 ether;

    function setUp() public {
        revToken = new RevToken("RevToken", "GT");
        nft = new MyNFTCollection(address(revToken));
        vm.deal(user, 1 ether); // Give user some ETH
    }

    function test_Mint() public {
        // Switch to user context
        vm.startPrank(user);

        // Record balances before minting
        uint256 userBalanceBefore = user.balance;
        uint256 contractBalanceBefore = address(revToken).balance;
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
        assertEq(address(revToken).balance, contractBalanceBefore + mintPrice*nTokensBought, "Wrong ETH received");
        
        vm.stopPrank();
    }

    function test_withdrawableDividendOf() public {
        
        console.log("minting tokens for user", user);
        // get owner of the gov token contract
        address owner = revToken.owner();
        console.log("owner", owner);

        revToken.mintRevTokens(user, 100);

        vm.startPrank(user);
        // mint 1 nft
        nft.mint{value: mintPrice}(1);

        // check if user has dividends
        console.log("withdrawableDividendOf", revToken.withdrawableDividendOf(user));
        assertGt(revToken.withdrawableDividendOf(user), 0, "User has no dividends");

        vm.stopPrank();
    }

}
