import { expect } from "chai";
import { ethers } from "hardhat";
import { POAS } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("POAS", function () {
  let poas: POAS;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  const REDEEMABLE_ROLE = ethers.keccak256(ethers.toUtf8Bytes("REDEEMABLE_ROLE"));

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    const POAS = await ethers.getContractFactory("POAS");
    poas = await POAS.deploy();
  });

  describe("Deposit", function () {
    it("should mint pOAS tokens when depositing OAS", async function () {
      const depositAmount = ethers.parseEther("1");
      await expect(poas.connect(user1).deposit({ value: depositAmount }))
        .to.emit(poas, "Deposited")
        .withArgs(user1.address, depositAmount);

      expect(await poas.balanceOf(user1.address)).to.equal(depositAmount);
    });
  });

  describe("Batch Mint", function () {
    it("should mint tokens to multiple addresses", async function () {
      const recipients = [user1.address, user2.address];
      const amounts = [ethers.parseEther("1"), ethers.parseEther("2")];
      const totalAmount = amounts.reduce((a, b) => a + b);

      await expect(
        poas.batchMint(recipients, amounts, { value: totalAmount })
      ).to.emit(poas, "BatchMinted");

      expect(await poas.balanceOf(user1.address)).to.equal(amounts[0]);
      expect(await poas.balanceOf(user2.address)).to.equal(amounts[1]);
    });
  });

  describe("Redeem", function () {
    it("should allow redemption for authorized addresses", async function () {
      const amount = ethers.parseEther("1");
      await poas.connect(user1).deposit({ value: amount });
      await poas.grantRole(REDEEMABLE_ROLE, user1.address);

      const initialBalance = await ethers.provider.getBalance(user2.address);
      await poas.connect(user1).redeem(amount, user2.address);

      expect(await poas.balanceOf(user1.address)).to.equal(0);
      expect(await ethers.provider.getBalance(user2.address)).to.equal(
        initialBalance + amount
      );
    });
  });

  describe("Transfer Restrictions", function () {
    it("should prevent transfers between non-redeemable addresses", async function () {
      const amount = ethers.parseEther("1");
      await poas.connect(user1).deposit({ value: amount });

      await expect(
        poas.connect(user1).transfer(user2.address, amount)
      ).to.be.revertedWith("Transfer restricted to redeemable addresses");
    });
  });
}); 