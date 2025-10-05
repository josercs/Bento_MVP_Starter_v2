# Como aplicar este patch
1) Substitua o `telegraf.conf` por `telegraf.patched.conf` (ou aponte o volume para ele).
2) Crie/edite `.env` com `SITE`, `LINHA`, `MAQUINA` e, se quiser, `MQTT_ENABLE=true`.
3) Inicie com isolamento local:
   ```bash
   docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
   ```
4) (Opcional) Backup:
   ```bash
   ./scripts/backup_influx.sh
   ```
