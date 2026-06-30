# Brazil / Europe ANS Performance Dashboard

Interactive R Shiny dashboard for comparing Air Navigation System operational
performance between Brazil (DECEA) and Europe (EUROCONTROL), covering the period
2019 to 2025.

---

## Quick Start

```r
# 1. Install required packages (first time only)
source("setup.R")

# 2. Launch the dashboard
shiny::runApp()
```

**Required packages:** `shiny`, `bslib`, `dplyr`, `tidyr`, `ggplot2`,
`lubridate`, `scales`, `DT`, `zoo`

---

## Project Structure

```
Dashboard_BRA_EUR/
├── app.R                  # Main Shiny application
├── setup.R                # Package installer
├── dashboard_guide.qmd    # Dashboard guide (Quarto)
├── README.md              # This file
└── data/
    ├── PBWG-BRA-network-traffic-2023-2025.csv
    ├── PBWG-EUR-network-traffic-2023-2025.csv
    ├── PBWG-BRA-punc-2025.csv
    ├── PBWG-EUR-punc-2025.csv
    ├── PBWG-EUR-PUNC-2023.csv
    ├── PBWG-EUR-PUNC-2024.csv
    ├── PBWG-EUR-PUNC-LPPT-2019-2024.csv
    ├── PBWG-EUR-LGAV-punc-2024.csv
    ├── PBWG-BRA-EUR-bli-pli-2019-2025.csv
    ├── PBWG-BRA-txxt-analytic-2023-ref2024-icao_ganp_p20.csv
    ├── PBWG-BRA-txxt-analytic-2024-ref2024-icao_ganp_p20.csv
    ├── PBWG-BRA-txxt-analytic-2025-ref2024-icao_ganp_p20.csv
    ├── PBWG-EUR-txxt-analytic-2023-ref2024-icao_ganp_p20.csv
    ├── PBWG-EUR-txxt-analytic-2024-ref2024-icao_ganp_p20.csv
    ├── PBWG-EUR-txxt-analytic-2025-ref2024-icao_ganp_p20.csv
    ├── PBWG-EUR-asma40-monthly-2023-2025-public.csv
    ├── PBWG-BRA-EUR-ordered-throughput-LPPT-SBGR-2019-2025.csv
    ├── PBWG-BRA-EUR-study-flow-rank-2023-2025.csv
    ├── PBWG-BRA-EUR-study-flow-pairs-2023-2025.csv
    ├── PBWG-BRA-EUR-world-region-departures-2025.csv
    ├── PBWG-BRA-EUR-daio-share-2025.csv
    ├── PBWG-BRA-EUR-airport-departure-rank-2025.csv
    ├── PBWG-BRA-EUR-network-flow-pairs-2025.csv
    └── PBWG-BRA-EUR-country-departures-2025.csv
```

---

## Dashboard Tabs and Data Sources

### 1. Overview
High-level summary with KPI cards, daily traffic chart, and flight type distribution.

| Element | Data file |
|---------|-----------|
| KPI – total flights BRA and EUR | `PBWG-BRA-network-traffic-2023-2025.csv` / `PBWG-EUR-network-traffic-2023-2025.csv` |
| Chart – 7-day rolling average | Same files above (field `FLTS`) |
| Chart – DAIO distribution (Domestic/Arrival/International/Overflight) | `PBWG-BRA-EUR-daio-share-2025.csv` |

---

### 2. Traffic
Daily traffic volume evolution and annual totals, with filters by region and flight segment.

| Element | Data file |
|---------|-----------|
| Daily traffic (total, domestic, arrivals, departures, overflights) | `PBWG-BRA-network-traffic-2023-2025.csv` / `PBWG-EUR-network-traffic-2023-2025.csv` |
| Annual totals table | Aggregated from the same files |

**Relevant columns:** `DATE`, `FLTS` (total), `D` (departures), `A` (arrivals),
`I` (intra-regional), `O` (overflights).

---

### 3. Punctuality
Punctuality distribution for arrivals and departures at each study airport,
broken into five time bands: Early > 15 min, Early 5–15 min, Within ± 5 min,
Late 5–15 min, Late > 15 min.

| Element | Data file |
|---------|-----------|
| BRA punctuality 2025 (ARR + DEP) | `PBWG-BRA-punc-2025.csv` |
| EUR punctuality 2025 | `PBWG-EUR-punc-2025.csv` |
| EUR punctuality 2024 | `PBWG-EUR-PUNC-2024.csv` + `PBWG-EUR-LGAV-punc-2024.csv` |
| EUR punctuality 2023 | `PBWG-EUR-PUNC-2023.csv` |
| LPPT historical 2019–2024 | `PBWG-EUR-PUNC-LPPT-2019-2024.csv` |

**File format:** each row is an airport × date × phase (ARR/DEP), with flight
counts per minute bucket from `(-INF,-60]` to `[60,INF)`. The app aggregates
these buckets into the five standard PBWG bands.

---

### 4. Capacity
Declared peak capacity and utilisation indices (BLI and PLI) per airport
for the period 2019–2025.

| Element | Data file |
|---------|-----------|
| Maximum declared capacity (`MAX_CAP`) | `PBWG-BRA-EUR-bli-pli-2019-2025.csv` |
| Busy-Level Index (`BLI`) – share of hours above 20% of capacity | Same file |
| Peak-Level Index (`PLI`) – share of hours above 80% of capacity | Same file |

**Relevant columns:** `ICAO`, `YEAR`, `MAX_CAP`, `BLI`, `PLI`, `REG`.

---

### 5. Taxi & ASMA
Additional surface times (taxi-out and taxi-in) and arrival sequencing time (ASMA),
calculated as the deviation from the unimpeded reference time.

| Element | Data file |
|---------|-----------|
| Additional taxi-out BRA (2023–2025) | `PBWG-BRA-txxt-analytic-2023/2024/2025-ref2024-icao_ganp_p20.csv` – DEP phase |
| Additional taxi-in BRA (2023–2025) | Same file set – ARR phase |
| Additional taxi-out/in EUR (2023–2025) | `PBWG-EUR-txxt-analytic-2023/2024/2025-ref2024-icao_ganp_p20.csv` |
| Additional ASMA EUR (monthly, 2023–2025) | `PBWG-EUR-asma40-monthly-2023-2025-public.csv` |

**Relevant columns:** `ICAO`, `PHASE` (ARR/DEP), `DATE`, `MVTS_VALID`,
`TOT_ADD_TIME`. Average additional time per flight = `TOT_ADD_TIME / MVTS_VALID`.

> **Note:** ASMA data for Brazil is not available in this version.

---

### 6. BRA-EUR Flows
Inter-regional connections between Brazil and Europe, route pair rankings,
and traffic distribution by world region.

| Element | Data file |
|---------|-----------|
| Route pair rankings (study airports, 2023–2025) | `PBWG-BRA-EUR-study-flow-rank-2023-2025.csv` |
| International departures by world region 2025 | `PBWG-BRA-EUR-world-region-departures-2025.csv` |

---

### 7. Airport Comparison
Direct side-by-side comparison between one Brazilian and one European airport:
punctuality distribution and ordered throughput curve.

| Element | Data file |
|---------|-----------|
| Punctuality by airport | Same files as the Punctuality tab |
| Ordered throughput curve (SBGR and LPPT, 2019–2025) | `PBWG-BRA-EUR-ordered-throughput-LPPT-SBGR-2019-2025.csv` |

> **Note:** the ordered throughput curve is currently available only for
> SBGR (Guarulhos) and LPPT (Lisbon).

---

### 8. Data
Raw data tables for all loaded datasets, available for inspection and export
directly in the browser.

---

## Study Airports

**Brazil (12):**
SBBR · SBCF · SBCT · SBEG · SBGL · SBGR · SBKP · SBPA · SBRF · SBRJ · SBSP · SBSV

**Europe (12):**
EDDF · EDDM · EGKK · EGLL · EHAM · LEBL · LEMD · LFPG · LGAV · LPPT · LSZH · LTFM

---

## Publishing the Dashboard Online

The dashboard is designed to be published on **[shinyapps.io](https://www.shinyapps.io)**,
RStudio's hosting platform for Shiny apps. A free account supports up to 5 apps
and 25 active hours per month — sufficient for internal use and presentations.

### One-time setup

**1. Create a free account** at <https://www.shinyapps.io>

**2. Install the deployment package** (if not already installed):

```r
install.packages("rsconnect")
```

**3. Get your credentials** — in the shinyapps.io dashboard go to:
`Account → Tokens → Add Token → Show → Copy to Clipboard`

**4. Fill in `deploy.R`** with your account name, token and secret:

```r
# deploy.R — edit these three lines
rsconnect::setAccountInfo(
  name   = "your-account-name",
  token  = "your-token",
  secret = "your-secret"
)
```

### Deploy

```r
source("deploy.R")
```

The console will print the public URL and open the browser automatically:

```
https://your-account-name.shinyapps.io/Dashboard_BRA_EUR
```

### Notes

- **`deploy.R` is safe to commit** — credentials are only stored locally by
  `rsconnect` after `setAccountInfo()` is called. The `rsconnect/` folder
  (which contains tokens) is listed in `.gitignore` and will never be pushed.
- To **update** the live app after changing data or code, just run
  `source("deploy.R")` again.
- The total size of `data/` files is large (~800 MB). shinyapps.io accepts
  up to 1 GB per app, but upload time will be a few minutes on the first
  deploy. Future versions will pre-process data to `.rds` format to reduce
  this significantly.

---

## Updating the Data

The files in `data/` were extracted from the joint DECEA–EUROCONTROL report
*"Comparison of Operational Air Navigation System Performance: Brazil / Europe,
2019–2025"*.

In a future iteration, dedicated R scripts will be added to this repository to
**automatically regenerate** each CSV from the original data sources (DECEA and
PRU/EUROCONTROL databases), keeping the dashboard up to date without manual
intervention.

---

## Source

> DECEA / EUROCONTROL Performance Review Unit — *Comparison of Operational
> Air Navigation System Performance: Brazil / Europe, 2019–2025*.
> Performance Benchmarking Working Group (PBWG).
