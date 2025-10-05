# SECURITY_CHECKLIST (Edge/MVP)

## Rede e Acesso
- Compose *override* fixa binds em 127.0.0.1 para Grafana/Influx/MQTT (somente host local).
- Mantenha a rede do CLP isolada (VLAN/bridge dedicada). Apenas o Edge-PC enxerga porta 502.
- Bloqueie firewall externo; exponha 3000/8086/1883 apenas via túnel VPN quando necessário.

## Contas e Senhas
- Altere `INFLUX_PASS`, `INFLUX_TOKEN`, `GRAFANA_PASS` no `.env` antes do deploy.
- Crie usuário Grafana não-admin para clientes.

## Sistema/Tempo
- Sincronize NTP no host (chrony/systemd-timesyncd). Não rode NTP em containers.
- Timezone do host = timezone do cliente.

## Containers
- `telegraf` e `stops` com `read_only` + `no-new-privileges` (override já aplicado).
- Limite de recursos (opcional): `cpus`, `mem_limit` no compose.
- Atualize imagens periodicamente (`docker compose pull`).

## Dados
- **Retention** do bucket `mvp` = 30d (ajuste conforme contrato).
- Executar `scripts/backup_influx.sh` semanalmente (cron).
- Armazenar backups fora do Edge-PC (NAS/S3).

## NR-10/12
- Somente leitura via isolação galvânica (DI/AI; splitter/clamp).
- As-Built dos bornes “Shadow” e ART do comissionamento.
