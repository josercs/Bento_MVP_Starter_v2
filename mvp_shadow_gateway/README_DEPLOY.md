# MVP Shadow Gateway — Deploy & Plano de Ação (30–60 dias)

## Objetivo
Implantar um MVP **não-intrusivo** para captar S1 (peças), S2 (refugo), RUN e 1–2 analógicos, expondo via **Modbus/TCP** no S7-1200 e visualizando **Qualidade, RUN, Corrente/Vibração** no Grafana. Baseado no relatório de dores da Serra Gaúcha (custos de parada, OEE baixo, falta de visibilidade).

## Entregáveis (sem mexer no CLP do cliente)
1. **Gateway Sombra (S7-1200)** com MB_SERVER e `FB200_MVP` (contagem + escalas + mapeamento Modbus).
2. **Stack PaaS local**: Telegraf (Modbus→Influx), InfluxDB 2, Grafana com dashboard inicial OEE Starter.
3. **Relatório mensal (PDF)**: contagem, taxa de qualidade, tempo em RUN (% proxy de disponibilidade), top paradas (se habilitar detecção).

## Cronograma Sugerido
- **Semana 1** — bancada + checklist NR-10/12 + DNS/IP fixos + teste Modbus.
- **Semana 2** — instalação em máquina piloto (setor moveleiro ou metalmecânico), validação de sinais.
- **Semanas 3–4 (30 dias)** — coleta estável + dashboard + ajuste de escalas/limiares (corrente RUN).
- **Semanas 5–8 (60 dias)** — ativar "paradas" (threshold RUN=0 > 2 min), consolidar relatório com recomendações (top N paradas, quick wins).

## Critérios de Sucesso (aceitação piloto)
- ≥ **95%** de integridade de dados (sem buracos > 5 min).
- **Qualidade** calculada (good/(good+scrap)) e **RUN** time-series consistentes.
- **3 recomendações** de melhoria com base nos dados (ex.: setup/limpeza, sensoriamento, manutenção).
- ROI estimado com **redução de refugo** ou **ganho de disponibilidade** ≥ 1–3%.

## Como subir o stack
1. Edite `.env` (ou use defaults):
   ```env
   MB_HOST=192.168.1.121
   MB_UNIT=1
   INFLUX_USER=admin
   INFLUX_PASS=admin123
   INFLUX_ORG=retrofit4
   INFLUX_BUCKET=mvp
   INFLUX_TOKEN=admintoken
   GRAFANA_USER=admin
   GRAFANA_PASS=admin
   ```
2. Rode:
   ```bash
   docker compose up -d
   ```
3. Acesse **InfluxDB**: `http://localhost:8086` (org `retrofit4`, bucket `mvp`) e **Grafana**: `http://localhost:3000` (admin/admin).

## Ajustes por setor (moveleiro x metalmecânico)
- **Moveleiro**: S1 no fotoelétrico da saída da seccionadora/coladeira; S2 na rejeição; RUN via torre verde ou corrente do motor principal. Ciclos curtos → amostragem 500 ms ok.
- **Metalmecânico**: S1 no fim-de-curso/célula de peça; S2 no descarte; RUN pelo contator do spindle/prensa. Vibração para preditiva leve (0–10 V).

## Próximos passos (fase 2)
- Detecção de paradas: RUN=0 por >120 s → evento (csv/Influx).
- Cálculo **Disponibilidade/Performance/OEE** (precisa de tempo planejado e ciclo nominal).
- Integração com **MQTT** e API de ordens (ERP/MES) para performance real (peças/h).

## Observações NR-10/12
- Sempre via **isolação galvânica** (DI/AI/splitter). Não compartilhar 0V.
- Documentar bornes ("Shadow") e listar pontos em As-Built.

## Detecção de Paradas (incluída)
- Serviço **stops** lê o **RUN** do Modbus e grava eventos `measurement=events, type=stop` no Influx se RUN=0 por >= `STOP_THRESHOLD` (padrão 120 s).
- Dashboard **"MVP — Paradas"** importado automaticamente (pasta dashboards/).

### Ajustes
- Defina `STOP_THRESHOLD` no `.env` (ex.: 180 para 3 min).
- Use RUN com histerese confiável (defina a lógica de RUN no PLC).

