#!/bin/sh
set -e

echo "A aguardar Login/Game (10s)..."
sleep 10

cd /opt/aion/chat

TEMPLATE="/opt/aion/chat/config/chatserver.properties.template"
OUT="/opt/aion/chat/config/chatserver.properties"
if [ ! -f "$TEMPLATE" ]; then
  echo "Ficheiro em falta: $TEMPLATE" >&2
  exit 1
fi
cp "$TEMPLATE" "$OUT"
if [ -n "$AION_PUBLIC_ADDRESS" ]; then
  echo "chatserver.network.client.advertise = ${AION_PUBLIC_ADDRESS}:10241" >> "$OUT"
  echo "Chat: bind *:10241, anunciar aos clientes ${AION_PUBLIC_ADDRESS}:10241"
fi

CHAT_JAR=""
for j in ax-chat-*.jar; do
  if [ -f "$j" ]; then
    CHAT_JAR="$j"
    break
  fi
done

if [ -z "$CHAT_JAR" ]; then
  echo "ax-chat-*.jar não encontrado — corra ant dist no ChatServer." >&2
  exit 1
fi

exec java -Xms8m -Xmx32m -ea \
  -cp "./libs/*:${CHAT_JAR}" \
  com.aionengine.chatserver.ChatServer
