// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {console} from "forge-std/console.sol";

// BondingCurveToken contract

contract BondingCurveToken is ERC20Capped {
    // Bonding curve params
    uint256 public constant TOTAL_SUPPLY = 10000 ether;
    uint256 public constant OWN_SUPPLY = 2000 ether;
    uint256 public constant INITIAL_PRICE = 2e15;
    uint256 public constant PRICE_SLOPE = 24e10;
    uint256 public constant PRECISION = 1 ether;
    int24 public constant TICK_SPACING = 60;
    uint24 public constant FEE = 3000;

    // Errors
    error InvalidAmountError();
    error NotEnoughETHtoSellTokens();
    error NotEnoughETHtoProvideLiquidity();

    // Add state variables for staking
    mapping(address => uint256) public stakedBalances;
    uint256 public totalStaked;

    constructor(string memory name, string memory symbol)
        ERC20Capped(TOTAL_SUPPLY)
        ERC20(name, symbol)
    {
        _mint(address(this), OWN_SUPPLY);
    }

    function buy(uint256 amount) public payable {
        uint256 price = getBuyQuote(amount);
        console.log("Price: %d", price);
        console.log("Amount: %d", amount);
        console.log("Value: %d", msg.value);
        console.log("Price * amount / PRECISION: %d", (price * amount) / PRECISION);

        if (msg.value < (price * amount) / PRECISION) {
            revert InvalidAmountError();
        }

        // Computing amount
        // if amount exceeds total supply, then mint the remaining amount
        if (totalSupply() + amount > TOTAL_SUPPLY) {
            amount = TOTAL_SUPPLY - totalSupply();
            payable(msg.sender).transfer(msg.value - (price * amount) / PRECISION);
            _mint(msg.sender, amount);
            console.log("Deploying the pool...");
            PoolKey memory pool = _createUniswapPool();
            console.log("Adding liquidity to the pool...");
            _addLiquidity(pool);
        } else {
            console.log("amount: %d", amount);
            payable(msg.sender).transfer(msg.value - (price * amount) / PRECISION);
            console.log("Minting %d tokens", amount);
            _mint(msg.sender, amount);
        }
    }

    function sell(uint256 amount) public {
        console.log("Get sell price...");
        uint256 price = getSellQuote(amount);
        console.log("Sell price: %d", price);
        uint256 value = (price * amount) / PRECISION;
        console.log("Sell value: %d", value);

        if (value > address(this).balance) {
            revert NotEnoughETHtoSellTokens();
        }

        _burn(msg.sender, amount);
        payable(msg.sender).transfer(value);
    }

    
    // add a fallback function to handle ETH
    receive() external payable {}

    //////////////////////////
    //// View functions //////
    //////////////////////////

    function getPrice() public view returns (uint256) {
        return INITIAL_PRICE + (totalSupply() * PRICE_SLOPE) / PRECISION;
    }

    function getPriceInv() public view returns (uint256) {
        return (PRECISION * PRECISION) / getPrice();
    }

    function getPriceAtSupply(uint256 supply) public view returns (uint256) {
        return INITIAL_PRICE + (supply * PRICE_SLOPE) / PRECISION;
    }

    function getBuyQuote(uint256 amount) public view returns (uint256) {
        // Average between the current price and the price after the amount is minted
        return (getPrice() + getPrice() + (PRICE_SLOPE * amount) / PRECISION) / 2;
    }

    function getSellQuote(uint256 amount) public view returns (uint256) {
        // Average between the current price and the price after the amount is minted
        return (getPrice() + (getPrice() - (PRICE_SLOPE * amount) / PRECISION)) / 2;
    }

    function getMarketCap() public view returns (uint256) {
        return totalSupply() * getPrice();
    }

    // Function to stake tokens
    function stake(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient token balance");

        // Transfer tokens from the user to the contract
        _transfer(msg.sender, address(this), amount);
        
        stakedBalances[msg.sender] += amount;
        totalStaked += amount;
    }

    // Function to unstake tokens
    function unstake(uint256 amount) public {
        require(stakedBalances[msg.sender] >= amount, "Insufficient staked amount");
        
        stakedBalances[msg.sender] -= amount;
        totalStaked -= amount;
        
        // Transfer tokens back to the user
        _transfer(address(this), msg.sender, amount);
    }

    // Function to claim ETH based on token share
    function claim() public {
        uint256 userShare = (stakedBalances[msg.sender] * address(this).balance) / TOTAL_SUPPLY;
        require(userShare > 0, "No ETH to claim");

        // Reset the user's staked balance to prevent re-entrancy
        stakedBalances[msg.sender] = 0;

        // Transfer the calculated share of ETH to the user
        payable(msg.sender).transfer(userShare);
    }

    function buyAndStake(uint256 amount) public payable {
        uint256 price = getBuyQuote(amount);
        console.log("Price: %d", price);
        console.log("Amount: %d", amount);
        console.log("Value: %d", msg.value);
        console.log("Price * amount / PRECISION: %d", (price * amount) / PRECISION);

        // Check if the sent value is sufficient
        if (msg.value < (price * amount) / PRECISION) {
            revert InvalidAmountError();
        }

        // Mint the tokens to the caller
        _mint(msg.sender, amount);

        // Stake the purchased tokens
        stake(amount);
    }
}