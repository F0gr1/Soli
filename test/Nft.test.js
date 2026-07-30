import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.create();

async function deployNftFixture() {
  const [owner, creator, recipient] = await ethers.getSigners();
  const Nft = await ethers.getContractFactory("Nft");
  const nft = await Nft.deploy("Soli", "SOLI");
  await nft.waitForDeployment();
  return { nft, owner, creator, recipient };
}

describe("Nft", function () {
  it("sets the deployer as the initial owner", async function () {
    const { nft, owner } = await deployNftFixture();
    expect(await nft.owner()).to.equal(owner.address);
    expect(await nft.name()).to.equal("Soli");
    expect(await nft.symbol()).to.equal("SOLI");
  });

  it("allows permissionless minting with a supported URI", async function () {
    const { nft, creator } = await deployNftFixture();
    const uri = "ipfs://bafybeigdyrztoken/metadata.json";

    await expect(nft.connect(creator).mint(uri))
      .to.emit(nft, "Minted")
      .withArgs(creator.address, 1n, uri);

    expect(await nft.ownerOf(1n)).to.equal(creator.address);
    expect(await nft.tokenURI(1n)).to.equal(uri);
    expect(await nft.totalSupply()).to.equal(1n);
    expect(await nft.tokenOfOwnerByIndex(creator.address, 0n)).to.equal(1n);
    expect(await nft.nextTokenId()).to.equal(2n);
  });

  it("rejects empty, unsupported, and oversized URIs", async function () {
    const { nft, creator } = await deployNftFixture();
    await expect(nft.connect(creator).mint("")).to.be.revertedWithCustomError(
      nft,
      "InvalidTokenURI"
    );
    await expect(nft.connect(creator).mint("http://example.com/item.json"))
      .to.be.revertedWithCustomError(nft, "InvalidTokenURI");
    await expect(nft.connect(creator).mint("ipfs://"))
      .to.be.revertedWithCustomError(nft, "InvalidTokenURI");
    await expect(nft.connect(creator).mint("x".repeat(2049)))
      .to.be.revertedWithCustomError(nft, "InvalidTokenURI");
  });

  it("pauses minting and transfers", async function () {
    const { nft, owner, creator, recipient } = await deployNftFixture();
    await nft.connect(creator).mint("https://example.com/item.json");

    await nft.connect(owner).pause();
    await expect(nft.connect(creator).mint("ar://item"))
      .to.be.revertedWithCustomError(nft, "EnforcedPause");
    await expect(nft.connect(creator).transferFrom(creator.address, recipient.address, 1n))
      .to.be.revertedWithCustomError(nft, "EnforcedPause");

    await nft.connect(owner).unpause();
    await nft.connect(creator).transferFrom(creator.address, recipient.address, 1n);
    expect(await nft.ownerOf(1n)).to.equal(recipient.address);
  });

  it("uses two-step ownership transfer", async function () {
    const { nft, owner, recipient } = await deployNftFixture();
    await nft.connect(owner).transferOwnership(recipient.address);
    expect(await nft.pendingOwner()).to.equal(recipient.address);
    await nft.connect(recipient).acceptOwnership();
    expect(await nft.owner()).to.equal(recipient.address);
  });
});
