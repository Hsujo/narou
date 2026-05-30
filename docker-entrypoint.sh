#!/bin/bash
set -e

cd /novel

# First time initialization
if [ ! -f ".narou/global_setting.yaml" ]; then
    echo "==> First run: initializing Narou.rb..."
    narou init -p /opt/AozoraEpub3 -l 1.6
    narou setting device=epub
    echo "==> Initialization complete."
fi

echo "==> Starting Narou.rb WEB UI..."
exec "$@"
