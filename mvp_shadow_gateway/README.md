# MVP Shadow Gateway — Execução, Configuração e Diagnóstico (Windows)

Este guia explica como configurar, iniciar e diagnosticar o stack (InfluxDB, Grafana, Telegraf e serviço de Paradas) do MVP Shadow Gateway.

## Visão geral
- InfluxDB 2 (persistência) e Grafana (dashboards) sobem via Docker Compose.
- Telegraf lê o S7-1200 via Modbus/TCP e grava no InfluxDB.
- Serviço opcional `stops` detecta paradas (RUN=0 por N segundos) e escreve eventos no Influx.
- Mosquitto (MQTT) é opcional e fica em um perfil separado para evitar conflitos de porta.

## Pré‑requisitos
- Windows 10/11 com Docker Desktop instalado e rodando:
  - Docker CLI ≥ 28, Docker Compose v2.
- Rede com visibilidade ao IP do CLP (porta 502/TCP liberada).

Verifique versões:
```powershell
docker --version
docker compose version
```

## Estrutura e arquivos relevantes
- `.env`: configurações (IP do CLP, org/bucket/token do Influx, admin do Grafana, tags SITE/LINHA/MAQUINA, MQTT opcional).
- `docker-compose.yml`: serviços base (influxdb, grafana, telegraf, stops, mosquitto).
- `docker-compose.override.yml`: ajustes locais (rede/segurança) e portas adicionais para acesso local:
  - Grafana em 127.0.0.1:3001 → container 3000
  - InfluxDB em 127.0.0.1:8087 → container 8086
- `telegraf/telegraf.conf`: entrada Modbus (coils e holding registers) e processador Starlark (Quality, Good/Scrap 32-bit, normalização).
- `services/stops/stops.py`: lê RUN via Modbus e grava eventos de parada no Influx.
 - `grafana/provisioning/datasources/influxdb.yml`: datasource InfluxDB (Flux) provisionado (UID `influx-mvp`).
 - `grafana/dashboards/*.json`: dashboards provisionados (OEE Starter e Paradas). Veja `grafana/README_DASHBOARDS.md`.

### Screenshots rápidos
Se existirem os arquivos a seguir, eles serão exibidos:

![OEE Starter](./grafana/screenshots/oee_mvp.png)
![Paradas](./grafana/screenshots/stops_mvp.png)

Para gerar as imagens e queries Flux de exemplo, consulte `grafana/README_DASHBOARDS.md`.

## Configuração
1) Edite `.env` (dentro de `mvp_shadow_gateway/`):
   - `MB_HOST`: IP do S7‑1200 acessível a partir do host Docker.
   - `MB_UNIT`: 1 por padrão (ajuste se necessário).
   - `INFLUX_*`, `GRAFANA_*`: credenciais padrões já definidas; altere em produção.
   - `SITE`, `LINHA`, `MAQUINA`: tags para relatórios.
   - `MQTT_ENABLE=false` por padrão (habilite apenas se precisar MQTT).

2) Mapa Modbus (padrão em `telegraf.conf`):
   - Coils: 1=S1_piece, 2=S2_scrap, 3=RUN.
   - Holding: 1=Current_x10, 2=Vibration_x10, 10..11=GoodCount_lo/hi, 12..13=ScrapCount_lo/hi.
   - Byte order `AB` e `scale=1.0` aplicados (normalização posterior via Starlark).

## Subir os serviços
No PowerShell, a partir da pasta `mvp_shadow_gateway`:
```powershell
# (opcional) garantir que o Docker Desktop esteja aberto
Start-Process -FilePath "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Subir serviços principais
docker compose -f .\docker-compose.yml -f .\docker-compose.override.yml up -d influxdb grafana telegraf

# Ver estado
docker compose ps
```
Acessos:
- Grafana: http://127.0.0.1:3001 (admin/admin por padrão do .env)
- InfluxDB: http://127.0.0.1:8087 (org `retrofit4`, bucket `mvp`)

Observações:
- Se aparecer aviso “attribute `version` is obsolete”, é inofensivo.
- O override também publica 3000/8086 padrão; prefira 3001/8087 para evitar conflito local.

### Logins e credenciais padrão
- Grafana: usuário `admin`, senha `admin` (variáveis `GRAFANA_USER`/`GRAFANA_PASS` no `.env`).
- InfluxDB (UI): usuário `admin`, senha `admin123` (variáveis `INFLUX_USER`/`INFLUX_PASS`).
- InfluxDB (APIs/Telegraf/datasource): token `admintoken` (variável `INFLUX_TOKEN`).
- Organização/Bucket: `retrofit4` / `mvp`.

Notas importantes:
- As variáveis `DOCKER_INFLUXDB_INIT_*` do Influx só têm efeito na primeira inicialização do volume. Para reconfigurar do zero, derrube com `down -v` (apaga dados).
- Altere rapidamente as senhas na UI após o primeiro login para ambientes reais.
- Para produção, prefira usar os scripts de setup (`scripts/setup.ps1` ou `scripts/setup.sh`): eles sobem Influx/Grafana, criam org/buckets (`mvp_raw` e `mvp_agg`), geram um `INFLUX_TOKEN` novo e gravam esse token no seu `.env`, além de instalar a task de agregação de 15 min. Assim você evita usar credenciais/tokens de exemplo do compose.

## Serviço de Paradas (stops)
Subir quando desejar:
```powershell
docker compose -f .\docker-compose.yml -f .\docker-compose.override.yml up -d stops
docker logs -f mvp_stops
```
Variáveis relevantes (no `.env`):
- `STOP_THRESHOLD` (segundos, padrão 120).
- Usa `MB_HOST/MB_UNIT` e credenciais do Influx do `.env`.

Reiniciar apenas este serviço:
```powershell
docker restart mvp_stops
```

## MQTT (opcional)
O Mosquitto está em um perfil Compose chamado `mqtt` para evitar conflito com a porta 1883.
```powershell
# Subir mosquitto somente se necessário
docker compose --profile mqtt -f .\docker-compose.yml -f .\docker-compose.override.yml up -d mosquitto
```
No Telegraf, a saída MQTT só é habilitada quando `MQTT_ENABLE=true` no `.env`.

Saída MQTT (quando habilitada) usa `MQTT_HOST`, `MQTT_PORT` e `MQTT_TOPIC_PREFIX` do `.env`.

## Diagnóstico rápido (Smoke tests)
- Grafana:
```powershell
(Invoke-WebRequest http://127.0.0.1:3001/ -UseBasicParsing).StatusCode  # Esperado: 200
```
- InfluxDB:
```powershell
(Invoke-WebRequest http://127.0.0.1:8087/health -UseBasicParsing).StatusCode  # Esperado: 200
```
- Logs Telegraf:
```powershell
docker logs --tail 100 mvp_telegraf
```

- Reiniciar Telegraf após mudar `MB_HOST`/`MB_UNIT` ou `telegraf.conf`:
```powershell
docker restart mvp_telegraf
```

## Solução de Problemas
- Porta 1883 ocupada:
  - Mosquitto só inicia com `--profile mqtt`. Não suba se já existir outro broker rodando.
- Conflito nas portas 3000/8086:
  - Use os binds locais 3001 (Grafana) e 8087 (Influx) do `docker-compose.override.yml`.
  - Ajuste as portas no override se ainda houver conflito.
- Telegraf reiniciando por erro de configuração:
  - O `telegraf.conf` já está no formato do Telegraf 1.30 (arrays `coils`/`holding_registers`, `byte_order`, `data_type`, `scale`).
  - O processador Starlark foi simplificado e validado para calcular Quality e composições 32-bit.
- Timeout Modbus (`i/o timeout`):
  - Verifique `MB_HOST`/.env, reachability (ping) e firewall da rede até o CLP na porta 502/TCP.
  - Ajuste `timeout` no `[[inputs.modbus]]` se a rede for lenta.
- InfluxDB/Grafana não iniciam:
  - Veja `docker compose ps` e `docker logs mvp_influxdb|mvp_grafana`.
  - Caso reste sujeira: `docker compose down -v` e suba novamente.

- Sem dados chegando (painéis vazios):
  - Confirme reachability para o CLP: `Test-NetConnection -ComputerName <MB_HOST> -Port 502`.
  - Veja logs do Telegraf: tempos de `i/o timeout` indicam falta de rota/firewall para 502/TCP.
  - Valide que os endereços Modbus configurados existem no CLP.

## Operações úteis
```powershell
# Parar tudo
docker compose -f .\docker-compose.yml -f .\docker-compose.override.yml down

# Parar e apagar volumes (cuidado: apaga dados)
docker compose -f .\docker-compose.yml -f .\docker-compose.override.yml down -v

# Reiniciar apenas Telegraf
docker restart mvp_telegraf

# Ver serviços
docker compose ps
```

## Backup/Restore do InfluxDB
Os scripts `scripts/backup_influx.sh` e `scripts/restore_influx.sh` são Bash (Linux/WSL). Em Windows puro, você pode usar estes passos rápidos:

Backup (gera pasta local `backups`):
```powershell
$ts = (Get-Date).ToString('yyyyMMdd_HHmmss')
New-Item -ItemType Directory -Force -Path .\backups | Out-Null
docker exec mvp_influxdb influx backup /var/lib/influxdb2/backup -t $env:INFLUX_TOKEN -o $env:INFLUX_ORG
docker cp mvp_influxdb:/var/lib/influxdb2/backup .\backups\influx_$ts
```

Restore (cuidado: sobrescreve dados no Influx em execução):
```powershell
# Ajuste o caminho da pasta de backup que deseja restaurar
$bkp = ".\backups\<pasta_do_backup>"
docker cp $bkp mvp_influxdb:/var/lib/influxdb2/restore
docker exec mvp_influxdb influx restore /var/lib/influxdb2/restore -t $env:INFLUX_TOKEN -o $env:INFLUX_ORG --full
```

Retenção de dados: padrão `30d` em `DOCKER_INFLUXDB_INIT_RETENTION`. Para alterar depois da primeira inicialização, use a UI/CLI do Influx para editar a retention policy do bucket.

## Dicas rápidas (CLP/Modbus)
- Garanta que o S7-1200 (MB_SERVER) esteja no mesmo segmento de rede do host ou com rota/NAT adequada.
- Mapa Modbus padrão (coils 1..3 e holding 1,2,10..13). Ajuste em `telegraf/telegraf.conf` conforme seu projeto.
- Intervalos de coleta: `agent.interval = 500ms` (ajuste se necessário).

## Recomendações no lado do PLC (S7‑1200)
- Use detecção de borda (R_TRIG) para os sinais de peça boa/sucata (S1_piece/S2_scrap) e aplique antirruído (debounce) de 10–30 ms para evitar contagens indevidas por bounce.
- Armazene contadores de Good/Scrap como UDInt (32 bits) em DB retentivo, com tratamento de rollover (o gateway compõe 32 bits a partir de pares 16‑bit via `telegraf/processors/32bit_join.star`).
- Marque as áreas de memória (DBs) como retentivas para não perder contagem após quedas de energia.
- Mantenha um heartbeat (bit ou contador) para diagnóstico de resets/reinicializações do PLC.
- Garanta que o MB_SERVER esteja ativo e que os endereços estejam alinhados com `TIA_TagTable_MVP.csv` (coils 1..3; holdings 1,2,10..13). Ajuste byte order se seu mapeamento diferir.
- Para a bobina RUN, faça filtragem/anti‑ruído se necessário, garantindo estabilidade do estado operando/parado que alimenta o cálculo de Disponibilidade (A%).

## Notas de implementação (alterações aplicadas)
- Compose: `stops` movido para dentro de `services`; `mosquitto` em perfil `mqtt`.
- Override: portas locais adicionadas (3001 e 8087) e correções de indentação YAML.
- Telegraf: entrada Modbus reescrita para Telegraf 1.30; `name = "modbus"`; `byte_order` e `scale` definidos; processador Starlark reescrito.
- Python: `pymodbus` instalado no ambiente local; o container `stops` instala `pymodbus==3.6.5` automaticamente na inicialização.

## Referências
- Telegraf Modbus Input (v1.30): https://github.com/influxdata/telegraf/tree/release-1.30/plugins/inputs/modbus
