#!/usr/bin/env bash
set -euo pipefail

ORG=${ORG:-retrofit4}
USER_NAME=${USER_NAME:-admin}
PASS=${PASS:-$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)}

ENV_DIR="$(cd "$(dirname "$0")/.."; pwd)"
ENV_FILE="$ENV_DIR/.env"
ENV_EXAMPLE="$ENV_DIR/.env.example"

if [ ! -f "$ENV_FILE" ]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  sed -i.bak "s/<definir-no-setup>/$PASS/g" "$ENV_FILE"
  sed -i.bak "s/<preencher-pelo-setup>/will_be_set/g" "$ENV_FILE"
  echo ".env criado"
fi

pushd "$ENV_DIR" >/dev/null
docker compose up -d influxdb grafana
sleep 15

docker exec mvp_influxdb influx setup --bucket mvp --org "$ORG" --username "$USER_NAME" --password "$PASS" --force --retention 30d >/dev/null 2>&1 || true

TOKEN=$(docker exec mvp_influxdb influx auth create --all-access --json | jq -r '.token')
echo "Token gerado: ${TOKEN:0:8}..."

docker exec mvp_influxdb influx bucket create -n mvp_raw -o "$ORG" -r 2160h || true
docker exec mvp_influxdb influx bucket create -n mvp_agg -o "$ORG" -r 17520h || true

sed -i.bak "s/^INFLUX_TOKEN=.*/INFLUX_TOKEN=$TOKEN/g" "$ENV_FILE"

TASK_FILE="/mnt/influx/tasks/oee_agg_15m.flux"
docker cp "$ENV_DIR/influx/tasks/oee_agg_15m.flux" mvp_influxdb:$TASK_FILE
docker exec mvp_influxdb influx task create -f $TASK_FILE -o "$ORG" -t "$TOKEN" || true

popd >/dev/null
echo "Setup concluído."
