import csv, datetime as dt, os

WEEK = {'Mon':0,'Tue':1,'Wed':2,'Thu':3,'Fri':4,'Sat':5,'Sun':6}

def _parse_hhmm(s):
    h, m = s.split(":")
    return int(h), int(m)

def _load_windows(csv_path):
    windows = []
    if not os.path.exists(csv_path):
        return windows
    with open(csv_path, newline="", encoding="utf-8") as f:
        r = csv.DictReader((row for row in f if not row.strip().startswith("#")))
        for row in r:
            wday = WEEK[row["weekday"]]
            sh, sm = _parse_hhmm(row["start"])
            eh, em = _parse_hhmm(row["end"])
            windows.append((row["SITE"], row["LINHA"], row["MAQUINA"], wday, (sh,sm), (eh,em), row.get("reason","planned")))
    return windows

class Planner:
    def __init__(self, csv_path="services/stops/planned_windows.csv"):
        self.csv_path = csv_path
        self.windows = _load_windows(csv_path)
        self._last_mtime = os.path.getmtime(csv_path) if os.path.exists(csv_path) else 0

    def reload_if_changed(self):
        try:
            m = os.path.getmtime(self.csv_path)
            if m != self._last_mtime:
                self.windows = _load_windows(self.csv_path)
                self._last_mtime = m
        except FileNotFoundError:
            self.windows = []

    def is_planned(self, now: dt.datetime, site: str, line: str, machine: str):
        self.reload_if_changed()
        wd = now.weekday()
        hh, mm = now.hour, now.minute
        for s,l,m,wday,(sh,sm),(eh,em),reason in self.windows:
            if s==site and l==line and m==machine and wd==wday:
                if (hh,mm) >= (sh,sm) and (hh,mm) <= (eh,em):
                    return True, reason
        return False, ""
