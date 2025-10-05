# Retrofit4 — MVP Shadow Gateway (S7-1200 Modbus/TCP)

## Como usar (resumo)
1) **TIA Portal**
   - Importe os DBs (`DB500/501/510/520.scl`), cole `FB200_MVP.scl` e `OB1_MVP.scl` no projeto.
   - Configure IP do S7-1200 (ex.: 192.168.1.121), conecte os sinais e faça **Download**.

2) **Stack (PC/Edge)**
   ```bash
   cd mvp_shadow_gateway
   # edite .env (IP do CLP, senhas/tokens, tags SITE/LINHA/MAQUINA)
   docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
   ```

3) **Acessos**
   - Grafana: http://localhost:3000  → Dashboards: *MVP — OEE Starter*, *MVP — Paradas*
   - InfluxDB: http://localhost:8086  → org `retrofit4`, bucket `mvp`

4) **Arquivos úteis**
   - `README_MVP_S7-1200.md` → guia completo do TIA
   - `mvp_shadow_gateway/README_DEPLOY.md` → plano 30–60 dias + critérios
   - `mvp_shadow_gateway/SECURITY_CHECKLIST.md` → segurança
   - `collector.py` → leitor Modbus mínimo (opcional)
   - `modbus_map_mvp.csv` → mapa Modbus

> Para MQTT, defina `MQTT_ENABLE=true` no `.env` e reinicie o compose.
