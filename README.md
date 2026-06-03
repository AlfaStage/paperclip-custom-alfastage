# Paperclip Custom Image: OpenCode, Hermes & PT-BR Localization

Este repositório contém a infraestrutura necessária para construir e publicar no **Docker Hub** uma imagem personalizada do **Paperclip** contendo suporte nativo e pré-instalado para **OpenCode**, **Hermes Agent** e localização em **Português do Brasil (pt-BR)**.

Tudo é automatizado de ponta a ponta via **GitHub Actions** e perfeitamente compatível com implantação no **Coolify**, **Traefik** ou **Cloudflare Tunnels**.

---

## 🛠️ Conteúdo do Repositório

*   `Dockerfile`: Configuração de compilação multi-stage estendendo a imagem oficial do Paperclip, instalando os runtimes globais dos agentes de IA (`opencode-ai` e `hermes-agent`) e injetando a tradução em português (`paperclip-plugin-i18n-pt-br`) na build estática do frontend.
*   `docker-compose.yml`: Ambiente de infraestrutura leve e otimizado com limites de hardware contendo apenas a imagem personalizada do Paperclip e o banco PostgreSQL necessário para sessões de autenticação em produção.
*   `.env.example`: Modelo de variáveis de ambiente para preenchimento no host.
*   `.github/workflows/docker-build-push.yml`: Workflow que compila a imagem no GitHub Actions e faz o push automático para o Docker Hub em novos commits ou semanalmente.

---

## 🚀 Guia de Implantação de Ponta a Ponta

### Passo 1: Preparação no Docker Hub
1. Crie uma conta em [hub.docker.com](https://hub.docker.com/).
2. Acesse **Account Settings** -> **Security** -> **New Access Token**.
3. Crie um token chamado `github-actions` com permissões **Read, Write, Delete**. **Copie o token gerado!**

### Passo 2: Configurando seu Repositório do GitHub
1. Crie um repositório no seu GitHub (ex: `paperclip-custom-alfastage`).
2. Suba todos os arquivos deste repositório local para o GitHub.
3. Acesse a aba **Settings** do repositório no GitHub -> **Secrets and variables** -> **Actions**.
4. Crie dois segredos repositórios clicando em **New repository secret**:
    *   `DOCKERHUB_USERNAME`: Seu nome de usuário do Docker Hub.
    *   `DOCKERHUB_TOKEN`: O token de acesso gerado no Passo 1.
5. O build iniciará imediatamente. Acompanhe na aba **Actions**. Sua imagem estará disponível no Docker Hub em poucos minutos como `seu_usuario/paperclip-custom-alfastage:latest`.

---

## 🐳 Implantação no Coolify

Para implantar no **Coolify** de forma modular, rápida e com consumo reduzido de recursos no VPS, utilize a configuração de Docker Compose abaixo.

> [!IMPORTANT]
> **Configurações de Hardware Atribuídas:**
> *   **PostgreSQL:** Limitado a `0.50 vCPU` e `512 MB` de RAM. Este limite garante recursos suficientes para a inicialização inicial do banco de dados e execução do healthcheck sem lentidão.
> *   **Paperclip:** Limitado a `1.00 vCPU` e `1.5 GB` de RAM. Este limite de 1.5 GB de RAM é o mínimo necessário para garantir que subprocessos paralelos de IA (como Node.js/OpenCode e Python/Hermes) rodem sem sofrer falhas de Out of Memory (OOM).

### Configuração do Docker Compose (Coolify):
Cole o bloco abaixo na caixa de configurações do seu serviço de Docker Compose no Coolify:

```yaml
services:
  postgres:
    image: 'postgres:16-alpine'
    restart: unless-stopped
    environment:
      POSTGRES_DB: '${DB_NAME:-paperclip}'
      POSTGRES_USER: '${DB_USER:-paperclip}'
      POSTGRES_PASSWORD: '${DB_PASSWORD:-paperclip_secret_pass}'
    volumes:
      - 'pgdata:/var/lib/postgresql/data'
    healthcheck:
      test:
        - CMD-SHELL
        - 'pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB'
      interval: 5s
      timeout: 5s
      retries: 10
      start_period: 30s
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 512M
        reservations:
          cpus: '0.20'
          memory: 256M

  paperclip:
    image: 'alfastage/paperclip-custom-alfastage:latest'
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      - SERVICE_URL_PAPERCLIP_3100
      - PORT=3100
      - HOST=0.0.0.0
      - SERVE_UI=true
      - PAPERCLIP_DEPLOYMENT_MODE=authenticated
      - PAPERCLIP_DEPLOYMENT_EXPOSURE=public
      - 'PAPERCLIP_AUTH_PUBLIC_BASE_URL=https://paperclip.labs.alfastage.com.br'
      - 'BETTER_AUTH_SECRET=${BETTER_AUTH_SECRET:-cThzOTAyNXA5dzRmNW12c2VjdXJlOGMzaGF3ZDVkMnYyNnc1ZmEy}'
      - 'DATABASE_URL=postgresql://${DB_USER:-paperclip}:${DB_PASSWORD:-paperclip_secret_pass}@postgres:5432/${DB_NAME:-paperclip}'
      - 'ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}'
      - 'OPENAI_API_KEY=${OPENAI_API_KEY}'
    volumes:
      - 'paperclip-data:/home/node/.paperclip'
      - 'hermes-skills:/root/.hermes'
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1.5G
        reservations:
          cpus: '0.25'
          memory: 512M

volumes:
  pgdata: null
  paperclip-data: null
  hermes-skills: null
```

---

## 🔑 Inicialização e Cadastro do Administrador (CEO)

No modo `authenticated` de produção, os cadastros públicos de novos usuários são totalmente bloqueados por segurança. Para configurar a primeira conta administradora (CEO), siga as etapas a seguir de forma sequencial:

### Passo 1: Acesse o Terminal do Container
Pelo painel do Coolify, selecione o container ativo da aplicação **Paperclip** e clique na aba **Console** ou **Terminal** (acessando como `root`).

### Passo 2: Crie a Configuração Estruturada do Zod
A CLI do Paperclip exige um arquivo `config.json` em um formato aninhado muito rígido validado por Zod. **Execute o comando abaixo no terminal do container para sobrescrever o arquivo de configuração com as chaves corretas:**

```bash
cat << 'EOF' > /root/.paperclip/instances/default/config.json
{
  "$meta": {
    "version": 1,
    "updatedAt": "2026-06-02T04:11:00Z",
    "source": "onboard"
  },
  "database": {
    "mode": "postgres"
  },
  "logging": {
    "mode": "file",
    "logDir": "/root/.paperclip/instances/default/logs"
  },
  "server": {
    "deploymentMode": "authenticated",
    "exposure": "public",
    "host": "0.0.0.0",
    "port": 3100,
    "serveUi": true
  },
  "auth": {
    "baseUrlMode": "explicit",
    "publicBaseUrl": "https://paperclip.labs.alfastage.com.br",
    "disableSignUp": false
  },
  "telemetry": {
    "enabled": true
  }
}
EOF
```

### Passo 3: Gere o Convite do Administrador
Com o arquivo de configuração perfeitamente validado pelo esquema do Zod, execute a CLI para inicializar o convite único:

```bash
pnpm paperclipai auth bootstrap-ceo --base-url https://paperclip.labs.alfastage.com.br
```

### Passo 4: Conclua o Cadastro
1. Copie o link exclusivo de convite impresso no terminal. Ele terá o seguinte formato:
   `https://paperclip.labs.alfastage.com.br/auth/claim-ceo?token=token_hash_aqui`
2. Abra o link no seu navegador.
3. Preencha seus dados de e-mail e senha para concluir a criação do primeiro usuário do ecossistema. Você será oficialmente autenticado como o **CEO** com acesso ao painel de orquestração.

---

## 🤖 Configuração e Resolução de Problemas nos Agentes (OpenCode & Hermes)

Após realizar o cadastro como CEO e acessar o painel do Paperclip, você poderá implantar e configurar os agentes de IA locais. Siga estas diretrizes para validar e resolver avisos comuns de funcionamento:

### 1. OpenCode Agent (`opencode_local`)
Caso o diagnóstico de probe do OpenCode aponte alertas como `Configured OpenCode model is unavailable` ou `OpenCode probe ran but did not return hello as expected`:
* **Selecione um Modelo Gratuito Ativo:** Nas configurações do Agente no painel do Paperclip, defina a propriedade do modelo para uma das opções gratuitas (Free Tier) descobertas pela CLI do OpenCode. Exemplos:
  * `opencode/deepseek-v4-flash-free`
  * `opencode/nemotron-3-super-free`
  * `opencode/minimax-m3-free`
* **Validar a Execução no Terminal:** Para testar a comunicação direta do OpenCode com os provedores a partir do container, acesse o terminal dele e execute:
  ```bash
  opencode run --format json "Respond with hello"
  ```
  Isso ajuda a diagnosticar possíveis gargalos de rede ou respostas fora do padrão esperado pelo probe do Paperclip.

### 2. Hermes Agent (`hermes_local`)
Caso o Hermes acuse ausência de chaves de API (`No LLM API keys found in environment`):
* **Configuração das Credenciais do Gemini ou OpenRouter:**
  O Hermes Agent suporta nativamente o Google Gemini (AI Studio) ou OpenRouter. Ele precisa localizar as variáveis `GEMINI_API_KEY` (ou `GOOGLE_API_KEY`) ou `OPENROUTER_API_KEY`.
  * **Opção A (Via Interface do Paperclip - Recomendado):** Acesse a edição do Agente no painel web, localize a seção de **Env Secrets / Agent Secrets** e insira as variáveis com as suas chaves correspondentes.
  * **Opção B (Via Terminal do Container):** Persista as chaves diretamente no arquivo de ambiente do volume do Hermes executando:
    ```bash
    cat << 'EOF' > /root/.hermes/.env
    GEMINI_API_KEY=sua_chave_gemini_aqui
    OPENROUTER_API_KEY=sua_chave_openrouter_aqui
    EOF
    ```


