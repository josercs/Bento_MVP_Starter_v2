import os, time, datetime, urllib.request, json
from planned_utils import Planner
from pymodbus.client import ModbusTcpClient

MB_HOST   = os.getenv("MB_HOST", "192.168.1.121")
MB_PORT   = int(os.getenv("MB_PORT", "502"))
MB_UNIT   = int(os.getenv("MB_UNIT", "1"))
STOP_SECS = int(os.getenv("STOP_THRESHOLD", "120"))

INFLUX_URL   = os.getenv("INFLUX_URL", "http://influxdb:8086")
INFLUX_ORG   = os.getenv("INFLUX_ORG", "retrofit4")
INFLUX_BUCKET= os.getenv("INFLUX_BUCKET", "mvp")
INFLUX_TOKEN = os.getenv("INFLUX_TOKEN", "admintoken")

# Context tags
SITE   = os.getenv("SITE", "Bento")
LINHA  = os.getenv("LINHA", "Seccionadora01")
MAQUINA= os.getenv("MAQUINA", "Maquina01")

planner = Planner()

def influx_write(line):
    url = f"{INFLUX_URL}/api/v2/write?org={INFLUX_ORG}&bucket={INFLUX_BUCKET}&precision=s"
    req = urllib.request.Request(url, data=line.encode("utf-8"), method="POST")
    req.add_header("Authorization", f"Token {INFLUX_TOKEN}")
    req.add_header("Content-Type", "text/plain; charset=utf-8")
    with urllib.request.urlopen(req, timeout=5) as resp:
        resp.read()

def now_s():
    return int(time.time())

client = ModbusTcpClient(MB_HOST, port=MB_PORT)
assert client.connect(), f"Cannot connect to {MB_HOST}:{MB_PORT}"

last_run = 1
t_zero = None
print(f"[stops] monitoring RUN coil on {MB_HOST} unit {MB_UNIT}, threshold={STOP_SECS}s")
try:
    while True:
        rr = client.read_coils(2, 1, unit=MB_UNIT)  # address 3 (zero-based index=2)
        if rr.isError():
            time.sleep(1.0)
            continue
        run = 1 if rr.bits and rr.bits[0] else 0
        t = now_s()

        if run == 0 and last_run == 1:
            # transition to stop
            t_zero = t
        elif run == 1 and last_run == 0 and t_zero is not None:
            # back to run: if lasted long enough, record event
            dur = t - t_zero
            if dur >= STOP_SECS:
                now_dt = datetime.datetime.utcfromtimestamp(t)
                planned, reason = planner.is_planned(now_dt, SITE, LINHA, MAQUINA)
                tags = f"type=stop,SITE={SITE},LINHA={LINHA},MAQUINA={MAQUINA},planned={'true' if planned else 'false'}"
                fields = f"duration_s={dur}"
                if reason:
                    # quote reason in line protocol
                    reason_s = reason.replace('"','\"')
                    fields += f",reason=\"{reason_s}\""
                line = f"events,{tags} {fields} {t}"
                try:
                    influx_write(line)
                    print(f"[stops] stop event: duration={dur}s planned={planned} @ {t}")
                except Exception as e:
                    print("[stops] influx write error:", e)
            t_zero = None

        last_run = run
        time.sleep(1.0)
except KeyboardInterrupt:
    pass
finally:
    client.close()
