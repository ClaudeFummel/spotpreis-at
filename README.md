# ⚡ Spotpreis Österreich (PWA)

EPEX Day‑Ahead Strompreise für Österreich im **15‑Minuten‑Raster** – als installierbare Web‑App fürs iPhone.

- Aktueller Preis, Min / Ø / Max, Ampel‑Diagramm, Liste aller Viertelstunden
- Umschaltbar 15 min / 1 h (Stundenwert = echter Mittelwert der 4 Viertelstunden)
- inkl. 20 % MwSt oder netto, eigener Anbieter‑Aufschlag (ct/kWh)
- „Günstigstes Fenster“ (1–4 h) für Akku / Wallbox / Waschmaschine
- 7 Tage Rückblick + morgen (ab ca. 13:00 veröffentlicht)

## Wie es funktioniert

Eine GitHub Action (`.github/workflows/pages.yml`) läuft stündlich um :20, holt die Preise von
[energy-charts.info](https://energy-charts.info) (Fraunhofer ISE, CC BY 4.0, Bundesnetzagentur | SMARD.de)
und veröffentlicht sie zusammen mit der App als statische Seite auf GitHub Pages. Kein eigener Server nötig.

## Installation am iPhone

1. `https://claudefummel.github.io/spotpreis-at/` in **Safari** öffnen
2. Teilen‑Symbol → **Zum Home‑Bildschirm**

## Lokal testen

```powershell
python scripts/fetch_prices.py prices.json
python -m http.server 8766
```

> Hinweis: GitHub deaktiviert zeitgesteuerte Workflows in öffentlichen Repos nach 60 Tagen ohne Repo‑Aktivität
> und schickt vorher eine E‑Mail. Dann im Tab *Actions* einmal auf „Enable workflow“ klicken.
