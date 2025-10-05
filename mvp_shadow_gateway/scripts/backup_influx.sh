#!/usr/bin/env bash
set -euo pipefail
TS=$(date +"%Y%m%d_%H%M%S")
DEST="./backups/influx_${TS}"
mkdir -p "$DEST"
docker compose exec -T influxdb influx backup --org "${INFLUX_ORG:-retrofit4}" "$DEST"
echo "Backup salvo em $DEST"
