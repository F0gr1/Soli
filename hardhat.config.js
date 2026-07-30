import hardhatToolboxMochaEthers from "@nomicfoundation/hardhat-toolbox-mocha-ethers";

const sepolia =
  process.env.SEPOLIA_RPC_URL && process.env.SEPOLIA_PRIVATE_KEY
    ? {
        type: "http",
        url: process.env.SEPOLIA_RPC_URL,
        chainId: 11155111,
        accounts: [process.env.SEPOLIA_PRIVATE_KEY],
      }
    : undefined;

/** @type import("hardhat/config").HardhatUserConfig */
export default {
  plugins: [hardhatToolboxMochaEthers],
  networks: {
    hardhat: {
      type: "edr-simulated",
      chainId: 31337,
    },
    localhost: {
      type: "http",
      url: process.env.HARDHAT_LOCALHOST_URL || "http://127.0.0.1:8545",
      chainId: 31337,
    },
    ...(sepolia ? { sepolia } : {}),
  },
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: "cancun",
    },
  },
  mocha: {
    timeout: 40000,
  },
};
