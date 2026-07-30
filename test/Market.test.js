import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.create();

async function deployMarketFixture() {
  const [owner, seller, buyer, other] = await ethers.getSigners();
  const Nft = await ethers.getContractFactory("Nft");
  const Market = await ethers.getContractFactory("Market");
  const nft = await Nft.deploy("Soli", "SOLI");
  const market = await Market.deploy();
  await nft.waitForDeployment();
  await market.waitForDeployment();
  await nft.connect(seller).mint("ipfs://bafybeig/item.json");
  await nft.connect(seller).approve(market.target, 1n);
  return { nft, market, owner, seller, buyer, other };
}

async function listOne(market, nft, seller, price = ethers.parseEther("1")) {
  await market.connect(seller).list(nft.target, 1n, price);
  return price;
}

describe("Market", function () {
  it("escrows an approved ERC721 and creates an active listing", async function () {
    const { nft, market, seller } = await deployMarketFixture();
    const price = ethers.parseEther("1");

    await expect(market.connect(seller).list(nft.target, 1n, price))
      .to.emit(market, "Listed")
      .withArgs(1n, nft.target, 1n, seller.address, price);

    const listing = await market.listings(1n);
    expect(listing.nft).to.equal(nft.target);
    expect(listing.seller).to.equal(seller.address);
    expect(listing.price).to.equal(price);
    expect(listing.status).to.equal(0n);
    expect(await nft.ownerOf(1n)).to.equal(market.target);
  });

  it("cancels an active listing and returns the NFT", async function () {
    const { nft, market, seller } = await deployMarketFixture();
    await listOne(market, nft, seller);

    await expect(market.connect(seller).cancelListing(1n))
      .to.emit(market, "ListingCancelled")
      .withArgs(1n, seller.address);

    expect((await market.listings(1n)).status).to.equal(1n);
    expect(await nft.ownerOf(1n)).to.equal(seller.address);
    await expect(market.connect(seller).cancelListing(1n))
      .to.be.revertedWithCustomError(market, "InvalidListing");
  });

  it("completes a sale and exposes pull-based seller proceeds", async function () {
    const { nft, market, seller, buyer } = await deployMarketFixture();
    const price = await listOne(market, nft, seller);

    await expect(market.connect(buyer).buy(1n, { value: price }))
      .to.emit(market, "Sold")
      .withArgs(1n, buyer.address, seller.address, price);

    expect((await market.listings(1n)).status).to.equal(2n);
    expect(await nft.ownerOf(1n)).to.equal(buyer.address);
    expect(await market.pendingProceeds(seller.address)).to.equal(price);
    expect(await market.totalPendingProceeds()).to.equal(price);

    await expect(market.connect(seller).withdrawProceeds())
      .to.emit(market, "ProceedsWithdrawn")
      .withArgs(seller.address, price);
    expect(await market.pendingProceeds(seller.address)).to.equal(0n);
    expect(await market.totalPendingProceeds()).to.equal(0n);
    expect(await ethers.provider.getBalance(market.target)).to.equal(0n);
  });

  it("rejects invalid sale transitions and payments", async function () {
    const { nft, market, seller, buyer, other } = await deployMarketFixture();
    await expect(market.connect(seller).list(nft.target, 1n, 0n))
      .to.be.revertedWithCustomError(market, "InvalidPrice");
    await expect(market.connect(seller).list(nft.target, 1n, 1n))
      .to.not.be.revert(ethers);
    await expect(market.connect(buyer).buy(1n, { value: 2n }))
      .to.be.revertedWithCustomError(market, "IncorrectPayment");
    await expect(market.connect(seller).buy(1n, { value: 1n }))
      .to.be.revertedWithCustomError(market, "CannotBuyOwnListing");
    await expect(market.connect(other).cancelListing(1n))
      .to.be.revertedWithCustomError(market, "NotSeller");
  });

  it("only accepts NFT transfers during list escrow", async function () {
    const { nft, market, seller } = await deployMarketFixture();
    await expect(
      nft.connect(seller).safeTransferFrom(seller.address, market.target, 1n)
    ).to.be.revertedWithCustomError(market, "UnexpectedERC721Transfer");
  });

  it("pauses trading and uses two-step ownership", async function () {
    const { nft, market, owner, seller, buyer, other } = await deployMarketFixture();
    await market.connect(owner).pause();
    await expect(market.connect(seller).list(nft.target, 1n, 1n))
      .to.be.revertedWithCustomError(market, "EnforcedPause");
    await market.connect(owner).unpause();

    await market.connect(owner).transferOwnership(other.address);
    await market.connect(other).acceptOwnership();
    expect(await market.owner()).to.equal(other.address);
    await expect(market.connect(owner).pause()).to.be.revertedWithCustomError(
      market,
      "OwnableUnauthorizedAccount"
    );
    await market.connect(seller).list(nft.target, 1n, 1n);
    await expect(market.connect(buyer).buy(1n, { value: 1n })).not.to.be.revert(ethers);
  });

  it("does not accept unaccounted ETH", async function () {
    const { market, other } = await deployMarketFixture();
    await expect(other.sendTransaction({ to: market.target, value: 1n }))
      .to.be.revertedWithCustomError(market, "DirectPaymentNotAccepted");
  });
});
