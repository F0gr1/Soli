import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("SoliModule", (m) => {
  const name = m.getParameter("name", "Soli");
  const symbol = m.getParameter("symbol", "SOLI");
  const nft = m.contract("Nft", [name, symbol]);
  const market = m.contract("Market");

  return { nft, market };
});
