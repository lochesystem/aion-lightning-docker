# Runbook — Aion Lightning (Docker)

Documento operacional único: preparar o **código-fonte**, subir a stack, operar em **VPS** e manter **versão no GitHub**.  
Repo: **só orquestração Docker + overlays**; o emulador (JARs, `static_data`) vive no repositório **aion-lightning-work** (ou cópia tua).

---

## 1. O que este repositório faz

| Componente | Função |
|------------|--------|
| `docker-compose.yml` | Modo **bridge** (Docker Desktop Windows/Linux típico). Login publica **2107 / 7780 / 10241**. |
| `docker-compose.host.yml` | Modo **host network** (recomendado em **VPS Linux**). |
| `config-overrides/` | `database.properties`, `network.properties`, `ipconfig.xml`, template do chat. |
| `mariadb/initdb/` | Cria bases `al_server_ls` / `al_server_gs`, user `aion`, importa SQL montados do *work*. |
| Scripts | `start-aion-docker.ps1`, `import-aion-databases.ps1`, `migrate-mysql-to-aion-docker.ps1`, `install-wsl-for-docker.*` |

**Não inclui:** `AL-Login.jar`, `AL-Game.jar`, `ax-chat-*.jar`, pastas `static_data` — vêm do *work* já compilado (`ant dist`).

---

## 2. Requisitos de hardware (referência)

| Recurso | Mínimo razoável | Confortável |
|---------|------------------|-------------|
| RAM | ~4 GB (host + containers) | 8 GB+ |
| CPU | 2 vCPU | 4+ |
| Disco | 20 GB+ SSD | 40 GB+ |

*Game Server* é o mais pesado; MariaDB + Login + Chat somam menos, mas o primeiro arranque do GS pode demorar vários minutos.

---

## 3. Repositório irmão: `aion-lightning-work`

1. Clonar / ter cópia do **aion-lightning-work** com `aion-lightning-2.7`.
2. Em cada módulo (ou raiz do projeto, conforme o teu `build.xml`):
   - **AL-Login:** `ant dist` → `build/dist` com `AL-Login.jar` em `libs/`.
   - **AL-Game:** `ant dist` → `build/Dist` com `AL-Game.jar`.
   - **ChatServer:** `ant dist` → `build/dist/chatserver` com `ax-chat-*.jar`.
3. Garantir ficheiros SQL:
   - `AL-Login/sql/al_server_ls.sql`
   - `AL-Game/sql/al_server_gs.sql`

**Chat `client.advertise`:** o teu ChatServer deve incluir a propriedade `chatserver.network.client.advertise` (ver histórico do projeto / ramo actual). Sem isso, em modo bridge o anúncio do chat ao cliente pode falhar fora do mesmo PC.

---

## 4. Configuração local: `compose.env`

1. Copiar `compose.env.example` → **`compose.env`** (o ficheiro `compose.env` está no `.gitignore` — **nunca** commits com passwords).
2. Ajustar:

| Variável | Descrição |
|----------|-----------|
| `AION_WORK_ROOT` | Caminho **absoluto** à raiz do *work* (`C:/path` ou `/home/user/...`). |
| `MYSQL_ROOT_PASSWORD` | Password root do MariaDB no contentor (forte em produção). |
| `AION_PUBLIC_ADDRESS` | IPv4 que **jogadores** usam para te alcançar: público da VPS, LAN, ou Tailscale `100.x`. |

3. **`config-overrides/game/network/ipconfig.xml`**  
   - `default` e faixas **Tailscale** devem refletir o **mesmo** IP que os clientes usam no login.  
   - Em VPS: `default` = **IP público** (ou deixar só faixas + default coerente com a tua rede).

4. **`config-overrides/host/chat/config/chatserver.properties`** (só modo `host`)  
   - `chatserver.network.client.address` = `IP_VISÍVEL:10241`.

---

## 5. Arranque — Windows (Docker Desktop)

1. WSL2 + Docker Desktop (ver `README.md` e `install-wsl-for-docker` se o engine falhar).
2. `git clone` deste repo ao lado do *work* (ou ajusta `AION_WORK_ROOT`).
3. `chmod +x mariadb/initdb/01-import-databases.sh` (Git no Windows: `git update-index --chmod=+x ...`).
4. Na pasta deste repo:
   ```powershell
   .\start-aion-docker.ps1
   ```
   ou:
   ```powershell
   docker compose --env-file compose.env up -d --build
   ```
5. Import / refresh SQL (opcional após mudar dumps):
   ```powershell
   .\import-aion-databases.ps1
   ```
6. MariaDB exposto em **`127.0.0.1:3306`** no compose bridge (só máquina local) — útil para *db-browser*.

---

## 6. Arranque — Linux (dev ou VPS)

### 6.1 Bridge (igual ao Windows)

```bash
cd /opt/aion-lightning-docker   # ou o teu caminho
docker compose --env-file compose.env up -d --build
./import-aion-databases.sh      # opcional: usar import-aion-databases.ps1 vía pwsh, ou ver script bash abaixo
```

*Nota:* O script PowerShell `import-aion-databases.ps1` funciona em Linux com **PowerShell Core** (`pwsh`). Alternativa: usar `docker exec` como documentado no próprio script ou correr o SQL manualmente.

### 6.2 Host network (recomendado em VPS)

1. Editar `config-overrides/host/chat/config/chatserver.properties` (`client.address`).
2. Alinhar `config-overrides/game/network/ipconfig.xml` ao IP público / LAN.
3. Subir:
   ```bash
   docker compose -f docker-compose.host.yml --env-file compose.env up -d --build
   ```

Volumes MariaDB: **`mariadb_data_host`** (distinto do modo bridge).

---

## 7. Cloud / VPS (checklist genérico)

Fornecedores típicos: **Oracle Cloud Ampere (free tier)**, **Hetzner**, **Contabo**, **DigitalOcean**, etc.

1. **SO:** Ubuntu 22.04 ou 24.04 LTS amd64 (ARM: testar `docker compose build` no destino).
2. **Docker:** instalar [Docker Engine](https://docs.docker.com/engine/install/ubuntu/) + plugin Compose.
3. **Bootstrap rápido** (opcional):
   ```bash
   chmod +x scripts/bootstrap-vps.sh
   sudo ./scripts/bootstrap-vps.sh
   ```
4. Copiar para o servidor:
   - Este repositório (`aion-lightning-docker`).
   - O *work* compilado **ou** o código-fonte + `ant`/`jdk8` no servidor.
5. Criar `compose.env` no servidor com `AION_WORK_ROOT` apontando para o caminho **no VPS**.
6. **Firewall / Security Group**
   - Abrir **TCP: 2107, 7780, 10241** para a internet (ou só para IPs conhecidos).
   - **Não** expor **3306** publicamente. Acesso DB: SSH tunnel ou rede privada.
7. **`AION_PUBLIC_ADDRESS`** = IPv4 elástico/público da VPS (ou Tailscale se todo o tráfego for pela VPN).
8. Subir stack (preferir **`docker-compose.host.yml`** em Linux nu).
9. Validar:
   ```bash
   docker compose -f docker-compose.host.yml --env-file compose.env ps
   docker compose -f docker-compose.host.yml --env-file compose.env logs login --tail 30
   docker compose -f docker-compose.host.yml --env-file compose.env logs game --tail 30
   ```

### 7.1 Oracle Cloud Always Free (nota)

- **Ampere A1 (ARM):** boa RAM gratuita; imagens base `eclipse-temurin` costumam ter variantes **arm64** — validar com `docker compose build`.
- **VM AMD1 GB:** normalmente **insuficiente** para esta stack completa.

---

## 8. Operação corrente

| Acção | Comando |
|--------|---------|
| Estado | `docker compose --env-file compose.env ps` |
| Logs GS | `docker compose --env-file compose.env logs -f game` |
| Parar | `docker compose --env-file compose.env down` |
| Apagar dados DB | `docker compose --env-file compose.env down -v` (**irreversível**) |

**Backup:** volume Docker `mariadb_data` / `mariadb_data_host` — usar `docker run` com `mysqldump` ou backup de volume conforme a tua política.

**Migrar DB externa para o contentor:** ver `migrate-mysql-to-aion-docker.ps1` (origem remota → MariaDB Docker).

---

## 9. Versionamento no GitHub

### 9.1 Primeira publicação (no teu PC)

```bash
cd /caminho/para/aion-lightning-docker
git init
git branch -M main
git add .
git commit -m "Initial import: Aion Lightning Docker stack"
```

Criar repositório **vazio** no GitHub (sem README se já tens local).

```bash
git remote add origin https://github.com/SEU_USUARIO/aion-lightning-docker.git
git push -u origin main
```

### 9.2 O que **não** commitar

- `compose.env` (secrets) — já listado no `.gitignore`.
- Ficheiros do *work* (`build/dist`, passwords).

### 9.3 Releases

- Usar [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github) com notas que apontem para **tag** + `CHANGELOG.md`.
- Alinhar versão semântica (`v1.0.0`) com alterações em compose / overlays.

### 9.4 CI

Workflow `.github/workflows/validate-compose.yml` valida `docker compose config` nos dois ficheiros compose em cada push/PR.

---

## 10. Problemas frequentes

| Sintoma | Causa provável |
|---------|----------------|
| Cliente não liga ao login | Firewall; `AION_PUBLIC_ADDRESS` errado; IP no cliente ≠ IP do servidor. |
| Chat falha após entrar no mundo | `client.advertise` / Chat antigo sem propriedade `advertise`. |
| Lista de servidores com IP errado | `ipconfig.xml` do GS; modo bridge + NAT Docker (ver overlays). |
| `load fail! *.html` no voo (nível &lt; 9) | Cliente sem HTML retail; patch em `DialogService` / `gameserver.simple.secondclass.enable` no *work*. |
| MariaDB sem tabelas | Volume já inicializado sem import; correr `import-aion-databases.ps1` ou `down -v` + subir de novo (apaga dados). |

---

## 11. Referências cruzadas

- `README.md` — visão geral e quick start.
- `CHANGELOG.md` — histórico de versões deste repo.
- `SECURITY.md` — reporte de vulnerabilidades e secrets.
- Repositório **aion-lightning-work** (se existir): `docs/cursor-handoff-runbook/DOCKER-STACK.md` para contexto do código-fonte.

---

*Última revisão estrutural: alinhada ao repo `aion-lightning-docker` para deploy em fornecedor cloud e GitHub.*
