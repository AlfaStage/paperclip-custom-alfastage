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

# Instalação global do Codex CLI e Gemini CLI
RUN npm install -g @openai/codex @google/gemini-cli


FROM base AS deps
WORKDIR /app
# Copia todo o workspace para garantir que todos os pacotes (incluindo plugins e adaptadores adicionados) estejam presentes
COPY . .
RUN pnpm install --frozen-lockfile

FROM deps AS builder
WORKDIR /app
# Instalação do plugin de tradução pt-br para a interface
RUN pnpm --filter ui add paperclip-plugin-i18n-pt-br
RUN pnpm build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app /app

EXPOSE 3100
CMD ["node", "--import", "./server/node_modules/tsx/dist/loader.mjs", "server/dist/index.js"]
