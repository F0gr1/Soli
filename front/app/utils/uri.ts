const supportedPrefixes = ["ipfs://", "ar://", "https://", "data:application/json"];

export function isSupportedTokenUri(uri: string): boolean {
  const value = uri.trim();
  return value.length > 0 && value.length <= 2048 && supportedPrefixes.some((prefix) => {
    return value.startsWith(prefix) && value.length > prefix.length;
  });
}
