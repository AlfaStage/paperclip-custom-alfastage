# syntax=docker/dockerfile:1.20
FROM node:lts-trixie-slim AS base
ARG USER_UID=1000
ARG USER_GID=1000

# Instalação das dependências de sistema necessárias para Paperclip, OpenCode e Hermes
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     ca-certificates \
     gosu \
     curl \
     gh \
     git \
     wget \
     ripgrep \
     python3 \
     python3-pip \
     python3-venv \
     build-essential \
  && rm -rf /var/lib/apt/lists/* \
  && corepack enable

# Remapeamento do UID/GID para evitar conflitos de permissões com volumes montados
RUN usermod -u $USER_UID --non-unique node \
  && groupmod -g $USER_GID --non-unique node \
  && usermod -g $USER_GID -d /paperclip node

# Instalação global do OpenCode AI CLI
RUN npm install -g opencode-ai

# Instalação global do Hermes Agent utilizando o instalador oficial do Nous Research
RUN curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
ENV PATH="/root/.hermes/bin:$PATH"

FROM base AS deps
WORKDIR /app
# Cópia das estruturas do monorepo Paperclip e instalação de dependências via pnpm
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml .npmrc ./
COPY cli/package.json cli/
COPY server/package.json server/
COPY ui/package.json ui/
COPY packages/shared/package.json packages/shared/
COPY packages/db/package.json packages/db/
COPY packages/adapter-utils/package.json packages/adapter-utils/
COPY packages/mcp-server/package.json packages/mcp-server/
COPY packages/skills-catalog/package.json packages/skills-catalog/
COPY packages/adapters/acpx-local/package.json packages/adapters/acpx-local/
COPY packages/adapters/claude-local/package.json packages/adapters/claude-local/
COPY packages/adapters/codex-local/package.json packages/adapters/codex-local/
COPY packages/adapters/cursor-local/package.json packages/adapters/cursor-local/
COPY packages/adapters/cursor-cloud/package.json packages/adapters/cursor-cloud/
COPY packages/adapters/gemini-local/package.json packages/adapters/gemini-local/
COPY packages/adapters/grok-local/package.json packages/adapters/grok-local/
COPY packages/adapters/opencode-local/package.json packages/adapters/opencode-local/
COPY packages/adapters/openclaw-gateway/package.json packages/adapters/openclaw-gateway/
COPY packages/adapters/pi-local/package.json packages/adapters/pi-local/

RUN pnpm install --frozen-lockfile

FROM deps AS builder
WORKDIR /app
COPY . .
# Instalação do plugin de tradução pt-br para a interface
RUN pnpm --filter ui add paperclip-plugin-i18n-pt-br
RUN pnpm build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app /app

EXPOSE 3100
CMD ["node", "--import", "./server/node_modules/tsx/dist/loader.mjs", "server/dist/index.js"]
