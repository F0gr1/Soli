# Soli

Soli is a small NFT studio for creating ERC-721 tokens from metadata URIs. The repository contains a Hardhat 3 contract workspace and a Nuxt 4 client. The default workflow is local-only; no contract is deployed by this repository to a public network.

## Specification

### NFT

- `Nft` is an OpenZeppelin Contracts 5 ERC-721 with URI storage and enumeration.
- Minting is permissionless: any wallet can mint one token to itself, with no protocol fee, allowlist, cap, or owner approval.
- A mint URI must be 1-2048 bytes and start with `ipfs://`, `ar://`, `https://`, or `data:application/json`, followed by content.
- Mint uses `_safeMint`, emits `Minted`, and token IDs start at `1`.
- The owner can pause and unpause minting and token transfers. Ownership uses `Ownable2Step`.
- The contract does not promise that off-chain URI content is immutable, available, or safe to render.

### Market

`Market` is an escrow-based ERC-721 fixed-price sale contract. It is deliberately separate from minting.

- `list(nft, tokenId, price)` requires ERC-721 support, current ownership, and approval, then transfers the token into escrow.
- `cancelListing` is available only to the seller and returns the escrowed token.
- `buy` requires exact native-token payment, marks the listing sold before the external NFT transfer, and transfers the NFT to the buyer.
- Sale proceeds are credited to `pendingProceeds[seller]`; sellers must call `withdrawProceeds`.
- Direct native-token transfers are rejected. The accounting invariant is `totalPendingProceeds == sum(pendingProceeds)` for recorded sales.
- Active, Cancelled, and Sold are terminally distinct states. A token can be listed again only after a cancelled or completed sale has returned it to an owner.
- `Pausable`, `ReentrancyGuard`, `Ownable2Step`, checks-effects-interactions, custom errors, and events are used for the critical paths.
- The frontend intentionally excludes listing, cancellation, buying, and withdrawal UI. Use the contract ABI directly or add a separately reviewed marketplace client.

### State transitions

```text
NFT:        Unminted -> Minted -> Transferred*   (*while unpaused)
Listing:    Active -> Cancelled -> NFT returned
Listing:    Active -> Sold -> NFT delivered + seller proceeds pending -> Withdrawn
```

## Threat model and limits

- A wallet is assumed to protect its own private key and to review the chain and transaction before signing.
- The contracts protect escrow custody, exact payment, replay-free listing state transitions, pull-based withdrawals, and reentrancy-sensitive paths.
- URI validation is syntax-only. Soli does not fetch, scan, pin, moderate, or authenticate metadata.
- The marketplace has no royalties, fees, auctions, signatures, ERC-20 payment support, upgradeability, or dispute/refund process.
- A malicious ERC-721 implementation can lie about ERC-165 support or behave unexpectedly; only trusted collections should be listed.
- Forced native-token transfers such as `selfdestruct` can create an unaccounted surplus that no function treats as seller proceeds.
- The contracts have not received an independent third-party audit. `npm audit` covers JavaScript dependency advisories, not Solidity correctness.

## Required versions

- Node.js `24.16.0`
- npm `11.x`
- Hardhat `3.11.1`
- ethers `6.17.0`
- `@nomicfoundation/hardhat-toolbox-mocha-ethers` `3.0.7` with Hardhat Ignition
- Solidity `0.8.28`
- OpenZeppelin Contracts `5.6.1`
- Nuxt `4.5.1` and Vue `3.5.40`

Use a Node version manager or the same `node:24.16.0-bookworm-slim` image used by Docker. Hardhat 3 requires an ESM project; do not reintroduce Waffle, `@nomiclabs/*`, ethers 5, Nuxt 2, Vue 2, BootstrapVue, or Web3.

## Docker Compose

```sh
docker compose config
docker compose build
docker compose up -d --wait
curl http://127.0.0.1:3000/api/health
```

Compose starts a Hardhat JSON-RPC chain, waits for `eth_chainId=31337`, runs the Ignition deployment once, exports the manifest into a shared volume, and starts Nuxt after deployment completes. The frontend health endpoint is `/api/health`.

The local Hardhat node uses deterministic development accounts and keys. They are public test keys and must never be funded, reused, or configured in production. The frontend runtime config contains only public chain ID/RPC URL values; no private key, API token, or RPC secret is bundled.

Stop and remove the local stack with `docker compose down -v` when a clean chain and manifest are required.

## Native workflow

```sh
npm ci
npm run compile
npm test
npm run frontend:install
npm run frontend:typecheck
npm run frontend:test
npm run frontend:build
```

For a browser-connected local workflow, use two terminals:

```sh
npm run chain
npm run deploy:local
npm --prefix front run dev
```

The deployment command uses `ignition/modules/Soli.js` and writes `front/public/deployments/31337.json`. Generated deployment manifests are ignored by Git. `scripts/export-deployment.js` reads addresses from the Ignition deployment manifest and ABI data from Hardhat artifacts; the Nuxt server exposes the selected manifest through `/api/deployments/<chainId>`. The frontend does not contain a fixed address or copied sample ABI.

## Tests, coverage, and audit

- `npm test` covers mint validation, safe mint ownership, pause controls, ownership transfer, escrow, listing cancellation, exact payment, proceeds withdrawal, direct-transfer rejection, and sale transitions.
- `npm --prefix front run test` covers the frontend URI validation boundary.
- `npm run coverage` executes JavaScript coverage around the Hardhat test command. Hardhat 3 currently has no official Solidity instrumentation plugin; the legacy `solidity-coverage` package requires Hardhat 2 and is intentionally not mixed into this project. Solidity coverage remains a residual risk until a Hardhat 3-compatible instrumenter is selected.
- `npm run audit` and `npm --prefix front run audit` inspect runtime dependency advisories. The optional `npm run audit:full` also scans Hardhat's development tree; it currently reports upstream advisories with no compatible fix in the Hardhat 3 toolbox without downgrading the required toolchain. `npm audit` is not a substitute for a Solidity audit.

## Sepolia

Sepolia is the only public testnet referenced by the configuration. It is opt-in and requires local environment variables:

```sh
export SEPOLIA_RPC_URL="https://your-provider.example/sepolia"
export SEPOLIA_PRIVATE_KEY="0xyour-test-wallet-key"
npm run deploy:sepolia
```

Never commit these values, use a mainnet key, or paste them into Nuxt runtime config. The repository contains no provider secret, fixed Infura URL, Rinkeby URL, or pre-deployed public address. No public deployment is performed by CI or this README.

Before a public deployment, verify the provider chain ID is `11155111`, review the Ignition manifest, fund only a disposable test wallet, and perform an independent contract review.
