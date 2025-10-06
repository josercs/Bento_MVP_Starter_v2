# v1.1 — OEE & Hardening (como aplicar)

1) Overlay de saúde:
- Use junto com docker-compose.yml e docker-compose.override.yml:

```powershell
cd mvp_shadow_gateway
docker compose -f docker-compose.yml -f docker-compose.override.yml -f overlays/docker-compose.healthchecks.yml up -d
```

2) Setup automatizado (gera .env, buckets e task):
- Windows (PowerShell):
```powershell
./mvp_shadow_gateway/scripts/setup.ps1
```
- Linux/macOS:
```bash
./mvp_shadow_gateway/scripts/setup.sh
```

3) Paradas planejadas:
- Preencha `services/stops/planned_windows.csv`.
- No `services/stops/stops.py` importe e use:
```python
from planned_utils import Planner
planner = Planner()
planned, reason = planner.is_planned(datetime.datetime.now(), site, line, machine)
```

4) Grafana:
- Use `grafana/queries/oee_flux_examples.md` para montar A, P, Q e OEE.
