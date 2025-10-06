def apply(metric):
  pairs = [("GoodCount", "GoodCount_lo", "GoodCount_hi"),
           ("ScrapCount", "ScrapCount_lo", "ScrapCount_hi")]
  for name, lo_key, hi_key in pairs:
    lo = metric.fields.get(lo_key)
    hi = metric.fields.get(hi_key)
    if lo != None and hi != None:
      metric.fields[name] = (int(hi) << 16) + int(lo)
      metric.fields.pop(lo_key, None)
      metric.fields.pop(hi_key, None)
  return metric
