# Grafana — Datasource e Dashboards (MVP)

## Datasource (provisionado)
Arquivo: `grafana/provisioning/datasources/influxdb.yml`
- UID: `influx-mvp`
- Tipo: InfluxDB (Flux)
- URL: `http://influxdb:8086`
- Organization: `${INFLUX_ORG}` (do `.env`)
- Bucket padrão: `${INFLUX_BUCKET}` (do `.env`)
- Token: `${INFLUX_TOKEN}` (do `.env`)

Ao subir o Grafana via Compose, esse datasource é criado automaticamente.

## Dashboards (provisionados)
Arquivo: `grafana/provisioning/dashboards/dashboards.yml`
- Provedor "MVP Dashboards" aponta para `/var/lib/grafana/dashboards`.
- Dashboards incluídos:
  - `dashboards/oee_mvp.json`
  - `dashboards/stops_mvp.json`

Esses arquivos são montados no container e importados automaticamente no startup do Grafana.

## Screenshots
Coloque imagens PNG nesta pasta: `grafana/screenshots/` com os nomes abaixo para exibição automática:

![MVP — OEE Starter](./screenshots/oee_mvp.png)
![MVP — Paradas](./screenshots/stops_mvp.png)

Como exportar no Grafana:
- Abra o dashboard, ajuste o intervalo de tempo e clique no título do painel ou no menu de dashboard → Share → Export → Save as PNG.
- Salve como `oee_mvp.png` e `stops_mvp.png` nesta pasta.

## Queries Flux de exemplo
Use o datasource `influx-mvp` (provisionado) nas consultas abaixo.

Qualidade (se já processada no Telegraf):
```flux
from(bucket: v.bucket)
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "modbus" and r._field == "Quality")
```

RUN % por minuto (coil 0/1 → %):
```flux
from(bucket: v.bucket)
  |> range(start: v.timeRangeStart)
  |> filter(fn: (r) => r._measurement == "modbus" and r._field == "RUN")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
  |> map(fn: (r) => ({ r with _value: r._value * 100.0 }))
  |> yield(name: "RUN_%")
```

Taxa de produção (peças/min) com `GoodCount` (derivada não-negativa):
```flux
from(bucket: v.bucket)
  |> range(start: v.timeRangeStart)
  |> filter(fn: (r) => r._measurement == "modbus" and r._field == "GoodCount")
  |> derivative(unit: 1m, nonNegative: true)
  |> rename(columns: {"_value": "GoodRate_per_min"})
```

Analógicos normalizados (%):
```flux
from(bucket: v.bucket)
  |> range(start: v.timeRangeStart)
  |> filter(fn: (r) => r._measurement == "modbus" and (r._field == "Current_pct" or r._field == "Vibration_pct"))
```

Eventos de parada gravados pelo serviço `stops` (duração em segundos):
```flux
from(bucket: v.bucket)
  |> range(start: v.timeRangeStart)
  |> filter(fn: (r) => r._measurement == "events" and r.type == "stop" and r._field == "duration_s")
```

Observações:
- Se existirem tags como `site/linha/maquina`, adicione `and r.site == "SITE"` nos filtros.
- Ajuste `every:` nas janelas para o ritmo do processo (ex.: 5s, 10s, 1m).

## Acesso rápido
- Grafana (host): http://127.0.0.1:3001
- Login padrão: `admin` / `admin` (ou conforme `.env`)
- Datasource UID: `influx-mvp` (use em painéis e queries Flux)

## Ajustes comuns
- Se mudar `INFLUX_*` no `.env`, derrube e suba o Grafana para reprovisionar:
```powershell
docker compose -f .\docker-compose.yml -f .\docker-compose.override.yml restart grafana
```
- Para editar dashboards, salve alterações em JSON e mantenha-os no diretório `grafana/dashboards` para versionamento.
