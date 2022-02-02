const { ethers } = require("hardhat");

async function main() {
  const Nft = await ethers.getContractFactory("Nft");
  const nft = await Nft.deploy("name", "symbol");

  await nft.deployed();

  console.log("Nft deployed to:", nft.address);
}
main()
	  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });