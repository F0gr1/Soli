# Soli frontend

Nuxt 4 and Vue 3 client for local Soli NFT minting. It reads `/api/deployments/<chainId>`, backed by a manifest generated from the Hardhat Ignition deployment after deployment. There are no hardcoded contract addresses or private runtime secrets.

```sh
npm ci
npm run dev
npm run typecheck
npm run test
npm run build
npm run start
```

The wallet must be on the manifest chain. Marketplace sale actions are intentionally not part of this UI.
