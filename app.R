library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)
library(scales)
library(DT)

# ── Study airports ─────────────────────────────────────────────────────────────
airports <- tribble(
  ~icao, ~name,                              ~city,            ~region,
  "SBBR","Brasília Int'l",                   "Brasília",       "Brazil",
  "SBCF","Confins",                          "Belo Horizonte", "Brazil",
  "SBCT","Afonso Pena",                      "Curitiba",       "Brazil",
  "SBEG","Eduardo Gomes",                    "Manaus",         "Brazil",
  "SBGL","Galeão",                           "Rio de Janeiro", "Brazil",
  "SBGR","Guarulhos",                        "São Paulo",      "Brazil",
  "SBKP","Viracopos",                        "Campinas",       "Brazil",
  "SBPA","Salgado Filho",                    "Porto Alegre",   "Brazil",
  "SBRF","Guararapes",                       "Recife",         "Brazil",
  "SBRJ","Santos Dumont",                    "Rio de Janeiro", "Brazil",
  "SBSP","Congonhas",                        "São Paulo",      "Brazil",
  "SBSV","Dep. Luís Eduardo Magalhães",      "Salvador",       "Brazil",
  "EDDF","Frankfurt",                        "Frankfurt",      "Europe",
  "EDDM","Munich",                           "Munich",         "Europe",
  "EGKK","Gatwick",                          "London",         "Europe",
  "EGLL","Heathrow",                         "London",         "Europe",
  "EHAM","Schiphol",                         "Amsterdam",      "Europe",
  "LEBL","El Prat",                          "Barcelona",      "Europe",
  "LEMD","Barajas",                          "Madrid",         "Europe",
  "LFPG","Charles de Gaulle",               "Paris",          "Europe",
  "LGAV","Eleftherios Venizelos",            "Athens",         "Europe",
  "LPPT","Humberto Delgado",                 "Lisbon",         "Europe",
  "LSZH","Kloten",                           "Zurich",         "Europe",
  "LTFM","Istanbul Airport",                 "Istanbul",       "Europe"
)
STUDY_BRA <- airports$icao[airports$region == "Brazil"]
STUDY_EUR <- airports$icao[airports$region == "Europe"]

ap_label <- function(icao_vec) {
  df <- airports[airports$icao %in% icao_vec, ]
  setNames(df$icao, paste0(df$icao, " – ", df$name, " (", df$city, ")"))
}

# ── Colours ────────────────────────────────────────────────────────────────────
COL_BRA <- "#009C3B"
COL_EUR <- "#003399"
PUNCT_COLS <- c(
  "Early > 15 min"  = "#2166ac",
  "Early 5–15 min"  = "#92c5de",
  "Within ± 5 min"  = "#4dac26",
  "Late 5–15 min"   = "#f4a582",
  "Late > 15 min"   = "#d6604d"
)
BAND_LEVELS <- names(PUNCT_COLS)

# ── Punctuality minute-bucket helpers ─────────────────────────────────────────
EARLY_GT15_COLS <- c(
  "(-INF,-60]","(-60,-55]","(-55,-50]","(-50,-45]","(-45,-40]","(-40,-35]",
  "(-35,-30]","(-30,-25]","(-25,-20]","(-20,-15]"
)
EARLY_5_15_COLS <- c("(-15,-10]","(-10,-5]")
WITHIN5_COLS    <- c("(-5,0]","(0,5)")
LATE_5_15_COLS  <- c("[5,10)","[10,15)")
LATE_GT15_COLS  <- c("[15,20)","[20,25)","[25,30)","[30,35)","[35,40)",
                     "[40,45)","[45,50)","[50,55)","[55,60)","[60,INF)")

aggregate_punct_bands <- function(df) {
  df |>
    mutate(
      early_gt15 = rowSums(across(all_of(EARLY_GT15_COLS)), na.rm = TRUE),
      early_5_15 = rowSums(across(all_of(EARLY_5_15_COLS)), na.rm = TRUE),
      within5    = rowSums(across(all_of(WITHIN5_COLS)),    na.rm = TRUE),
      late_5_15  = rowSums(across(all_of(LATE_5_15_COLS)),  na.rm = TRUE),
      late_gt15  = rowSums(across(all_of(LATE_GT15_COLS)),  na.rm = TRUE)
    ) |>
    select(ICAO, DATE, PHASE, N_VALID,
           early_gt15, early_5_15, within5, late_5_15, late_gt15)
}

bands_to_pct <- function(df) {
  df |>
    mutate(total = early_gt15 + early_5_15 + within5 + late_5_15 + late_gt15) |>
    mutate(across(c(early_gt15, early_5_15, within5, late_5_15, late_gt15),
                  ~ round(100 * .x / total, 1))) |>
    select(-total)
}

pivot_bands_long <- function(df) {
  df |>
    pivot_longer(c(early_gt15, early_5_15, within5, late_5_15, late_gt15),
                 names_to = "band", values_to = "pct") |>
    mutate(band = factor(band,
      levels = c("early_gt15","early_5_15","within5","late_5_15","late_gt15"),
      labels = BAND_LEVELS))
}

# ── Load & pre-process punctuality ────────────────────────────────────────────
read_punct <- function(path, region, year) {
  read.csv(path, check.names = FALSE) |>
    aggregate_punct_bands() |>
    mutate(region = region, year = year, DATE = as.Date(DATE))
}

punc_raw <- bind_rows(
  read_punct("data/PBWG-BRA-punc-2025.csv",        "Brazil", 2025),
  read_punct("data/PBWG-EUR-punc-2025.csv",         "Europe", 2025),
  read_punct("data/PBWG-EUR-PUNC-2024.csv",         "Europe", 2024),
  read_punct("data/PBWG-EUR-PUNC-2023.csv",         "Europe", 2023),
  read_punct("data/PBWG-EUR-LGAV-punc-2024.csv",    "Europe", 2024),
  read_punct("data/PBWG-EUR-PUNC-LPPT-2019-2024.csv","Europe", NA)
)

# Fix year for LPPT historical file (year comes from DATE column)
punc_raw <- punc_raw |>
  mutate(year = ifelse(is.na(year), year(DATE), year))

# Keep only study airports
punc_study <- punc_raw |>
  filter(ICAO %in% c(STUDY_BRA, STUDY_EUR)) |>
  left_join(airports[, c("icao","region")], by = c("ICAO" = "icao")) |>
  mutate(region = coalesce(region.y, region.x)) |>
  select(-region.x, -region.y)

# Annual summary per airport
punc_annual <- punc_study |>
  group_by(ICAO, region, year, PHASE) |>
  summarise(across(c(early_gt15, early_5_15, within5, late_5_15, late_gt15),
                   sum, na.rm = TRUE), .groups = "drop") |>
  bands_to_pct()

# ── Load traffic data ──────────────────────────────────────────────────────────
read_traffic <- function(path) {
  read.csv(path) |> mutate(DATE = as.Date(DATE))
}
traffic_daily <- bind_rows(
  read_traffic("data/PBWG-BRA-network-traffic-2023-2025.csv"),
  read_traffic("data/PBWG-EUR-network-traffic-2023-2025.csv")
) |>
  mutate(year = year(DATE), month = floor_date(DATE, "month"))

# Annual totals
traffic_annual <- traffic_daily |>
  group_by(REG, year) |>
  summarise(total_flights = sum(FLTS, na.rm = TRUE), .groups = "drop")

# ── Load BLI/PLI (capacity) ───────────────────────────────────────────────────
bli_pli <- read.csv("data/PBWG-BRA-EUR-bli-pli-2019-2025.csv") |>
  left_join(airports[, c("icao","name","city","region")],
            by = c("ICAO" = "icao"))

# ── Load taxi/surface times ────────────────────────────────────────────────────
read_txxt <- function(path, region, year) {
  read.csv(path) |>
    mutate(region = region, year = year, DATE = as.Date(DATE))
}

txxt_raw <- bind_rows(
  read_txxt("data/PBWG-BRA-txxt-analytic-2023-ref2024-icao_ganp_p20.csv","Brazil",2023),
  read_txxt("data/PBWG-BRA-txxt-analytic-2024-ref2024-icao_ganp_p20.csv","Brazil",2024),
  read_txxt("data/PBWG-BRA-txxt-analytic-2025-ref2024-icao_ganp_p20.csv","Brazil",2025),
  read_txxt("data/PBWG-EUR-txxt-analytic-2023-ref2024-icao_ganp_p20.csv","Europe",2023),
  read_txxt("data/PBWG-EUR-txxt-analytic-2024-ref2024-icao_ganp_p20.csv","Europe",2024),
  read_txxt("data/PBWG-EUR-txxt-analytic-2025-ref2024-icao_ganp_p20.csv","Europe",2025)
) |>
  filter(ICAO %in% c(STUDY_BRA, STUDY_EUR))

txxt_annual <- txxt_raw |>
  group_by(ICAO, region, year, PHASE) |>
  summarise(
    total_add = sum(TOT_ADD_TIME, na.rm = TRUE),
    total_mvts = sum(MVTS_VALID, na.rm = TRUE),
    avg_add_min = total_add / total_mvts,
    .groups = "drop"
  )

# ── Load ASMA (Europe) ────────────────────────────────────────────────────────
asma_eur <- read.csv("data/PBWG-EUR-asma40-monthly-2023-2025-public.csv") |>
  mutate(DATE = as.Date(DATE), year = year(DATE)) |>
  filter(ICAO %in% STUDY_EUR)

asma_annual <- asma_eur |>
  group_by(ICAO, year) |>
  summarise(avg_add_asma = sum(TOT_ADD_TIME, na.rm = TRUE) /
                           sum(MVTS_VALID, na.rm = TRUE),
            .groups = "drop") |>
  mutate(region = "Europe")

# ── Load flow pairs ───────────────────────────────────────────────────────────
flow_rank <- read.csv("data/PBWG-BRA-EUR-study-flow-rank-2023-2025.csv")
flow_pairs <- read.csv("data/PBWG-BRA-EUR-study-flow-pairs-2023-2025.csv")
daio       <- read.csv("data/PBWG-BRA-EUR-daio-share-2025.csv")
world_reg  <- read.csv("data/PBWG-BRA-EUR-world-region-departures-2025.csv")

# ── Throughput (LPPT & SBGR only, 2019–2025) ─────────────────────────────────
throughput <- read.csv("data/PBWG-BRA-EUR-ordered-throughput-LPPT-SBGR-2019-2025.csv") |>
  mutate(BIN = as.POSIXct(BIN, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))

# ── Theme ──────────────────────────────────────────────────────────────────────
dash_theme <- bs_theme(
  version      = 5,
  bg           = "#f8f9fa",
  fg           = "#212529",
  primary      = "#003399",
  secondary    = "#009C3B",
  base_font    = font_google("Inter"),
  heading_font = font_google("Inter", wght = "600")
)

plot_theme <- theme_minimal(base_size = 12) +
  theme(
    plot.background  = element_rect(fill = "white", colour = NA),
    panel.grid.minor = element_blank(),
    legend.position  = "bottom"
  )

ap_lbl <- function(icao) {
  r <- airports[airports$icao == icao, ]
  paste0(icao, " – ", r$name, " (", r$city, ")")
}

# ══════════════════════════════════════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════════════════════════════════════
ui <- page_navbar(
  title        = "Brazil / Europe ANS Performance Dashboard",
  theme        = dash_theme,
  window_title = "BRA-EUR Dashboard",
  bg           = "#003399",
  fillable     = TRUE,

  # ── Overview ──────────────────────────────────────────────────────────────
  nav_panel("Overview", icon = icon("chart-line"),

    layout_columns(col_widths = c(4, 4, 4),
      value_box("Brazil 2025 Flights",
        value    = textOutput("ov_bra_flts", inline = TRUE),
        showcase = icon("plane-departure"), theme = "success",
        p("controlled flights")),
      value_box("Europe 2025 Flights",
        value    = textOutput("ov_eur_flts", inline = TRUE),
        showcase = icon("globe"), theme = "primary",
        p("controlled flights")),
      value_box("Study Airports",
        value = "24", showcase = icon("map-marker-alt"), theme = "secondary",
        p("12 Brazil + 12 Europe"))
    ),
    br(),
    layout_columns(col_widths = c(7, 5),
      card(card_header("Daily Traffic – 7-day Rolling Average (2023–2025)"),
           plotOutput("ov_daily", height = "340px")),
      card(card_header("2025 Flight Distribution by Type"),
           plotOutput("ov_daio",  height = "340px"))
    )
  ),

  # ── Traffic ───────────────────────────────────────────────────────────────
  nav_panel("Traffic", icon = icon("plane"),

    layout_sidebar(
      sidebar = sidebar(title = "Filters",
        checkboxGroupInput("tr_reg", "Region",
          choices = c("BRA","EUR"), selected = c("BRA","EUR")),
        selectInput("tr_seg", "Flight segment",
          choices = c("Total" = "FLTS", "Domestic/Regional" = "I",
                      "Departures" = "D", "Arrivals" = "A", "Overflights" = "O"),
          selected = "FLTS")
      ),
      card(card_header("Daily Traffic Volume"), plotOutput("tr_daily", height = "360px")),
      br(),
      card(card_header("Annual Totals"), DTOutput("tr_annual_tbl"))
    )
  ),

  # ── Punctuality ───────────────────────────────────────────────────────────
  nav_panel("Punctuality", icon = icon("clock"),

    layout_sidebar(
      sidebar = sidebar(title = "Filters",
        radioButtons("pt_phase","Flight phase",
          choices = c("Arrival" = "ARR","Departure" = "DEP"), selected = "ARR"),
        selectInput("pt_year","Year",
          choices = sort(unique(punc_annual$year), decreasing = TRUE)),
        radioButtons("pt_reg","Region",
          choices = c("Both","Brazil","Europe"), selected = "Both"),
        hr(),
        p(class = "text-muted small",
          "Bands: Early/Late relative to scheduled time. Within ± 5 min = on-time.")
      ),

      card(card_header("Punctuality Distribution by Airport (stacked %)"),
           plotOutput("pt_stacked", height = "500px")),
      br(),
      layout_columns(col_widths = c(6,6),
        card(card_header("% Within ± 15 min – Brazil"),
             plotOutput("pt_15_bra", height = "320px")),
        card(card_header("% Within ± 15 min – Europe"),
             plotOutput("pt_15_eur", height = "320px"))
      )
    )
  ),

  # ── Capacity ──────────────────────────────────────────────────────────────
  nav_panel("Capacity", icon = icon("tachometer-alt"),

    layout_sidebar(
      sidebar = sidebar(title = "Filters",
        selectInput("cap_reg","Region",
          choices = c("Both","Brazil","Europe"), selected = "Both"),
        sliderInput("cap_yr","Year range", min = 2019, max = 2025,
                    value = c(2019,2025), sep = "")
      ),
      card(card_header("Declared Peak Capacity (MAX_CAP) per Airport"),
           plotOutput("cap_max", height = "400px")),
      br(),
      layout_columns(col_widths = c(6,6),
        card(card_header("Busy-Level Index (BLI) – share of hours above 20% capacity"),
             plotOutput("cap_bli", height = "320px")),
        card(card_header("Peak-Level Index (PLI) – share of hours above 80% capacity"),
             plotOutput("cap_pli", height = "320px"))
      )
    )
  ),

  # ── Taxi & ASMA ───────────────────────────────────────────────────────────
  nav_panel("Taxi & ASMA", icon = icon("road"),

    layout_sidebar(
      sidebar = sidebar(title = "Filters",
        radioButtons("tx_phase","Surface phase",
          choices = c("Taxi-Out (DEP)" = "DEP","Taxi-In (ARR)" = "ARR"),
          selected = "DEP"),
        selectInput("tx_reg","Region",
          choices = c("Both","Brazil","Europe"), selected = "Both")
      ),
      card(card_header("Average Additional Taxi Time per Flight (min) – 2023–2025"),
           plotOutput("tx_trend", height = "480px")),
      br(),
      card(card_header("Average Additional ASMA Time per Flight (min) – Europe, 2023–2025"),
           plotOutput("tx_asma", height = "300px"))
    )
  ),

  # ── Flow Pairs ────────────────────────────────────────────────────────────
  nav_panel("BRA-EUR Flows", icon = icon("exchange-alt"),

    layout_columns(col_widths = c(6,6),
      card(card_header("Top BRA–EUR Route Pairs – Rank Evolution 2023–2025"),
           plotOutput("fl_rank", height = "440px")),
      card(card_header("International Connections – World Region Share 2025"),
           plotOutput("fl_world", height = "440px"))
    )
  ),

  # ── Airport Comparison ────────────────────────────────────────────────────
  nav_panel("Airport Comparison", icon = icon("code-compare"),

    layout_sidebar(
      sidebar = sidebar(title = "Select airports",
        selectInput("cmp_bra","Brazil airport",
          choices = ap_label(STUDY_BRA), selected = "SBGR"),
        selectInput("cmp_eur","Europe airport",
          choices = ap_label(STUDY_EUR), selected = "LPPT"),
        radioButtons("cmp_phase","Phase",
          choices = c("Arrival" = "ARR","Departure" = "DEP"), selected = "ARR"),
        selectInput("cmp_yr","Year",
          choices = sort(unique(punc_annual$year), decreasing = TRUE))
      ),

      layout_columns(col_widths = c(6,6),
        card(card_header(textOutput("cmp_hdr_bra")),
             plotOutput("cmp_pt_bra", height = "280px")),
        card(card_header(textOutput("cmp_hdr_eur")),
             plotOutput("cmp_pt_eur", height = "280px"))
      ),
      br(),
      card(card_header("Throughput – Ordered Arrivals per Hour (SBGR & LPPT, 2019–2025)"),
           plotOutput("cmp_thru", height = "340px"))
    )
  ),

  # ── Raw Data ──────────────────────────────────────────────────────────────
  nav_panel("Data", icon = icon("table"),
    navset_card_underline(
      nav_panel("Airports",       DTOutput("dt_apt")),
      nav_panel("Traffic daily",  DTOutput("dt_trf")),
      nav_panel("Punctuality",    DTOutput("dt_punc")),
      nav_panel("BLI / PLI",      DTOutput("dt_bli")),
      nav_panel("Taxi / ASMA",    DTOutput("dt_tx")),
      nav_panel("Flow pairs",     DTOutput("dt_fl"))
    )
  )
)

# ══════════════════════════════════════════════════════════════════════════════
# Server
# ══════════════════════════════════════════════════════════════════════════════
server <- function(input, output, session) {

  # ── Overview ────────────────────────────────────────────────────────────────
  output$ov_bra_flts <- renderText({
    v <- traffic_annual |> filter(REG == "BRA", year == 2025) |> pull(total_flights)
    if (length(v)) paste0(round(v/1e6, 2), " M") else "—"
  })
  output$ov_eur_flts <- renderText({
    v <- traffic_annual |> filter(REG == "EUR", year == 2025) |> pull(total_flights)
    if (length(v)) paste0(round(v/1e6, 1), " M") else "—"
  })

  output$ov_daily <- renderPlot({
    d <- traffic_daily |>
      arrange(REG, DATE) |>
      group_by(REG) |>
      mutate(roll7 = zoo::rollmean(FLTS, 7, fill = NA, align = "right")) |>
      ungroup()
    ggplot(d, aes(DATE, roll7, colour = REG, group = REG)) +
      geom_line(linewidth = 0.8, na.rm = TRUE) +
      scale_colour_manual(values = c(BRA = COL_BRA, EUR = COL_EUR),
                          labels = c(BRA = "Brazil", EUR = "Europe")) +
      scale_y_continuous(labels = comma) +
      labs(x = NULL, y = "Daily flights (7-day avg)", colour = NULL) +
      plot_theme
  })

  output$ov_daio <- renderPlot({
    d <- daio |>
      mutate(label = recode(DAIO,
        I = "Domestic/Reg.", D = "Departures", A = "Arrivals", O = "Overflights"),
        REG = recode(REG, BRA = "Brazil", EUR = "Europe"))
    ggplot(d, aes(REG, SHARE * 100, fill = label)) +
      geom_col() +
      scale_fill_brewer(palette = "Set2") +
      labs(x = NULL, y = "%", fill = NULL) +
      plot_theme
  })

  # ── Traffic ─────────────────────────────────────────────────────────────────
  tr_d <- reactive({
    traffic_daily |> filter(REG %in% input$tr_reg)
  })

  output$tr_daily <- renderPlot({
    col <- input$tr_seg
    d <- tr_d() |> arrange(REG, DATE) |> group_by(REG) |>
      mutate(roll7 = zoo::rollmean(.data[[col]], 7, fill = NA, align = "right")) |>
      ungroup()
    ggplot(d, aes(DATE, roll7, colour = REG)) +
      geom_line(linewidth = 0.9, na.rm = TRUE) +
      scale_colour_manual(values = c(BRA = COL_BRA, EUR = COL_EUR),
                          labels = c(BRA = "Brazil", EUR = "Europe")) +
      scale_y_continuous(labels = comma) +
      labs(x = NULL, y = "Flights (7-day avg)", colour = NULL) +
      plot_theme
  })

  output$tr_annual_tbl <- renderDT({
    traffic_annual |>
      mutate(total_flights = comma(total_flights)) |>
      datatable(options = list(pageLength = 10), rownames = FALSE)
  })

  # ── Punctuality ─────────────────────────────────────────────────────────────
  pt_filt <- reactive({
    d <- punc_annual |>
      filter(PHASE == input$pt_phase, year == as.integer(input$pt_year))
    if (input$pt_reg != "Both") d <- d |> filter(region == input$pt_reg)
    d |>
      left_join(airports[, c("icao","city")], by = c("ICAO" = "icao")) |>
      mutate(label = paste0(ICAO, "\n", city)) |>
      pivot_bands_long()
  })

  output$pt_stacked <- renderPlot({
    d <- pt_filt()
    ggplot(d, aes(label, pct, fill = band)) +
      geom_col(position = "stack") +
      facet_wrap(~ region, scales = "free_x") +
      scale_fill_manual(values = PUNCT_COLS) +
      labs(x = NULL, y = "%", fill = NULL) +
      plot_theme +
      theme(axis.text.x = element_text(size = 8))
  })

  pct15_plot <- function(rgn, col) {
    punc_annual |>
      filter(PHASE == input$pt_phase,
             year  == as.integer(input$pt_year),
             region == rgn) |>
      mutate(within15 = early_5_15 + within5 + late_5_15) |>
      left_join(airports[, c("icao","city")], by = c("ICAO" = "icao")) |>
      mutate(label = paste0(ICAO, " (", city, ")")) |>
      ggplot(aes(reorder(label, within15), within15)) +
      geom_col(fill = col) +
      geom_text(aes(label = paste0(within15, "%")), hjust = -0.1, size = 3.5) +
      coord_flip() +
      scale_y_continuous(limits = c(0, 105)) +
      labs(x = NULL, y = "% within ±15 min") +
      plot_theme
  }

  output$pt_15_bra <- renderPlot({ pct15_plot("Brazil", COL_BRA) })
  output$pt_15_eur <- renderPlot({ pct15_plot("Europe", COL_EUR) })

  # ── Capacity ─────────────────────────────────────────────────────────────────
  cap_filt <- reactive({
    d <- bli_pli |> filter(YEAR >= input$cap_yr[1], YEAR <= input$cap_yr[2])
    if (input$cap_reg != "Both") d <- d |> filter(REG == substr(input$cap_reg,1,3))
    d
  })

  output$cap_max <- renderPlot({
    d <- cap_filt() |>
      filter(YEAR == max(YEAR)) |>
      mutate(label = paste0(ICAO, " – ", city))
    ggplot(d, aes(reorder(label, MAX_CAP), MAX_CAP, fill = REG)) +
      geom_col() +
      geom_text(aes(label = MAX_CAP), hjust = -0.1, size = 3.2) +
      coord_flip() +
      scale_fill_manual(values = c(BRA = COL_BRA, EUR = COL_EUR),
                        labels = c(BRA="Brazil", EUR="Europe")) +
      scale_y_continuous(limits = c(0, 140)) +
      labs(x = NULL, y = "Flights/hour", fill = NULL) +
      plot_theme
  })

  output$cap_bli <- renderPlot({
    d <- cap_filt() |>
      mutate(label = paste0(ICAO, "\n", city))
    ggplot(d, aes(YEAR, BLI, colour = REG, group = label)) +
      geom_line(alpha = 0.7) + geom_point(size = 1.5) +
      scale_colour_manual(values = c(BRA = COL_BRA, EUR = COL_EUR),
                          labels = c(BRA="Brazil", EUR="Europe")) +
      facet_wrap(~ REG) +
      labs(x = NULL, y = "BLI", colour = NULL) +
      plot_theme + theme(legend.position = "none")
  })

  output$cap_pli <- renderPlot({
    d <- cap_filt() |>
      mutate(label = paste0(ICAO, "\n", city))
    ggplot(d, aes(YEAR, PLI, colour = REG, group = label)) +
      geom_line(alpha = 0.7) + geom_point(size = 1.5) +
      scale_colour_manual(values = c(BRA = COL_BRA, EUR = COL_EUR),
                          labels = c(BRA="Brazil", EUR="Europe")) +
      facet_wrap(~ REG) +
      labs(x = NULL, y = "PLI", colour = NULL) +
      plot_theme + theme(legend.position = "none")
  })

  # ── Taxi & ASMA ─────────────────────────────────────────────────────────────
  tx_filt <- reactive({
    d <- txxt_annual |> filter(PHASE == input$tx_phase)
    if (input$tx_reg != "Both") d <- d |> filter(region == input$tx_reg)
    d |> left_join(airports[, c("icao","city")], by = c("ICAO" = "icao")) |>
      mutate(label = paste0(ICAO, "\n(", city, ")"))
  })

  output$tx_trend <- renderPlot({
    d <- tx_filt()
    ggplot(d, aes(year, avg_add_min, colour = region, group = ICAO)) +
      geom_line(linewidth = 1) + geom_point(size = 2) +
      facet_wrap(~ label, ncol = 4) +
      scale_colour_manual(values = c(Brazil = COL_BRA, Europe = COL_EUR)) +
      scale_x_continuous(breaks = c(2023,2024,2025)) +
      labs(x = NULL, y = "Avg additional time (min)", colour = NULL) +
      plot_theme +
      theme(strip.text = element_text(size = 7), axis.text = element_text(size = 7))
  })

  output$tx_asma <- renderPlot({
    d <- asma_annual |>
      left_join(airports[, c("icao","city")], by = c("ICAO" = "icao")) |>
      mutate(label = paste0(ICAO, "\n(", city, ")"))
    ggplot(d, aes(year, avg_add_asma, fill = ICAO)) +
      geom_col(position = "dodge") +
      scale_x_continuous(breaks = c(2023,2024,2025)) +
      labs(x = NULL, y = "Avg additional ASMA (min)", fill = NULL) +
      plot_theme
  })

  # ── BRA-EUR Flows ────────────────────────────────────────────────────────────
  output$fl_rank <- renderPlot({
    d <- flow_rank |>
      filter(PAIR_CLASS == "Study-Study") |>
      mutate(PAIR = reorder(PAIR, -RANK))
    ggplot(d, aes(factor(YEAR), RANK, group = PAIR, colour = PAIR)) +
      geom_line(linewidth = 1) +
      geom_point(size = 3) +
      geom_text(aes(label = PAIR), hjust = -0.05, size = 2.8,
                data = d |> filter(YEAR == max(YEAR))) +
      scale_y_reverse() +
      labs(x = NULL, y = "Rank (1 = busiest)", colour = NULL) +
      plot_theme + theme(legend.position = "none")
  })

  output$fl_world <- renderPlot({
    d <- world_reg |>
      filter(ADES_WORLD_REGION != "Unmapped") |>
      mutate(REG = recode(REG, BRA = "Brazil", EUR = "Europe"))
    ggplot(d, aes(reorder(ADES_WORLD_REGION, SHARE), SHARE * 100, fill = REG)) +
      geom_col(position = "dodge") +
      scale_fill_manual(values = c(Brazil = COL_BRA, Europe = COL_EUR)) +
      coord_flip() +
      labs(x = NULL, y = "Share of external departures (%)", fill = NULL) +
      plot_theme
  })

  # ── Airport Comparison ───────────────────────────────────────────────────────
  output$cmp_hdr_bra <- renderText(ap_lbl(input$cmp_bra))
  output$cmp_hdr_eur <- renderText(ap_lbl(input$cmp_eur))

  cmp_punct_plot <- function(icao_sel, col) {
    d <- punc_annual |>
      filter(ICAO == icao_sel, PHASE == input$cmp_phase,
             year == as.integer(input$cmp_yr)) |>
      pivot_bands_long()
    ggplot(d, aes(factor(year), pct, fill = band)) +
      geom_col() +
      scale_fill_manual(values = PUNCT_COLS) +
      labs(x = NULL, y = "%", fill = NULL) +
      plot_theme
  }

  output$cmp_pt_bra <- renderPlot({ cmp_punct_plot(input$cmp_bra, COL_BRA) })
  output$cmp_pt_eur <- renderPlot({ cmp_punct_plot(input$cmp_eur, COL_EUR) })

  output$cmp_thru <- renderPlot({
    d <- throughput |>
      filter(ICAO %in% c("SBGR","LPPT")) |>
      mutate(region = ifelse(ICAO == "SBGR", "Brazil (SBGR)", "Europe (LPPT)"))
    ggplot(d, aes(RANK, TOT_THRU, colour = factor(YEAR), group = interaction(ICAO, YEAR))) +
      geom_line(alpha = 0.8, linewidth = 0.7) +
      facet_wrap(~ region) +
      scale_colour_viridis_d(option = "D") +
      labs(x = "Rank (busiest hours)", y = "Total throughput (flights/h)",
           colour = "Year") +
      plot_theme
  })

  # ── Data tables ──────────────────────────────────────────────────────────────
  dt_opt <- list(scrollX = TRUE, pageLength = 10)
  output$dt_apt  <- renderDT({ datatable(airports,      options = dt_opt, rownames = FALSE) })
  output$dt_trf  <- renderDT({ datatable(traffic_daily, options = dt_opt, rownames = FALSE) })
  output$dt_punc <- renderDT({ datatable(punc_annual,   options = dt_opt, rownames = FALSE) })
  output$dt_bli  <- renderDT({ datatable(bli_pli,       options = dt_opt, rownames = FALSE) })
  output$dt_tx   <- renderDT({ datatable(txxt_annual,   options = dt_opt, rownames = FALSE) })
  output$dt_fl   <- renderDT({ datatable(flow_rank,     options = dt_opt, rownames = FALSE) })
}

shinyApp(ui, server)
