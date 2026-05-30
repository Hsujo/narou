#!/bin/bash
set -e

cd /novel

if [ ! -f ".narou/database.yaml" ]; then
    # Fresh first run — full init
    echo "==> First run: initializing Narou.rb..."
    narou init -p /opt/AozoraEpub3 -l 1.6
    narou setting device=epub
    narou setting server-bind=0.0.0.0
    narou setting server-port=33000
    mkdir -p .narousetting
    echo "already-server-boot: true" > .narousetting/server_setting.yaml
    echo "==> Initialization complete."
elif [ ! -f ".narousetting/global_setting.yaml" ]; then
    # .narou imported from Windows but .narousetting needs setup
    echo "==> Imported config detected, re-initializing AozoraEpub3..."
    narou init -p /opt/AozoraEpub3 -l 1.6
    narou setting server-bind=0.0.0.0
    narou setting server-port=33000
    mkdir -p .narousetting
    echo "already-server-boot: true" > .narousetting/server_setting.yaml
    echo "==> Setup complete."
fi

echo "==> Starting Narou.rb WEB UI on 0.0.0.0:33000..."
exec "$@"
