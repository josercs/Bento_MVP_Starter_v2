# Minimal Modbus TCP reader for S7-1200 MVP
# pip install pymodbus==3.6.5
from pymodbus.client import ModbusTcpClient
import time, csv, os

MB_HOST = os.getenv("MB_HOST", "192.168.1.121")
MB_PORT = int(os.getenv("MB_PORT", "502"))
MB_UNIT = int(os.getenv("MB_UNIT", "1"))
CSV_PATH = os.getenv("CSV_PATH", "mvp_data.csv")

client = ModbusTcpClient(MB_HOST, port=MB_PORT)
assert client.connect(), f"Could not connect to {MB_HOST}:{MB_PORT}"

# Prepare CSV
header = ["ts","coil1_S1","coil2_S2","coil3_RUN","hr40001_Current_x10","hr40002_Vibration_x10","GoodCount","ScrapCount"]
if not os.path.exists(CSV_PATH):
    with open(CSV_PATH, "w", newline="", encoding="utf-8") as f:
        csv.writer(f).writerow(header)

def read_dint_from_words(lo, hi):
    return (hi << 16) | lo

try:
    while True:
        now = time.time()

        coils = client.read_coils(0, 8, unit=MB_UNIT)
        hrs   = client.read_holding_registers(0, 32, unit=MB_UNIT)

        if coils.isError() or hrs.isError():
            print("Modbus read error")
            time.sleep(1.0)
            continue

        c = coils.bits + [False]*8
        h = hrs.registers + [0]*32

        good = read_dint_from_words(h[9],  h[10])   # 40010..40011
        scrap= read_dint_from_words(h[11], h[12])   # 40012..40013

        row = [now, int(c[0]), int(c[1]), int(c[2]), h[0], h[1], good, scrap]

        with open(CSV_PATH, "a", newline="", encoding="utf-8") as f:
            csv.writer(f).writerow(row)

        print(f"t={now:.0f} S1={c[0]} S2={c[1]} RUN={c[2]} I_x10={h[0]} V_x10={h[1]} Good={good} Scrap={scrap}")
        time.sleep(0.5)

except KeyboardInterrupt:
    pass
finally:
    client.close()
