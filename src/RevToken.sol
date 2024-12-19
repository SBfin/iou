// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

contract RevToken is ERC20, Ownable {
    // Dividend tracking
    uint256 public totalReceived; 
    uint256 public magnifiedDividendPerShare;
    uint256 public constant magnificationFactor = 2**128;


    mapping(address => int256) public magnifiedDividendCorrections;
    mapping(address => uint256) public withdrawnDividends;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) Ownable(msg.sender) {
        // For example, you might mint governance tokens to the deployer or a treasury:
        _mint(msg.sender, 1);
    }

    receive() external payable {
        // If received ETH accidentally, it won't distribute automatically.
        // Make sure distribution is triggered by a known method (distributeRevenue).
    }

    // Called by the NFT contract after receiving ETH from mints
    function distributeRevenue() external payable {
        require(msg.value > 0, "No revenue");
        // Update global accounting
        console.log("inside distributeRevenue");
        if (totalSupply() > 0) {
            magnifiedDividendPerShare += (msg.value * magnificationFactor) / totalSupply();
        }
        totalReceived += msg.value;
    }

    // TODO: override transfer function to track dividends
    /*
    function _transfer(address from, address to, uint256 amount) internal override {
        super._transfer(from, to, amount);

        // Adjust dividend corrections to ensure that dividends are tracked correctly
        int256 magCorrection = int256(magnifiedDividendPerShare * amount);
        magnifiedDividendCorrections[from] += magCorrection;
        magnifiedDividendCorrections[to] -= magCorrection;
    }

    function _mint(address account, uint256 amount) internal override {
        super._mint(account, amount);

        // When tokens are minted, the new holder shouldn't be entitled to previously accrued dividends:
        magnifiedDividendCorrections[account] -= int256(magnifiedDividendPerShare * amount);
    }

    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
        
        // Adjust corrections on burn
        magnifiedDividendCorrections[account] += int256(magnifiedDividendPerShare * amount);
    }
    */
    // View the dividends that `account` can withdraw currently
    function withdrawableDividendOf(address account) public view returns(uint256) {
        return accumulativeDividendOf(account) - withdrawnDividends[account];
    }

    // Returns the total accumulated dividends for `account`
    function accumulativeDividendOf(address account) public view returns(uint256) {
        int256 correction = magnifiedDividendCorrections[account];
        console.log("correction", correction);
        int256 dividends = int256(magnifiedDividendPerShare * balanceOf(account)) + correction;
        console.log("balanceOf", balanceOf(account));
        console.log("magnifiedDividendPerShare", magnifiedDividendPerShare);
        if (dividends < 0) {
            return 0;
        }
        console.log("dividends after magnification", uint256(dividends / int256(magnificationFactor)));
        return uint256(dividends / int256(magnificationFactor));
    }

    // Allow token holders to claim their dividends
    function claimDividends() external {
        uint256 withdrawable = withdrawableDividendOf(msg.sender);
        require(withdrawable > 0, "No dividends to withdraw");

        withdrawnDividends[msg.sender] += withdrawable;
        (bool success, ) = msg.sender.call{value: withdrawable}("");
        require(success, "Transfer failed");
    }

    // Owner can mint governance tokens. In a real scenario, you'd have a proper distribution logic.
    function mintRevTokens(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
