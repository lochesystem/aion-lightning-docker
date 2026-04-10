# Política de segurança

## Versões suportadas

Este repositório é **infraestrutura como código** (Docker Compose). Não distribui binários do jogo Aion. Corrige vulnerabilidades nas **imagens base** (ex.: `eclipse-temurin`, `mariadb`) ao **reconstruir** imagens com tags actualizadas e ao manter o host actualizado.

## Reportar um problema

Se encontrares uma vulnerabilidade **neste repositório** (Compose, scripts, documentação que incentive práticas inseguras), abre um **issue** privado no GitHub (se disponível) ou contacta os maintainers do fork.

## Boas práticas obrigatórias

1. **Nunca** commits o ficheiro `compose.env` — contém passwords. Usa só `compose.env.example` como modelo.
2. **Não** exponhas **MariaDB (3306)** à Internet pública em produção.
3. Usa passwords fortes para `MYSQL_ROOT_PASSWORD` e mantém `aion` / `aionlocal` apenas em ambientes de desenvolvimento isolados.
4. Em VPS, prefere **firewall** (ufw, security groups) limitando **2107, 7780, 10241** a IPs conhecidos quando possível.

## Dependências

- Imagens: `docker.io/library/mariadb:10.11`, `eclipse-temurin:8-jdk-jammy`, `eclipse-temurin:8-jre-jammy`.
- Monitoriza [avisos de segurança](https://github.com/adoptium) e [MariaDB](https://mariadb.org/about/security/) para as versões que pinas no Compose.
