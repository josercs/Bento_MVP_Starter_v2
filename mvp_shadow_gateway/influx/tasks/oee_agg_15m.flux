option task = {name: "oee_agg_15m", every: 15m}

raw = from(bucket: "mvp_raw")
  |> range(start: -task.every)
  |> filter(fn: (r) => r._measurement == "modbus")
  |> filter(fn: (r) => exists r.SITE and exists r.LINHA and exists r.MAQUINA)

good = raw |> filter(fn:(r)=> r._field == "GoodCount") |> derivative(unit: 1s, nonNegative: true)
scrap = raw |> filter(fn:(r)=> r._field == "ScrapCount") |> derivative(unit: 1s, nonNegative: true)

good15 = good |> aggregateWindow(every: 15m, fn: sum, createEmpty: false)
scrap15 = scrap |> aggregateWindow(every: 15m, fn: sum, createEmpty: false)

join1 = join(tables: {g: good15, s: scrap15}, on: ["_time","SITE","LINHA","MAQUINA"], method: "inner")
  |> map(fn:(r)=> ({ r with _value: if exists r._value_g and exists r._value_s then (r._value_g + r._value_s) else 0.0, _field: "Total"}))

run = raw |> filter(fn:(r)=> r._field == "RUN") |> aggregateWindow(every: 15m, fn: mean, createEmpty: false)
A = run |> map(fn:(r)=> ({ r with _field: "A_pct", _value: r._value * 100.0 }))

Q = join(tables: {g: good15, t: join1}, on: ["_time","SITE","LINHA","MAQUINA"]) |> map(fn:(r)=> ({ r with _field: "Q_pct", _value: if r._value_t > 0.0 then (r._value_g / r._value_t) * 100.0 else 0.0 }))

ideal = 1.0
P = good15 |> map(fn:(r)=> ({ r with _field: "P_pct", _value: if ideal > 0.0 then (r._value * 1.0 / (900.0 / ideal)) * 100.0 else 0.0 }))

// normalize measurement name for downstream dashboards
A2 = A |> map(fn:(r)=> ({ r with _measurement: "machine" }))
Q2 = Q |> map(fn:(r)=> ({ r with _measurement: "machine" }))
P2 = P |> map(fn:(r)=> ({ r with _measurement: "machine" }))

union(tables: [A2, Q2, P2]) |> to(bucket: "mvp_agg")
