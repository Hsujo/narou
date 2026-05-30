#!/bin/bash
set -e

cd /novel

# First time initialization
if [ ! -f ".narou/global_setting.yaml" ]; then
    echo "==> First run: initializing Narou.rb..."
    narou init -p /opt/AozoraEpub3 -l 1.6
    narou setting device=epub
    narou setting server-bind=127.0.0.1
    narou setting server-port=33000

    # Skip first-boot interactive confirmation
    mkdir -p /novel/.narousetting
    echo "already-server-boot: true" > /novel/.narousetting/server_setting.yaml

    echo "==> Initialization complete."
fi

echo "==> Starting Narou.rb WEB UI on 127.0.0.1:33000..."
exec "$@"
