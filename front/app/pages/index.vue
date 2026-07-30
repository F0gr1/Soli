<script setup lang="ts">
import { BrowserProvider, Contract } from "ethers";
import type { DeploymentManifest, OwnedToken } from "../types/deployment";
import { isSupportedTokenUri } from "../utils/uri";

const config = useRuntimeConfig();
const expectedChainId = Number(config.public.defaultChainId);
const deployment = ref<DeploymentManifest>();
const provider = ref<BrowserProvider>();
const nftContract = ref<NftContractApi>();
const account = ref("");
const walletChainId = ref<number>();
const uri = ref("ipfs://");
const tokens = ref<OwnedToken[]>([]);
const status = ref("Loading the Ignition deployment manifest...");
const errorMessage = ref("");
const isBusy = ref(false);

interface NftContractApi {
  balanceOf(owner: string): Promise<bigint>;
  tokenOfOwnerByIndex(owner: string, index: bigint): Promise<bigint>;
  tokenURI(tokenId: bigint): Promise<string>;
  mint(uri: string): Promise<{ wait(): Promise<unknown> }>;
}

const chainMismatch = computed(() => {
  return walletChainId.value !== undefined && walletChainId.value !== expectedChainId;
});

const canMint = computed(() => {
  return Boolean(nftContract.value && account.value && !chainMismatch.value && !isBusy.value);
});

async function loadDeployment() {
  try {
    const manifest = await $fetch<DeploymentManifest>(`/api/deployments/${expectedChainId}`, {
      cache: "no-store",
    });
    if (manifest.chainId !== expectedChainId) {
      throw new Error(`Manifest chainId ${manifest.chainId} does not match ${expectedChainId}.`);
    }
    deployment.value = manifest;
    status.value = `Manifest loaded for ${manifest.network} (chain ${manifest.chainId}).`;
  } catch (error) {
    status.value = "Deployment manifest unavailable.";
    errorMessage.value = error instanceof Error ? error.message : "Unknown manifest error.";
  }
}

async function connectWallet() {
  errorMessage.value = "";
  if (!window.ethereum) {
    errorMessage.value = "No EIP-1193 wallet was detected. Install or open a browser wallet.";
    return;
  }
  if (!deployment.value) {
    errorMessage.value = "Deploy the contracts before connecting a wallet.";
    return;
  }

  isBusy.value = true;
  try {
    const accounts = (await window.ethereum.request({ method: "eth_requestAccounts" })) as string[];
    account.value = accounts[0] || "";
    provider.value = new BrowserProvider(window.ethereum);
    const network = await provider.value.getNetwork();
    walletChainId.value = Number(network.chainId);
    if (chainMismatch.value) {
      nftContract.value = undefined;
      tokens.value = [];
      status.value = `Wrong network: switch the wallet to chain ${expectedChainId}.`;
      return;
    }

    const signer = await provider.value.getSigner(account.value);
    nftContract.value = new Contract(
      deployment.value.contracts.Nft.address,
      deployment.value.contracts.Nft.abi,
      signer
    ) as unknown as NftContractApi;
    await loadTokens();
    status.value = `Wallet connected on chain ${walletChainId.value}.`;
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : "Wallet connection failed.";
  } finally {
    isBusy.value = false;
  }
}

async function loadTokens() {
  const contract = nftContract.value;
  const owner = account.value;
  if (!contract || !owner) return;
  const count = BigInt(await contract.balanceOf(owner));
  const loaded: OwnedToken[] = [];
  for (let index = 0n; index < count; index++) {
    const tokenId = BigInt(await contract.tokenOfOwnerByIndex(owner, index));
    const tokenUri = await contract.tokenURI(tokenId);
    loaded.push({ tokenId: tokenId.toString(), uri: tokenUri });
  }
  tokens.value = loaded;
}

async function mint() {
  errorMessage.value = "";
  const contract = nftContract.value;
  if (!canMint.value || !contract) return;
  if (!isSupportedTokenUri(uri.value)) {
    errorMessage.value = "Use a non-empty ipfs://, ar://, https://, or data:application/json URI.";
    return;
  }

  isBusy.value = true;
  try {
    const transaction = await contract.mint(uri.value.trim());
    status.value = "Mint submitted. Waiting for confirmation...";
    await transaction.wait();
    await loadTokens();
    status.value = "Mint confirmed.";
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : "Mint failed.";
  } finally {
    isBusy.value = false;
  }
}

onMounted(loadDeployment);
</script>

<template>
  <main class="page-shell">
    <div class="grain" aria-hidden="true" />
    <header class="topbar">
      <NuxtLink to="/" class="brand"><span class="brand-mark">S</span> SOLI</NuxtLink>
      <span class="network-pill">LOCAL / {{ expectedChainId }}</span>
    </header>

    <section class="hero">
      <div class="hero-copy">
        <p class="eyebrow">A SMALL ON-CHAIN STUDIO</p>
        <h1>Make a piece.<br /><em>Keep it yours.</em></h1>
        <p class="lede">Soli turns a metadata URI into an ERC-721 token you can verify, hold, and carry with your wallet.</p>
        <div class="hero-actions">
          <button class="button button-primary" type="button" :disabled="isBusy" @click="connectWallet">
            {{ account ? "Reconnect wallet" : "Connect wallet" }}
          </button>
          <span class="status" role="status">{{ status }}</span>
        </div>
      </div>
      <div class="hero-art" aria-hidden="true">
        <div class="orb orb-large" />
        <div class="orb orb-small" />
        <div class="orbit-line orbit-one" />
        <div class="orbit-line orbit-two" />
        <span class="art-label">01 / SOLI</span>
      </div>
    </section>

    <section class="mint-panel" aria-labelledby="mint-title">
      <div class="panel-copy">
        <p class="eyebrow">PERMISSIONLESS MINT</p>
        <h2 id="mint-title">Give the chain<br />something real to hold.</h2>
        <p>Minting is open to every wallet. There is no protocol fee or allowlist. The contract validates the URI and uses safeMint.</p>
      </div>
      <form class="mint-form" @submit.prevent="mint">
        <label for="uri">Metadata URI</label>
        <input id="uri" v-model="uri" type="text" autocomplete="off" placeholder="ipfs://..." :disabled="isBusy" />
        <div class="form-footer">
          <span class="hint">ipfs:// · ar:// · https:// · data:application/json</span>
          <button class="button button-dark" type="submit" :disabled="!canMint">
            {{ isBusy ? "Working..." : "Mint NFT" }} <span aria-hidden="true">↗</span>
          </button>
        </div>
      </form>
    </section>

    <p v-if="chainMismatch" class="alert">Wallet chain {{ walletChainId }} does not match deployment chain {{ expectedChainId }}. Transactions are disabled.</p>
    <p v-if="errorMessage" class="alert" role="alert">{{ errorMessage }}</p>

    <NftCard :items="tokens" />

    <footer class="footer">
      <span>SOLI / EXPERIMENTAL</span>
      <span>Market contract deployed; fixed-price sale UI is intentionally out of scope.</span>
    </footer>
  </main>
</template>

<style>
:root {
  color: #142225;
  background: #f3efe7;
  font-family: "Avenir Next", Avenir, Helvetica, Arial, sans-serif;
}

* { box-sizing: border-box; }

body { margin: 0; }

button, input { font: inherit; }

button { cursor: pointer; }

button:disabled { cursor: not-allowed; opacity: 0.5; }

.page-shell {
  margin: 0 auto;
  max-width: 1280px;
  min-height: 100vh;
  overflow: hidden;
  padding: 1.25rem clamp(1.1rem, 4vw, 4.5rem) 2rem;
  position: relative;
}

.grain {
  background-image: radial-gradient(rgba(20, 34, 37, 0.12) 0.65px, transparent 0.65px);
  background-size: 5px 5px;
  inset: 0;
  opacity: 0.08;
  pointer-events: none;
  position: absolute;
}

.topbar, .hero, .mint-panel, .footer, .alert, .collection { position: relative; z-index: 1; }

.topbar { align-items: center; display: flex; justify-content: space-between; }

.brand { align-items: center; color: #142225; display: flex; font-size: 0.8rem; font-weight: 800; gap: 0.6rem; letter-spacing: 0.2em; text-decoration: none; }

.brand-mark { align-items: center; background: #142225; border-radius: 50%; color: #e8b36d; display: inline-flex; font-family: Georgia, serif; font-size: 1.1rem; height: 2rem; justify-content: center; letter-spacing: 0; width: 2rem; }

.network-pill { border: 1px solid rgba(20, 34, 37, 0.28); border-radius: 100px; color: #526467; font-size: 0.68rem; letter-spacing: 0.12em; padding: 0.5rem 0.75rem; }

.hero { display: grid; gap: 3rem; grid-template-columns: minmax(0, 1fr) minmax(260px, 0.8fr); min-height: 510px; padding: clamp(4rem, 10vw, 8rem) 0 3rem; }

.eyebrow { color: #967255; font-size: 0.7rem; font-weight: 800; letter-spacing: 0.18em; margin: 0 0 1.2rem; text-transform: uppercase; }

h1, h2 { font-family: Georgia, "Times New Roman", serif; font-weight: 500; letter-spacing: -0.04em; }

h1 { font-size: clamp(3.4rem, 8vw, 7.4rem); line-height: 0.9; margin: 0; }

h1 em { color: #967255; font-style: italic; }

.lede { color: #526467; font-size: 1.05rem; line-height: 1.65; margin: 2rem 0 2.2rem; max-width: 31rem; }

.hero-actions { align-items: center; display: flex; flex-wrap: wrap; gap: 1rem; }

.button { border: 0; border-radius: 0; font-size: 0.78rem; font-weight: 800; letter-spacing: 0.1em; padding: 0.9rem 1.15rem; text-transform: uppercase; }

.button-primary { background: #e8b36d; color: #142225; }

.button-dark { background: #142225; color: #f3efe7; }

.status { color: #526467; font-size: 0.8rem; }

.hero-art { align-items: center; background: #b9cfc5; display: flex; justify-content: center; min-height: 350px; overflow: hidden; position: relative; }

.orb { background: #e8b36d; border-radius: 50%; position: absolute; }

.orb-large { height: 190px; transform: translate(15px, -8px); width: 190px; }

.orb-small { background: #142225; height: 38px; transform: translate(-70px, 85px); width: 38px; }

.orbit-line { border: 1px solid rgba(20, 34, 37, 0.46); border-radius: 50%; height: 290px; position: absolute; transform: rotate(-26deg); width: 110px; }

.orbit-one { transform: rotate(38deg); }

.orbit-two { height: 110px; transform: rotate(-38deg); width: 290px; }

.art-label { bottom: 1rem; color: #142225; font-size: 0.7rem; font-weight: 800; left: 1rem; letter-spacing: 0.15em; position: absolute; }

.mint-panel { background: #e0a96b; display: grid; gap: 3rem; grid-template-columns: 0.8fr 1.2fr; padding: clamp(1.5rem, 4vw, 3.5rem); }

.mint-panel h2 { font-size: clamp(2.1rem, 4vw, 3.8rem); line-height: 0.95; margin: 0 0 1.3rem; }

.panel-copy p:last-child { color: rgba(20, 34, 37, 0.75); line-height: 1.55; max-width: 22rem; }

.mint-form { align-self: end; }

.mint-form label { display: block; font-size: 0.75rem; font-weight: 800; letter-spacing: 0.1em; margin-bottom: 0.6rem; text-transform: uppercase; }

.mint-form input { background: transparent; border: 0; border-bottom: 1px solid rgba(20, 34, 37, 0.45); border-radius: 0; color: #142225; font-family: Georgia, serif; font-size: clamp(1.3rem, 3vw, 2rem); outline: none; padding: 0.65rem 0; width: 100%; }

.mint-form input:focus { border-color: #142225; }

.form-footer { align-items: center; display: flex; flex-wrap: wrap; gap: 1rem; justify-content: space-between; margin-top: 1.3rem; }

.hint { color: rgba(20, 34, 37, 0.66); font-size: 0.72rem; }

.alert { background: #f4c7bd; color: #6e2d24; font-size: 0.85rem; margin: 1rem 0 0; padding: 0.8rem 1rem; }

.footer { border-top: 1px solid rgba(20, 34, 37, 0.16); color: #526467; display: flex; font-size: 0.68rem; justify-content: space-between; letter-spacing: 0.08em; margin-top: 4rem; padding-top: 1rem; text-transform: uppercase; }

@media (max-width: 700px) {
  .hero { grid-template-columns: 1fr; min-height: auto; padding-top: 4.5rem; }
  .hero-art { min-height: 260px; }
  .mint-panel { grid-template-columns: 1fr; }
  .footer { flex-direction: column; gap: 0.7rem; }
}
</style>
