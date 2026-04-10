# Changelog

Todas as alterações notáveis ao repositório **aion-lightning-docker** serão documentadas aqui.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-PT/1.0.0/), e este projecto adere a [Semantic Versioning](https://semver.org/lang/pt-BR/) onde aplicável.

## [Unreleased]

## [1.0.0] — 2026-04-09

### Adicionado

- Documentação **GitHub-ready**: `docs/RUNBOOK.md`, `SECURITY.md`, `CHANGELOG.md`.
- `scripts/bootstrap-vps.sh` para Ubuntu (Docker Engine + Compose).
- Workflow GitHub Actions: validação `docker compose config`.
- `docker-compose.host.yml`: montagem de `ipconfig.xml` alinhada ao modo bridge.
- README reestruturado com índice e ligações à documentação.

### Contexto

- Stack: MariaDB 10.11, Login/Game (JDK 8), Chat (JRE 8), overlays em `config-overrides/`.
- Scripts: `start-aion-docker.ps1`, `import-aion-databases.ps1`, `migrate-mysql-to-aion-docker.ps1`.

<!-- Após o primeiro push: substitui TEU_ORG pelo teu utilizador ou organização GitHub. -->
[Unreleased]: https://github.com/TEU_ORG/aion-lightning-docker/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/TEU_ORG/aion-lightning-docker/releases/tag/v1.0.0
