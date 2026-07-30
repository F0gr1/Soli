import { readFile } from "node:fs/promises";
import path from "node:path";
import { createError, defineEventHandler, getRouterParam } from "h3";

export default defineEventHandler(async (event) => {
  const chainId = getRouterParam(event, "chainId");
  if (!chainId || !/^\d+$/.test(chainId)) {
    throw createError({ statusCode: 400, statusMessage: "Invalid chain ID" });
  }

  const directory = process.env.SOLI_DEPLOYMENT_DIR || path.join(process.cwd(), "public", "deployments");
  try {
    return JSON.parse(await readFile(path.join(directory, `${chainId}.json`), "utf8"));
  } catch {
    throw createError({ statusCode: 404, statusMessage: "Deployment manifest not found" });
  }
});
