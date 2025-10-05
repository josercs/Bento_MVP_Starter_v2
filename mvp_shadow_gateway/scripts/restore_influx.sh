#!/usr/bin/env bash
set -euo pipefail
SRC="${1:-}"
if [ -z "$SRC" ]; then
  echo "Uso: $0 <pasta_do_backup>"
  exit 1
fi
docker compose exec -T influxdb influx restore --org "${INFLUX_ORG:-retrofit4}" "$SRC"
echo "Restore concluído de $SRC"
