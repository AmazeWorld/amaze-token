const { expect } = require("chai");
//const { BN } = require("bn.js");
const { ethers } = require("hardhat");

const {
  BN,           // Big Number support
  constants,    // Common constants, like the zero address and largest integers
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');

describe("AMZEToken contract", function () {
  it("Deployment should assign the total supply of tokens to the owner", async function () {
    const [owner] = await ethers.getSigners();

    const AMZEToken = await ethers.getContractFactory("AMZEToken");
    const amzeToken = await AMZEToken.deploy();
    const ownerBalance = await amzeToken.balanceOf(owner.address);
    const mintedTokens = 54000000 * (10 ** 18); 

    // BN assertions are automatically available via chai-bn (if using Chai)
    expect(ownerBalance)
      .to.be.bignumber.equal(mintedTokens);    
    //expect(54000000 * (10 ** 18)).to.be.bignumber.equal(ownerBalance);
  });
});