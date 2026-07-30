FROM node:24.16.0-bookworm-slim AS contract-base

WORKDIR /workspace
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts --no-audit --no-fund
COPY contracts ./contracts
COPY hardhat.config.js ./hardhat.config.js
COPY ignition ./ignition
COPY scripts ./scripts

FROM contract-base AS chain
EXPOSE 8545
CMD ["npm", "run", "chain"]

FROM contract-base AS deploy
COPY front/public ./front/public
CMD ["npm", "run", "deploy:local"]

FROM node:24.16.0-bookworm-slim AS frontend-build

WORKDIR /app
COPY front/package.json front/package-lock.json ./
RUN npm ci --include=optional --ignore-scripts --no-audit --no-fund
COPY front ./
RUN npm run build

FROM node:24.16.0-bookworm-slim AS frontend

WORKDIR /app
ENV NODE_ENV=production
COPY --from=frontend-build /app/.output ./.output
EXPOSE 3000
CMD ["node", ".output/server/index.mjs"]
