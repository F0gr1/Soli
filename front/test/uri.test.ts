import { describe, expect, it } from "vitest";
import { isSupportedTokenUri } from "../app/utils/uri";

describe("isSupportedTokenUri", () => {
  it("accepts the URI schemes supported by the NFT contract", () => {
    expect(isSupportedTokenUri("ipfs://cid/metadata.json")).toBe(true);
    expect(isSupportedTokenUri("ar://transaction")).toBe(true);
    expect(isSupportedTokenUri("https://example.com/metadata.json")).toBe(true);
    expect(isSupportedTokenUri("data:application/json,{\"name\":\"Soli\"}")).toBe(true);
  });

  it("rejects empty, unsupported, and overlong values", () => {
    expect(isSupportedTokenUri("")).toBe(false);
    expect(isSupportedTokenUri("http://example.com/metadata.json")).toBe(false);
    expect(isSupportedTokenUri("ipfs://")).toBe(false);
    expect(isSupportedTokenUri(`https://${"x".repeat(2048)}`)).toBe(false);
  });
});
