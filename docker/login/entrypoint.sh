#!/bin/sh
set -e
cd /opt/aion/login

if [ ! -f ./libs/AL-Login.jar ]; then
  echo "libs/AL-Login.jar nao encontrado — corra ant dist em AL-Login." >&2
  exit 1
fi

exec java -Xms128m -Xmx128m -server \
  -cp "./libs/*" \
  com.aionlightning.loginserver.LoginServer
