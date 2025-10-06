# OEE — consultas Flux (exemplos v1.1)

## A — Disponibilidade (% em 15m)

from(bucket: "mvp_agg")
  |> range(start: -24h)
  |> filter(fn:(r)=> r._measurement == "machine")
  |> filter(fn:(r)=> r._field == "A_pct")

## Q — Qualidade (% em 15m)

from(bucket: "mvp_agg")
  |> range(start: -24h)
  |> filter(fn:(r)=> r._measurement == "machine")
  |> filter(fn:(r)=> r._field == "Q_pct")

## P — Performance (% em 15m)

from(bucket: "mvp_agg")
  |> range(start: -24h)
  |> filter(fn:(r)=> r._measurement == "machine")
  |> filter(fn:(r)=> r._field == "P_pct")

## OEE — cálculo no painel (Transform)

Crie três queries (A_pct, Q_pct, P_pct) e, em Transform → Add field from calculation, defina:

OEE_pct = A_pct * Q_pct * P_pct / 10000
