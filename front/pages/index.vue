<template>
  <v-container>
  </v-container>
</template>

<script>
import Web3 from "web3";
import ABI from "../abi/Nft.json";
export default {
  data() {
    return {
      web3: null,
      nftContract: null,
      endpoint: 'https://rinkeby.infura.io/v3/7a1c5aa3ad5548869dfb3795a0436054',
      contractAddress: "Hi",
    };
  },
  async created() {
    const web3 = new Web3(this.endpoint);
    const abi = ABI.abi;
    const nftContract = new web3.eth.Contract(abi, this.contractAddress);
    this.web3 = web3;
    this.nftContract = nftContract;
    try {
      const newAccounts = await ethereum.request({
        method: "eth_requestAccounts",
      });
      const accounts = newAccounts;
      if (accounts[0] !== "") {
        this.web3.eth.defaultAccount = accounts[0];
      } else {
        console.error("ログインに失敗");
      }
    } catch (error) {
      console.error(error);
    }
  },
};
</script>