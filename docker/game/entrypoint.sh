#!/bin/sh
set -e

echo "A aguardar Login Server (8s)..."
sleep 8

cd /opt/aion/game

if [ ! -f AL-Game.jar ]; then
  echo "AL-Game.jar não encontrado — corra ant dist em AL-Game." >&2
  exit 1
fi

JAVA_OPTS="${JAVA_OPTS:--Xms512m -Xmx1024m -server}"

exec java $JAVA_OPTS -ea \
  -javaagent:./libs/al-commons-1.3.jar \
  -cp "./libs/*:AL-Game.jar" \
  com.aionemu.gameserver.GameServer
