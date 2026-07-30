import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import hre, { network } from "hardhat";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function main() {
  const { ethers } = await network.create();
  const { chainId } = await ethers.provider.getNetwork();
  const chainIdString = chainId.toString();
  const deploymentPath = path.join(
    __dirname,
    "..",
    "ignition",
    "deployments",
    `chain-${chainIdString}`,
    "deployed_addresses.json"
  );
  const deployedAddresses = JSON.parse(await fs.readFile(deploymentPath, "utf8"));

  const contracts = {};
  for (const contractName of ["Nft", "Market"]) {
    const artifact = await hre.artifacts.readArtifact(contractName);
    const address = deployedAddresses[`SoliModule#${contractName}`];
    if (!address) throw new Error(`Missing Ignition address for ${contractName}`);
    contracts[contractName] = { address, abi: artifact.abi };
  }

  const output = path.join(__dirname, "..", "front", "public", "deployments");
  await fs.mkdir(output, { recursive: true });
  await fs.writeFile(
    path.join(output, `${chainIdString}.json`),
    `${JSON.stringify({ chainId: Number(chainId), network: hre.network.name, contracts }, null, 2)}\n`
  );

  console.log(`Deployment manifest written for chain ${chainIdString}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
