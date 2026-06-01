# Paperclip Custom Image: OpenCode, Hermes & PT-BR Localization

Este repositório contém a infraestrutura necessária para construir e publicar no **Docker Hub** uma imagem personalizada do **Paperclip** contendo suporte nativo e pré-instalado para **OpenCode**, **Hermes Agent** e localização para **Português do Brasil (pt-BR)**.

Tudo é automatizado de ponta a ponta via **GitHub Actions** e perfeitamente compatível com implantação no **Coolify**, **Traefik** ou **Cloudflare Tunnels**.

---

## 🛠️ Conteúdo do Repositório

*   `Dockerfile`: Configuração de compilação multi-stage estendendo a imagem oficial do Paperclip, instalando os runtimes globais dos agentes de IA (`opencode-ai` e `hermes-agent`) e injetando a tradução em português (`paperclip-plugin-i18n-pt-br`) na build estática do frontend.
*   `docker-compose.yml`: Ambiente de infraestrutura leve contendo apenas a imagem personalizada do Paperclip e o banco PostgreSQL necessário para sessões de autenticação em produção.
*   `.env.example`: Modelo de variáveis de ambiente para preenchimento.
*   `.github/workflows/docker-build-push.yml`: Este workflow compila a imagem no GitHub Actions e faz o push automático para sua conta do Docker Hub toda vez que você altera o código ou semanalmente (para buscar novidades oficiais do Paperclip).

---

## 🚀 Como Fazer Tudo Funcionar (Passo a Passo)

### Passo 1: Preparação no Docker Hub
1. Crie uma conta gratuita em [hub.docker.com](https://hub.docker.com/).
2. Vá em **Account Settings** -> **Security** -> **New Access Token**.
3. Crie um token chamado `github-actions` com permissões **Read, Write, Delete**. **Copie o token gerado!**

### Passo 2: Configurando seu Repositório do GitHub
1. Crie um novo repositório no seu GitHub (ex: `paperclip-custom-alfastage`).
2. Suba todos os arquivos deste diretório local para o seu repositório no GitHub.
3. Vá na aba **Settings** do seu repositório no GitHub -> **Secrets and variables** (no menu esquerdo) -> **Actions**.
4. Clique em **New repository secret** e adicione dois segredos:
    *   `DOCKERHUB_USERNAME`: Seu nome de usuário do Docker Hub.
    *   `DOCKERHUB_TOKEN`: O token de acesso seguro gerado no Passo 1.

O GitHub Actions iniciará a compilação da imagem imediatamente. Você pode acompanhar o progresso na aba **Actions**. Assim que terminar, sua imagem estará visível no Docker Hub como `usuario_dockerhub/paperclip-custom-alfastage:latest`.

---

## 🐳 Implantação no Coolify (ou Traefik / Tunnels)

Com a imagem publicada no seu Docker Hub, suba sua aplicação no Coolify com as seguintes etapas:

1. **PostgreSQL Database:** No Coolify, crie um recurso do tipo **PostgreSQL** para o banco de dados do Paperclip e copie a string de conexão interna gerada.
2. **Nova Aplicação:** Crie um recurso do tipo **Docker Image** apontando para a sua imagem customizada:
    `seu_usuario_dockerhub/paperclip-custom-alfastage:latest`
3. **Porta:** Defina a porta exposta como **`3100`**.
4. **Variáveis de Ambiente:** Adicione os seguintes dados na aba **Environment Variables**:
    *   `PAPERCLIP_DEPLOYMENT_MODE=authenticated`
    *   `PAPERCLIP_DEPLOYMENT_EXPOSURE=public`
    *   `PAPERCLIP_AUTH_PUBLIC_BASE_URL=https://seu-dominio-aqui.com`
    *   `BETTER_AUTH_SECRET=um_segredo_longo_gerado_com_openssl`
    *   `DATABASE_URL=sua_string_de_conexao_do_postgresql`
    *   `ANTHROPIC_API_KEY=sua_chave_da_anthropic`
    *   `OPENAI_API_KEY=sua_chave_da_openai`
5. **SSL/TLS & Deploy:** Insira o domínio HTTPS desejado e clique em **Deploy**. O Coolify gerará o certificado SSL automaticamente.

---

## 🔑 Criando o Usuário Administrador (CEO)

Como o modo `authenticated` é focado em segurança, os cadastros públicos são bloqueados por padrão. Para habilitar seu primeiro acesso:

1. No painel do Coolify, acesse a aplicação do Paperclip e clique na aba **Console** ou **Terminal** do container.
2. Execute o utilitário integrado de inicialização para obter um link de convite exclusivo:
    ```bash
    pnpm paperclipai auth bootstrap-ceo --base-url https://seu-dominio-aqui.com
    ```
3. O terminal imprimirá um link exclusivo de convite de uso único parecido com isto:
    `https://seu-dominio-aqui.com/auth/claim-ceo?token=sua_hash_segura_aqui`
4. Copie esse link, abra no seu navegador, finalize seu cadastro e você será oficialmente o **CEO** com acesso total ao dashboard!
