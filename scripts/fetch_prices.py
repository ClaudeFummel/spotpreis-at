"""Holt 15-min EPEX Day-Ahead Preise (AT) von energy-charts.info und schreibt prices.json."""
import json, sys, urllib.request
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

out = sys.argv[1] if len(sys.argv) > 1 else "prices.json"
today = datetime.now(ZoneInfo("Europe/Vienna")).date()
start, end = today - timedelta(days=6), today + timedelta(days=1)
url = f"https://api.energy-charts.info/price?bzn=AT&start={start}&end={end}"

req = urllib.request.Request(url, headers={"User-Agent": "spotpreis-at-pwa"})
with urllib.request.urlopen(req, timeout=30) as r:
    raw = json.load(r)

prices = [{"t": t, "p": p} for t, p in zip(raw["unix_seconds"], raw["price"]) if p is not None]
if len(prices) < 90:
    sys.exit(f"Zu wenige Datenpunkte ({len(prices)}) - breche ab")

with open(out, "w", encoding="utf-8") as f:
    json.dump({
        "updated": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "unit": raw.get("unit"),
        "license": raw.get("license_info"),
        "prices": prices,
    }, f, separators=(",", ":"))
print(f"{len(prices)} Preise geschrieben ({start} .. {end})")
