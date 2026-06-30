################## SETUP ######################################################
# Quarto renders each chapter in a separate session.
# To save loading the same libraries in every chapter, we define defaults here.
# This script/definitions are sourced() at the beginning of every chapter.
###############################################################################

# load required libraries =====================================================
library(tidyverse)
library(lubridate)
library(ggrepel)
library(patchwork)
library(ggforce)
#-------- supporting packages
library(flextable)
library(zoo)
library(magrittr)
library(purrr)
library(glue)
library(pdftools)
library(devtools)
library(arrow)
library(rnaturalearth)
library(ggplot2)
library(treemapify)
library(ggbump)
#-------- dashboard packages
library(plotly)
library(DT)
library(crosstalk)

# ============== DEFAULTS and DEFINITIONS =====================================
this_year <- 2025
max_date  <- lubridate::ymd("2025-12-31")

# ggplot2 default theme
ggplot2::theme_set(theme_minimal())

# ============== FLEXTABLE ====================================================
flextable::set_flextable_defaults(
  fonts_ignore = TRUE,
  font.size    = 10,
  font.family  = "Helvetica"
)
ft_border <- flextable::fp_border_default(width = 0.5)

# ============== COLOURS ======================================================
bra_eur_colours <- c(BRA = "#52854C", EUR = "#4E84C4")
bra_col         <- getElement(bra_eur_colours, "BRA")
eur_col         <- getElement(bra_eur_colours, "EUR")

YEAR_COLORS <- c("2023" = "#E74C3C",
                 "2024" = "#2ECC71",
                 "2025" = "#5DADE2")

bra_eur_theme_minimal <- theme_minimal() + theme(axis.title = element_text(size = 9))
bra_eur_theme_bw      <- theme_bw()      + theme(axis.title = element_text(size = 9))

# punctuality band colours (5-band PBWG standard)
PUNCT_COLS <- c(
  "Early > 15 min" = "#2166ac",
  "Early 5–15 min" = "#92c5de",
  "Within ± 5 min" = "#4dac26",
  "Late 5–15 min"  = "#f4a582",
  "Late > 15 min"  = "#d6604d"
)

# ============== STUDY AIRPORTS ===============================================
bra_apts <- c("SBGR","SBGL","SBRJ","SBCF","SBBR","SBSV",
              "SBKP","SBSP","SBCT","SBPA","SBRF","SBEG")
eur_apts <- c("EGLL","EGKK","EHAM","EDDF","EDDM","LSZH",
              "LFPG","LEMD","LEBL","LPPT","LGAV","LTFM")

bra_apts_names <- tibble::tribble(
  ~ICAO,   ~NAME,
  "SBGR",  "Guarulhos",
  "SBGL",  "Galeão",
  "SBRJ",  "Santos Dumont",
  "SBCF",  "Belo Horizonte",
  "SBBR",  "Brasília",
  "SBSV",  "Salvador",
  "SBKP",  "Campinas",
  "SBSP",  "Congonhas",
  "SBCT",  "Curitiba",
  "SBPA",  "Porto Alegre",
  "SBRF",  "Recife",
  "SBEG",  "Eduardo Gomes"
)

eur_apts_names <- tibble::tribble(
  ~ICAO,   ~NAME,
  "EGLL",  "Heathrow",
  "EGKK",  "Gatwick",
  "EHAM",  "Amsterdam",
  "EDDF",  "Frankfurt",
  "EDDM",  "Munich",
  "LSZH",  "Zurich",
  "LIRF",  "Rome",
  "LFPG",  "Paris",
  "LEMD",  "Madrid",
  "LEBL",  "Barcelona",
  "LPPT",  "Lisbon",
  "LGAV",  "Athens",
  "LTFM",  "Istanbul"
)

# combined airport reference table (used by dashboard)
airports <- bind_rows(
  bra_apts_names |> mutate(region = "Brazil"),
  eur_apts_names |> filter(ICAO %in% eur_apts) |> mutate(region = "Europe")
) |>
  rename(icao = ICAO, name = NAME)

# ============== HIGH-LEVEL SYSTEM TABLE ======================================
table_bra_eur <- tibble::tribble(
  ~KPA,                                           ~Brazil_2019, ~Brazil_2020, ~Brazil_2021, ~Brazil_2022, ~Brazil_2023, ~Brazil_2024, ~Brazil_2025, ~Europe_2023, ~Europe_2024, ~Europe_2025,
  "geographic area (non-oceanic million km²)¹",   "8.5",  "8.5",  "8.5",  "8.5",  "8.5",  "8.5",  "8.5",  "10.9",   "10.9",   "10.9",
  "number of en-route ANSPs²",                    "1",    "1",    "1",    "1",    "1",    "1",    "1",    "37",     "37",     "37",
  "number of TWR¹",                               "59 TWR","60 TWR","57+1 DTWR","57+1 DTWR","57+1 DTWR","57+1 DTWR","59+1 DTWR","374","373","n/a",
  "number of APP¹",                               "43",   "43",   "42",   "42",   "41",   "41",   "42",   "268",    "266",    "n/a",
  "number of ACC¹",                               "5",    "5",    "5",    "1",    "5",    "5",    "5",    "57",     "57",     "57",
  "number of ATCOs in OPS¹",                      "3606", "3376", "3549", "3754", "3677", "3890", "3893", "16973",  "17186",  "n/a",
  "controlled flights³",                          "1594442","1018181","1286224","1677760","1801109","1995139","2109588","10144258","10633991","11046028",
  "flights ATCO",                                 "362",  "302",  "362",  "447",  "490",  "497",  "542",  "598",    "619",    "n/a",
  "traffic density (non-oceanic flights/km²)",    "0.22", "0.13", "0.12", "0.16", "0.18", "0.19", "0.21", "0.93",   "0.976",  "n/a"
)

# ============== PUNCTUALITY HELPERS ==========================================
EARLY_GT15 <- c("(-INF,-60]","(-60,-55]","(-55,-50]","(-50,-45]","(-45,-40]",
                "(-40,-35]","(-35,-30]","(-30,-25]","(-25,-20]","(-20,-15]")
EARLY_5_15 <- c("(-15,-10]","(-10,-5]")
WITHIN5    <- c("(-5,0]","(0,5)")
LATE_5_15  <- c("[5,10)","[10,15)")
LATE_GT15  <- c("[15,20)","[20,25)","[25,30)","[30,35)","[35,40)",
                "[40,45)","[45,50)","[50,55)","[55,60)","[60,INF)")

agg_bands <- function(df) {
  df |>
    mutate(
      early_gt15 = rowSums(across(all_of(EARLY_GT15)), na.rm = TRUE),
      early_5_15 = rowSums(across(all_of(EARLY_5_15)), na.rm = TRUE),
      within5    = rowSums(across(all_of(WITHIN5)),    na.rm = TRUE),
      late_5_15  = rowSums(across(all_of(LATE_5_15)),  na.rm = TRUE),
      late_gt15  = rowSums(across(all_of(LATE_GT15)),  na.rm = TRUE)
    ) |>
    select(ICAO, DATE, PHASE, N_VALID,
           early_gt15, early_5_15, within5, late_5_15, late_gt15)
}

to_pct <- function(df) {
  df |>
    mutate(tot = early_gt15 + early_5_15 + within5 + late_5_15 + late_gt15) |>
    mutate(across(c(early_gt15, early_5_15, within5, late_5_15, late_gt15),
                  ~ round(100 * .x / tot, 1))) |>
    select(-tot)
}

read_punct <- function(path, region, yr = NA) {
  read.csv(path, check.names = FALSE) |>
    agg_bands() |>
    mutate(region = region, DATE = as.Date(DATE),
           year   = if (is.na(yr)) year(DATE) else as.integer(yr))
}

pivot_bands_long <- function(df) {
  df |>
    pivot_longer(c(early_gt15, early_5_15, within5, late_5_15, late_gt15),
                 names_to = "band", values_to = "pct") |>
    mutate(band = factor(band,
      levels = c("early_gt15","early_5_15","within5","late_5_15","late_gt15"),
      labels = names(PUNCT_COLS)))
}

# ============== DATA LOADING =================================================

# -- Punctuality --------------------------------------------------------------
punc_raw <- bind_rows(
  read_punct("data/PBWG-BRA-punc-2025.csv",           "Brazil", 2025),
  read_punct("data/PBWG-EUR-punc-2025.csv",            "Europe", 2025),
  read_punct("data/PBWG-EUR-PUNC-2024.csv",            "Europe", 2024),
  read_punct("data/PBWG-EUR-LGAV-punc-2024.csv",       "Europe", 2024),
  read_punct("data/PBWG-EUR-PUNC-2023.csv",            "Europe", 2023),
  read_punct("data/PBWG-EUR-PUNC-LPPT-2019-2024.csv",  "Europe")
) |>
  filter(ICAO %in% c(bra_apts, eur_apts))

punc_annual <- punc_raw |>
  group_by(ICAO, region, year, PHASE) |>
  summarise(across(c(early_gt15, early_5_15, within5, late_5_15, late_gt15),
                   sum, na.rm = TRUE), .groups = "drop") |>
  to_pct() |>
  mutate(within15 = early_5_15 + within5 + late_5_15) |>
  left_join(airports[, c("icao","name")], by = c("ICAO" = "icao")) |>
  mutate(label = paste0(ICAO, " – ", name))

# -- Traffic ------------------------------------------------------------------
traffic_daily <- bind_rows(
  read.csv("data/PBWG-BRA-network-traffic-2023-2025.csv"),
  read.csv("data/PBWG-EUR-network-traffic-2023-2025.csv")
) |>
  mutate(DATE = as.Date(DATE), year = year(DATE)) |>
  arrange(REG, DATE) |>
  group_by(REG) |>
  mutate(roll7 = rollmean(FLTS, 7, fill = NA, align = "right")) |>
  ungroup()

traffic_annual <- traffic_daily |>
  group_by(REG, year) |>
  summarise(total = sum(FLTS, na.rm = TRUE), .groups = "drop") |>
  mutate(region  = recode(REG, BRA = "Brazil", EUR = "Europe"),
         total_M = round(total / 1e6, 2))

# -- Capacity / BLI / PLI -----------------------------------------------------
bli_pli <- read.csv("data/PBWG-BRA-EUR-bli-pli-2019-2025.csv") |>
  left_join(airports[, c("icao","name","region")], by = c("ICAO" = "icao")) |>
  mutate(label = paste0(ICAO, " – ", name))

# -- Taxi / surface times -----------------------------------------------------
read_txxt <- function(path, region, yr) {
  read.csv(path) |> mutate(region = region, year = yr, DATE = as.Date(DATE))
}

txxt_annual <- bind_rows(
  read_txxt("data/PBWG-BRA-txxt-analytic-2023-ref2024-icao_ganp_p20.csv","Brazil",2023),
  read_txxt("data/PBWG-BRA-txxt-analytic-2024-ref2024-icao_ganp_p20.csv","Brazil",2024),
  read_txxt("data/PBWG-BRA-txxt-analytic-2025-ref2024-icao_ganp_p20.csv","Brazil",2025),
  read_txxt("data/PBWG-EUR-txxt-analytic-2023-ref2024-icao_ganp_p20.csv","Europe",2023),
  read_txxt("data/PBWG-EUR-txxt-analytic-2024-ref2024-icao_ganp_p20.csv","Europe",2024),
  read_txxt("data/PBWG-EUR-txxt-analytic-2025-ref2024-icao_ganp_p20.csv","Europe",2025)
) |>
  filter(ICAO %in% c(bra_apts, eur_apts)) |>
  group_by(ICAO, region, year, PHASE) |>
  summarise(avg_add = sum(TOT_ADD_TIME, na.rm = TRUE) /
                      sum(MVTS_VALID,   na.rm = TRUE),
            .groups = "drop") |>
  left_join(airports[, c("icao","name")], by = c("ICAO" = "icao")) |>
  mutate(label = paste0(ICAO, " – ", name))

# -- ASMA (Europe) ------------------------------------------------------------
asma_annual <- read.csv("data/PBWG-EUR-asma40-monthly-2023-2025-public.csv") |>
  mutate(DATE = as.Date(DATE), year = year(DATE)) |>
  filter(ICAO %in% eur_apts) |>
  group_by(ICAO, year) |>
  summarise(avg_add_asma = sum(TOT_ADD_TIME, na.rm = TRUE) /
                           sum(MVTS_VALID,   na.rm = TRUE),
            .groups = "drop") |>
  mutate(region = "Europe") |>
  left_join(airports[, c("icao","name")], by = c("ICAO" = "icao")) |>
  mutate(label = paste0(ICAO, " – ", name))

# -- Flows --------------------------------------------------------------------
flow_rank <- read.csv("data/PBWG-BRA-EUR-study-flow-rank-2023-2025.csv")

world_reg <- read.csv("data/PBWG-BRA-EUR-world-region-departures-2025.csv") |>
  filter(ADES_WORLD_REGION != "Unmapped") |>
  mutate(region = recode(REG, BRA = "Brazil", EUR = "Europe"),
         pct    = round(SHARE * 100, 1))

daio <- read.csv("data/PBWG-BRA-EUR-daio-share-2025.csv") |>
  mutate(
    region = recode(REG, BRA = "Brazil", EUR = "Europe"),
    type   = recode(DAIO,
      I = "Domestic/Regional", D = "Departures",
      A = "Arrivals",          O = "Overflights"),
    pct = round(SHARE * 100, 1)
  )

# -- Throughput ---------------------------------------------------------------
throughput <- read.csv("data/PBWG-BRA-EUR-ordered-throughput-LPPT-SBGR-2019-2025.csv")
