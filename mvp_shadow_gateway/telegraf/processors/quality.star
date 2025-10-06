def apply(metric):
  good = metric.fields.get("GoodCount")
  scrap = metric.fields.get("ScrapCount")
  if good is not None and scrap is not None:
    total = int(good) + int(scrap)
    metric.fields["TotalCount"] = total
    if total > 0:
      metric.fields["Quality_pct"] = 100.0 * (int(good) / total)
  return metric
