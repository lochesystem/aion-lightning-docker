#!/bin/bash
set -euo pipefail
# Cria bases, utilizador aion@% (mysql_native_password) e importa SQL montados em /mnt/aion-import/
# (ficheiros bind separados no compose — nao dentro de docker-entrypoint-initdb.d por causa de :ro + mounts aninhados)

ROOT_PW="${MYSQL_ROOT_PASSWORD:-}"
if [ -z "${ROOT_PW}" ]; then
  echo "MYSQL_ROOT_PASSWORD não definida" >&2
  exit 1
fi

mysql=(mysql -uroot -p"${ROOT_PW}" -h localhost)

"${mysql[@]}" <<-EOSQL
CREATE DATABASE IF NOT EXISTS al_server_ls CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE IF NOT EXISTS al_server_gs CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER IF NOT EXISTS 'aion'@'%' IDENTIFIED VIA mysql_native_password USING PASSWORD('aionlocal');
GRANT ALL PRIVILEGES ON al_server_ls.* TO 'aion'@'%';
GRANT ALL PRIVILEGES ON al_server_gs.* TO 'aion'@'%';
FLUSH PRIVILEGES;
EOSQL

if [ -f /mnt/aion-import/al_server_ls.sql ]; then
  echo "Importando al_server_ls..."
  "${mysql[@]}" al_server_ls < /mnt/aion-import/al_server_ls.sql
else
  echo "AVISO: /mnt/aion-import/al_server_ls.sql em falta (verifique AION_WORK_ROOT no compose)." >&2
fi

if [ -f /mnt/aion-import/al_server_gs.sql ]; then
  echo "Importando al_server_gs..."
  "${mysql[@]}" al_server_gs < /mnt/aion-import/al_server_gs.sql
else
  echo "AVISO: /mnt/aion-import/al_server_gs.sql em falta." >&2
fi

echo "Init MariaDB concluído."
