export default defineNuxtConfig({
  devtools: { enabled: false },
  compatibilityDate: "2025-07-15",
  runtimeConfig: {
    public: {
      defaultChainId: Number(process.env.NUXT_PUBLIC_CHAIN_ID || "31337"),
      rpcUrl: process.env.NUXT_PUBLIC_RPC_URL || "http://127.0.0.1:8545",
    },
  },
  app: {
    head: {
      title: "Soli NFT Studio",
      meta: [
        { name: "description", content: "Permissionless NFT minting on a local EVM chain." },
        { name: "viewport", content: "width=device-width, initial-scale=1" },
      ],
    },
  },
});
