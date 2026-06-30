# Brazil / Europe ANS Performance Dashboard

Interactive Shiny dashboard comparing Air Navigation System performance between
Brazil (DECEA) and Europe (EUROCONTROL) — 2019–2025.

## Quick Start

```r
# 1. Install dependencies (first time only)
source("setup.R")

# 2. Launch dashboard
shiny::runApp()
```

## Structure

```
Dashboard_BRA_EUR/
├── app.R               # Main Shiny application
├── setup.R             # Package installer
├── data/
│   ├── airports.csv           # 24 study airports (12 BRA + 12 EUR)
│   ├── traffic_volume.csv     # Annual controlled flights 2019–2025
│   ├── punctuality.csv        # Arrival & departure punctuality by airport
│   ├── capacity_throughput.csv # Declared capacity + peak arrival throughput
│   └── taxi_asma.csv          # Additional taxi-out, taxi-in, ASMA times
└── www/                # Static assets (logos, CSS)
```

## Dashboard Tabs

| Tab | Content |
|-----|---------|
| **Overview** | KPI cards + traffic trend + KPA summary |
| **Traffic** | Annual volume, 2025 share, data table |
| **Punctuality** | Stacked bar by airport, % within ±15 min |
| **Capacity & Throughput** | Declared capacity, peak arrival throughput evolution |
| **Taxi & ASMA** | Additional taxi-out/in and ASMA trends per airport |
| **Airport Comparison** | Side-by-side compare any BRA vs EUR airport |
| **Data** | Raw data tables for all datasets |

## Study Airports

**Brazil (12):** SBBR, SBCF, SBCT, SBEG, SBGL, SBGR, SBKP, SBPA, SBRF, SBRJ, SBSP, SBSV

**Europe (12):** EDDF, EDDM, EGKK, EGLL, EHAM, LEBL, LEMD, LFPG, LGAV, LPPT, LSZH, LTFM

## Updating Data

Replace or update the CSV files in `data/` with real data from DECEA/EUROCONTROL.
Column names must match the existing schema. The app reads files on launch.

## Dependencies

- R ≥ 4.1
- shiny, bslib, dplyr, tidyr, ggplot2, scales, DT
