# aion-lightning-docker

Compose **Docker** para correr **MariaDB**, **Login Server**, **Game Server** e **Chat Server** do emulador **Aion Lightning** (AL 2.7), usando imagens **Eclipse Temurin 8** e **MariaDB 10.11**.

Este repositório contém **só** orquestração, Dockerfiles, overlays de configuração e scripts. Os **JARs**, **static_data** e SQL vêm do repositório **aion-lightning-work** (o teu fork ou clone local) já compilados com `ant dist`.

---

## Documentação

| Documento | Conteúdo |
|-----------|----------|
| **[docs/RUNBOOK.md](docs/RUNBOOK.md)** | **Runbook completo:** preparar o *work*, Windows, Linux, VPS/cloud, firewall, GitHub, CI, troubleshooting. |
| [SECURITY.md](SECURITY.md) | Secrets, exposição de portas, reporte de problemas. |
| [CHANGELOG.md](CHANGELOG.md) | Histórico de versões deste repo. |

---

## Requisitos rápidos

1. **aion-lightning-work** (ou equivalente) com:
   - `aion-lightning-2.7/AL-Login/build/dist`
   - `aion-lightning-2.7/AL-Game/build/Dist`
   - `aion-lightning-2.7/ChatServer/build/dist/chatserver`
   - `AL-Login/sql/al_server_ls.sql` e `AL-Game/sql/al_server_gs.sql`
2. **Docker** (Desktop no Windows com WSL2; **Engine** no Linux).
3. **`compose.env`** a partir de [`compose.env.example`](compose.env.example) (não commitares o `compose.env`).

---

## Início rápido

```bash
cp compose.env.example compose.env
# Edita AION_WORK_ROOT, MYSQL_ROOT_PASSWORD, AION_PUBLIC_ADDRESS
chmod +x mariadb/initdb/01-import-databases.sh
docker compose --env-file compose.env up -d --build
```

**Windows (PowerShell):** `.\start-aion-docker.ps1`

**Linux VPS (rede host):** ver secção no [RUNBOOK](docs/RUNBOOK.md) — `docker compose -f docker-compose.host.yml --env-file compose.env up -d --build`

**Import SQL** (reaplicar schema/dados oficiais do repo): `.\import-aion-databases.ps1` (PowerShell) ou instruções no RUNBOOK.

---

## Modos de rede

| Ficheiro | Uso |
|----------|-----|
| `docker-compose.yml` | **Bridge** — recomendado no **Docker Desktop** (Windows/macOS). Login expõe **2107**, **7780**, **10241**. MariaDB em **127.0.0.1:3306** no host (ferramentas locais). |
| `docker-compose.host.yml` | **Host** — típico em **VPS Linux**; volume MariaDB `mariadb_data_host`. |

Chat em bridge usa `AION_PUBLIC_ADDRESS` + template em `config-overrides/chat/`. Em host, edita `config-overrides/host/chat/config/chatserver.properties`.

---

## Variáveis `compose.env` (resumo)

| Variável | Descrição |
|----------|-----------|
| `AION_WORK_ROOT` | Caminho absoluto à raiz do *work* com `aion-lightning-2.7`. |
| `MYSQL_ROOT_PASSWORD` | Password root do MariaDB no contentor. |
| `AION_PUBLIC_ADDRESS` | IPv4 que os **clientes** usam (público, LAN ou Tailscale); usado no anúncio do chat em modo bridge. |

Credenciais emu nos overlays: **`aion` / `aionlocal`**.

---

## Scripts

| Script | Função |
|--------|--------|
| `start-aion-docker.ps1` | Arranca Docker Desktop se preciso; `compose up -d --build`. |
| `import-aion-databases.ps1` | Importa `al_server_*.sql` para o MariaDB do contentor. |
| `migrate-mysql-to-aion-docker.ps1` | Migra bases de outro MySQL/MariaDB para o contentor. |
| `install-wsl-for-docker.ps1` / `.cmd` | Ajuda a instalar WSL quando o Docker Desktop falha (Windows). |
| `scripts/bootstrap-vps.sh` | Instala Docker Engine + Compose em **Ubuntu** (correr com `sudo`). |

---

## Portas

| Serviço | TCP | Notas |
|---------|-----|--------|
| Login (clientes) | 2107 | Público em produção |
| Game (clientes) | 7780 | Idem |
| Chat (clientes) | 10241 | Idem |
| Login ↔ Game | 9016 | Só interno / localhost na stack bridge |
| Game ↔ Chat | 9021 | Idem |
| MariaDB | 3306 | **Não** expor à Internet; em bridge mapeado a `127.0.0.1` no host |

---

## Publicar no GitHub

```bash
git init
git branch -M main
git add .
git commit -m "chore: initial aion-lightning-docker stack"
git remote add origin https://github.com/TEU_USUARIO/aion-lightning-docker.git
git push -u origin main
```

Cria **Release** `v1.0.0` quando estiveres estável; actualiza `CHANGELOG.md`. O workflow **validate-compose** corre em cada push/PR.

---

## Licença

O **código deste repositório** (Compose, scripts, docs) está sob **MIT** — ver [LICENSE](LICENSE). Podes alterar para outra licença no teu fork se precisares.

O **Aion Lightning** e o cliente oficial **Aion** continuam sujeitos às licenças e termos do projeto de emulador e da editora que utilizas no **aion-lightning-work**. Este repo **não** inclui assets proprietários do cliente oficial.

---

## Créditos

Baseado na stack **Aion Lightning** / AL 2.7 e na documentação do *work* associado. Ajusta caminhos e forks conforme o teu projeto.
