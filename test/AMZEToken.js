// We import Chai to use its asserting functions here.
const { expect } = require("chai");

describe("AMZE contract", function () {
    let amzeContractFactory;
    let amzeToken;
    let owner;
    let addr1;
    let addr2;
    let addrs;
    
    beforeEach(async function () {
    amzeContractFactory = await ethers.getContractFactory("AMZEToken");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    amzeToken = await amzeContractFactory.deploy();
  });
  
  describe("Deployment", function () {
    it("Should set the right owner", async function () {
        expect(await amzeToken.owner()).to.equal(owner.address);
    });
    
    it("Should assign the total supply of tokens to the owner", async function () {
        const ownerBalance = await amzeToken.balanceOf(owner.address);
        expect(await amzeToken.totalSupply()).to.equal(ownerBalance);
      });
    });
  
    describe("Transactions", function () {
        it("Should transfer tokens between accounts", async function () {
          // Transfer 10000 tokens from owner to addr1
          await amzeToken.transfer(addr1.address, 10000 * (10 ** uint256(decimals())));
          const addr1Balance = await amzeToken.balanceOf(addr1.address);
          expect(addr1Balance).to.equal(10000 * (10 ** uint256(decimals())));
    
          // Transfer 10000 tokens from addr1 to addr2
          // We use .connect(signer) to send a transaction from another account
          await amzeToken.connect(addr1).transfer(addr2.address, 10000 * (10 ** uint256(decimals())));
          const addr2Balance = await amzeToken.balanceOf(addr2.address);
          expect(addr2Balance).to.equal(10000 * (10 ** uint256(decimals())));
        });
    
        it("Should fail if sender doesn’t have enough tokens", async function () {
          const initialOwnerBalance = await amzeToken.balanceOf(owner.address);
    
          // Try to send 10000 token from addr1 (0 tokens) to owner (10000 tokens).
          // `require` will evaluate false and revert the transaction.
          await expect(
            amzeToken.connect(addr1).transfer(owner.address, 10000 * (10 ** uint256(decimals())))
          ).to.be.revertedWith("Not enough tokens");
    
          // Owner balance shouldn't have changed.
          expect(await amzeToken.balanceOf(owner.address)).to.equal(
            initialOwnerBalance
          );
        });
    
        it("Should update balances after transfers", async function () {
          const initialOwnerBalance = await amzeToken.balanceOf(owner.address);
    
          // Transfer 10000 tokens from owner to addr1.
          await amzeToken.transfer(addr1.address, 10000 * (10 ** uint256(decimals())));
    
          // Transfer another 10000 tokens from owner to addr2.
          await amzeToken.transfer(addr2.address, 10000 * (10 ** uint256(decimals())));
    
          // Check balances.
          const finalOwnerBalance = await amzeToken.balanceOf(owner.address);
          expect(finalOwnerBalance).to.equal(initialOwnerBalance - 20000);
    
          const addr1Balance = await amzeToken.balanceOf(addr1.address);
          expect(addr1Balance).to.equal(10000 * (10 ** uint256(decimals())));
    
          const addr2Balance = await amzeToken.balanceOf(addr2.address);
          expect(addr2Balance).to.equal(10000 * (10 ** uint256(decimals())));
        });
      });
    });    