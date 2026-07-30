import type { InterfaceAbi } from "ethers";

export interface ContractManifest {
  address: string;
  abi: InterfaceAbi;
}

export interface DeploymentManifest {
  chainId: number;
  network: string;
  contracts: {
    Nft: ContractManifest;
    Market: ContractManifest;
  };
}

export interface OwnedToken {
  tokenId: string;
  uri: string;
}
