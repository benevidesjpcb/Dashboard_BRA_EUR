library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)
library(DT)

# ── Data loading ──────────────────────────────────────────────────────────────
airports      <- read.csv("data/airports.csv", stringsAsFactors = FALSE)
traffic_vol   <- read.csv("data/traffic_volume.csv", stringsAsFactors = FALSE)
punctuality   <- read.csv("data/punctuality.csv", stringsAsFactors = FALSE)
cap_thr       <- read.csv("data/capacity_throughput.csv", stringsAsFactors = FALSE)
taxi_asma     <- read.csv("data/taxi_asma.csv", stringsAsFactors = FALSE)

# ── Colour palette ────────────────────────────────────────────────────────────
COL_BRA  <- "#009C3B"   # green (Brazil)
COL_EUR  <- "#003399"   # blue  (Europe)
PUNCT_COLS <- c(
  "Early (>15 min)"  = "#2166ac",
  "Early (5–15 min)" = "#92c5de",
  "Within ±5 min"    = "#4dac26",
  "Late (5–15 min)"  = "#f4a582",
  "Late (>15 min)"   = "#d6604d"
)

# ── Helper: clean airport label ───────────────────────────────────────────────
ap_label <- function(icao_vec) {
  df <- airports[airports$icao %in% icao_vec, c("icao", "name", "city")]
  lbl <- paste0(df$icao, " – ", df$name, " (", df$city, ")")
  setNames(df$icao, lbl)
}

# ── Theme ─────────────────────────────────────────────────────────────────────
dash_theme <- bs_theme(
  version    = 5,
  bg         = "#f8f9fa",
  fg         = "#212529",
  primary    = "#003399",
  secondary  = "#009C3B",
  base_font  = font_google("Inter"),
  heading_font = font_google("Inter", wght = "600")
)

plot_theme <- theme_minimal(base_size = 12) +
  theme(
    plot.background  = element_rect(fill = "white", colour = NA),
    panel.grid.minor = element_blank(),
    legend.position  = "bottom"
  )

# ══════════════════════════════════════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════════════════════════════════════
ui <- page_navbar(
  title = div(
    img(src = "logo_bra_eur.png", height = "32px",
        style = "margin-right:8px; vertical-align:middle;",
        onerror = "this.style.display='none'"),
    "Brazil / Europe ANS Performance Dashboard"
  ),
  theme  = dash_theme,
  window_title = "BRA-EUR Dashboard",
  bg     = "#003399",
  fillable = TRUE,

  # ── Tab 1: Overview ──────────────────────────────────────────────────────
  nav_panel(
    title = "Overview",
    icon  = icon("chart-line"),

    layout_columns(
      col_widths = c(4, 4, 4),
      value_box(
        title    = "Brazil 2025 Flights",
        value    = "2.1 M",
        showcase = icon("plane-departure"),
        theme    = "success",
        p("19% of European traffic")
      ),
      value_box(
        title    = "Europe 2025 Flights",
        value    = "11.0 M",
        showcase = icon("globe"),
        theme    = "primary",
        p("~4× higher traffic density")
      ),
      value_box(
        title    = "Brazil Dep. Punctuality 2025",
        value    = "81%",
        showcase = icon("clock"),
        theme    = "secondary",
        p("Within ±15 min | Europe: 66%")
      )
    ),

    br(),

    layout_columns(
      col_widths = c(7, 5),

      card(
        card_header("Traffic Volume 2019–2025"),
        plotOutput("ov_traffic", height = "340px")
      ),

      card(
        card_header("Report Key Performance Areas"),
        tags$ul(
          style = "margin-top:10px; line-height:2;",
          tags$li(icon("plane"), strong(" Traffic Characterisation"),
                  " — network & airport level"),
          tags$li(icon("clock"), strong(" Predictability"),
                  " — arrival & departure punctuality"),
          tags$li(icon("tachometer-alt"), strong(" Capacity & Throughput"),
                  " — declared capacity, peak rates"),
          tags$li(icon("road"), strong(" Taxi & ASMA"),
                  " — additional surface & sequencing times"),
          tags$li(icon("route"), strong(" Flight Efficiency (HFE/VFE)"),
                  " — horizontal & vertical")
        ),
        tags$hr(),
        p(icon("info-circle"), " Data: DECEA & EUROCONTROL | Period: 2019–2025",
          class = "text-muted small")
      )
    )
  ),

  # ── Tab 2: Traffic ───────────────────────────────────────────────────────
  nav_panel(
    title = "Traffic",
    icon  = icon("plane"),

    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        selectInput("tr_regions", "Region(s)",
                    choices  = c("Brazil", "Europe"),
                    selected = c("Brazil", "Europe"),
                    multiple = TRUE),
        sliderInput("tr_years", "Year range",
                    min = 2019, max = 2025, value = c(2019, 2025), sep = "")
      ),

      layout_columns(
        col_widths = c(7, 5),

        card(
          card_header("Annual Controlled Flights (millions)"),
          plotOutput("tr_annual", height = "340px")
        ),

        card(
          card_header("2025 Traffic Share"),
          plotOutput("tr_share_bar", height = "340px")
        )
      ),

      br(),

      card(
        card_header("Data Table – Traffic Volume"),
        DTOutput("tr_table")
      )
    )
  ),

  # ── Tab 3: Punctuality ───────────────────────────────────────────────────
  nav_panel(
    title = "Punctuality",
    icon  = icon("clock"),

    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        radioButtons("pt_type", "Flight type",
                     choices = c("Arrival" = "arrival", "Departure" = "departure"),
                     selected = "arrival"),
        radioButtons("pt_year", "Year",
                     choices = c("2024", "2025"), selected = "2025"),
        selectInput("pt_region", "Region",
                    choices = c("Both", "Brazil", "Europe"),
                    selected = "Both"),
        hr(),
        p(class = "text-muted small",
          "Punctuality bands: Early >15 min, Early 5–15 min, Within ±5 min,",
          "Late 5–15 min, Late >15 min")
      ),

      card(
        card_header("Punctuality Distribution by Airport"),
        plotOutput("pt_stacked", height = "500px")
      ),

      br(),

      layout_columns(
        col_widths = c(6, 6),
        card(
          card_header("% Within ±15 min – Brazil"),
          plotOutput("pt_pct_bra", height = "300px")
        ),
        card(
          card_header("% Within ±15 min – Europe"),
          plotOutput("pt_pct_eur", height = "300px")
        )
      )
    )
  ),

  # ── Tab 4: Capacity & Throughput ─────────────────────────────────────────
  nav_panel(
    title = "Capacity & Throughput",
    icon  = icon("tachometer-alt"),

    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        selectInput("cap_region", "Region",
                    choices  = c("Both", "Brazil", "Europe"),
                    selected = "Both"),
        sliderInput("cap_years", "Throughput year range",
                    min = 2019, max = 2025, value = c(2019, 2025), sep = "")
      ),

      card(
        card_header("Peak Declared Capacity (flights/hour) – 2025"),
        plotOutput("cap_declared", height = "380px")
      ),

      br(),

      card(
        card_header("Peak Arrival Throughput Evolution"),
        plotOutput("cap_throughput", height = "380px")
      )
    )
  ),

  # ── Tab 5: Taxi & ASMA ───────────────────────────────────────────────────
  nav_panel(
    title = "Taxi & ASMA",
    icon  = icon("road"),

    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        selectInput("tx_metric", "Indicator",
                    choices = c(
                      "Additional Taxi-Out (min)" = "add_taxi_out_min",
                      "Additional Taxi-In (min)"  = "add_taxi_in_min",
                      "Additional ASMA (min)"     = "add_asma_min"
                    ),
                    selected = "add_taxi_out_min"),
        selectInput("tx_region", "Region",
                    choices  = c("Both", "Brazil", "Europe"),
                    selected = "Both"),
        sliderInput("tx_years", "Year range",
                    min = 2019, max = 2025, value = c(2019, 2025), sep = ""),
        hr(),
        p(class = "text-muted small",
          "Additional times measure inefficiency beyond the unimpeded reference time.")
      ),

      card(
        card_header("Evolution of Additional Times by Airport"),
        plotOutput("tx_trend", height = "480px")
      )
    )
  ),

  # ── Tab 6: Airport Comparison ────────────────────────────────────────────
  nav_panel(
    title = "Airport Comparison",
    icon  = icon("exchange-alt"),

    layout_sidebar(
      sidebar = sidebar(
        title = "Select Airports",
        selectInput("cmp_bra", "Brazil Airport",
                    choices  = ap_label(airports$icao[airports$region == "Brazil"]),
                    selected = "SBGR"),
        selectInput("cmp_eur", "Europe Airport",
                    choices  = ap_label(airports$icao[airports$region == "Europe"]),
                    selected = "LPPT"),
        radioButtons("cmp_ptype", "Punctuality type",
                     choices = c("Arrival" = "arrival", "Departure" = "departure"),
                     selected = "arrival")
      ),

      layout_columns(
        col_widths = c(6, 6),
        card(
          card_header(textOutput("cmp_title_bra")),
          plotOutput("cmp_punct_bra", height = "320px")
        ),
        card(
          card_header(textOutput("cmp_title_eur")),
          plotOutput("cmp_punct_eur", height = "320px")
        )
      ),

      br(),

      card(
        card_header("Additional Times Comparison"),
        plotOutput("cmp_taxi", height = "300px")
      )
    )
  ),

  # ── Tab 7: Data ──────────────────────────────────────────────────────────
  nav_panel(
    title = "Data",
    icon  = icon("table"),

    navset_card_underline(
      nav_panel("Airports",     DTOutput("dt_airports")),
      nav_panel("Traffic",      DTOutput("dt_traffic")),
      nav_panel("Punctuality",  DTOutput("dt_punct")),
      nav_panel("Capacity",     DTOutput("dt_cap")),
      nav_panel("Taxi & ASMA",  DTOutput("dt_taxi"))
    )
  )
)

# ══════════════════════════════════════════════════════════════════════════════
# Server
# ══════════════════════════════════════════════════════════════════════════════
server <- function(input, output, session) {

  # ── Overview ───────────────────────────────────────────────────────────────
  output$ov_traffic <- renderPlot({
    ggplot(traffic_vol, aes(year, controlled_flights_million,
                            colour = region, group = region)) +
      geom_line(linewidth = 1.4) +
      geom_point(size = 3) +
      scale_colour_manual(values = c(Brazil = COL_BRA, Europe = COL_EUR)) +
      scale_x_continuous(breaks = 2019:2025) +
      labs(x = NULL, y = "Controlled Flights (millions)",
           colour = NULL, title = NULL) +
      plot_theme
  })

  # ── Traffic ────────────────────────────────────────────────────────────────
  tv_filt <- reactive({
    traffic_vol |>
      filter(region %in% input$tr_regions,
             year >= input$tr_years[1], year <= input$tr_years[2])
  })

  output$tr_annual <- renderPlot({
    ggplot(tv_filt(), aes(year, controlled_flights_million,
                          colour = region, group = region)) +
      geom_line(linewidth = 1.4) +
      geom_point(size = 3) +
      scale_colour_manual(values = c(Brazil = COL_BRA, Europe = COL_EUR)) +
      scale_x_continuous(breaks = 2019:2025) +
      labs(x = NULL, y = "Million flights", colour = NULL) +
      plot_theme
  })

  output$tr_share_bar <- renderPlot({
    d <- traffic_vol |> filter(year == 2025, region %in% input$tr_regions)
    ggplot(d, aes(region, controlled_flights_million, fill = region)) +
      geom_col(width = 0.5) +
      geom_text(aes(label = paste0(controlled_flights_million, "M")),
                vjust = -0.5, size = 5, fontface = "bold") +
      scale_fill_manual(values = c(Brazil = COL_BRA, Europe = COL_EUR)) +
      labs(x = NULL, y = "Million flights", fill = NULL, title = "2025") +
      plot_theme + theme(legend.position = "none")
  })

  output$tr_table <- renderDT({
    datatable(tv_filt(), options = list(pageLength = 10), rownames = FALSE)
  })

  # ── Punctuality helpers ────────────────────────────────────────────────────
  pt_data <- reactive({
    d <- punctuality |>
      filter(type == input$pt_type, year == as.integer(input$pt_year))
    if (input$pt_region != "Both") d <- d |> filter(region == input$pt_region)

    d |>
      pivot_longer(c(early_gt15, early_5to15, within_5, late_5to15, late_gt15),
                   names_to = "band", values_to = "pct") |>
      mutate(band = factor(band,
        levels = c("early_gt15","early_5to15","within_5","late_5to15","late_gt15"),
        labels = c("Early (>15 min)","Early (5–15 min)","Within ±5 min",
                   "Late (5–15 min)","Late (>15 min)")))
  })

  output$pt_stacked <- renderPlot({
    d <- pt_data() |>
      mutate(airport_lbl = paste0(icao, "\n", airports$city[match(icao, airports$icao)]))
    ggplot(d, aes(airport_lbl, pct, fill = band)) +
      geom_col(position = "stack") +
      facet_wrap(~ region, scales = "free_x") +
      scale_fill_manual(values = PUNCT_COLS) +
      labs(x = NULL, y = "%", fill = NULL) +
      plot_theme +
      theme(axis.text.x = element_text(size = 8))
  })

  pct_within15 <- function(rgn) {
    punctuality |>
      filter(type == input$pt_type, year == as.integer(input$pt_year),
             region == rgn) |>
      mutate(within15 = early_5to15 + within_5 + late_5to15) |>
      left_join(airports[, c("icao","city")], by = "icao") |>
      mutate(label = paste0(icao, " (", city, ")"))
  }

  output$pt_pct_bra <- renderPlot({
    d <- pct_within15("Brazil")
    ggplot(d, aes(reorder(label, within15), within15)) +
      geom_col(fill = COL_BRA) +
      geom_text(aes(label = paste0(within15, "%")), hjust = -0.1, size = 3.5) +
      coord_flip() +
      scale_y_continuous(limits = c(0, 105)) +
      labs(x = NULL, y = "% within ±15 min") +
      plot_theme
  })

  output$pt_pct_eur <- renderPlot({
    d <- pct_within15("Europe")
    ggplot(d, aes(reorder(label, within15), within15)) +
      geom_col(fill = COL_EUR) +
      geom_text(aes(label = paste0(within15, "%")), hjust = -0.1, size = 3.5) +
      coord_flip() +
      scale_y_continuous(limits = c(0, 105)) +
      labs(x = NULL, y = "% within ±15 min") +
      plot_theme
  })

  # ── Capacity & Throughput ──────────────────────────────────────────────────
  cap_filt <- reactive({
    d <- cap_thr
    if (input$cap_region != "Both") d <- d |> filter(region == input$cap_region)
    d
  })

  output$cap_declared <- renderPlot({
    d <- cap_filt() |>
      left_join(airports[, c("icao","city")], by = "icao") |>
      mutate(label = paste0(icao, " – ", city)) |>
      arrange(peak_declared_capacity)
    ggplot(d, aes(reorder(label, peak_declared_capacity),
                  peak_declared_capacity, fill = region)) +
      geom_col() +
      geom_text(aes(label = peak_declared_capacity), hjust = -0.1, size = 3) +
      coord_flip() +
      scale_fill_manual(values = c(Brazil = COL_BRA, Europe = COL_EUR)) +
      scale_y_continuous(limits = c(0, 135)) +
      labs(x = NULL, y = "Flights/hour", fill = NULL) +
      plot_theme
  })

  output$cap_throughput <- renderPlot({
    yrs <- input$cap_years[1]:input$cap_years[2]
    yr_cols <- paste0("peak_arrival_throughput_", yrs)
    yr_cols <- yr_cols[yr_cols %in% names(cap_thr)]

    d <- cap_filt() |>
      select(icao, region, all_of(yr_cols)) |>
      pivot_longer(all_of(yr_cols), names_to = "year", values_to = "throughput") |>
      mutate(year = as.integer(sub("peak_arrival_throughput_", "", year))) |>
      filter(!is.na(throughput)) |>
      left_join(airports[, c("icao","city")], by = "icao") |>
      mutate(label = paste0(icao, " (", city, ")"))

    ggplot(d, aes(year, throughput, colour = region, group = label)) +
      geom_line(alpha = 0.6, linewidth = 0.8) +
      geom_point(size = 1.5, alpha = 0.7) +
      facet_wrap(~ region) +
      scale_colour_manual(values = c(Brazil = COL_BRA, Europe = COL_EUR)) +
      scale_x_continuous(breaks = yrs) +
      labs(x = NULL, y = "Peak arrival throughput (95th pct, flights/h)",
           colour = NULL) +
      plot_theme +
      theme(legend.position = "none")
  })

  # ── Taxi & ASMA ────────────────────────────────────────────────────────────
  tx_filt <- reactive({
    d <- taxi_asma |>
      filter(year >= input$tx_years[1], year <= input$tx_years[2])
    if (input$tx_region != "Both") d <- d |> filter(region == input$tx_region)
    d |>
      left_join(airports[, c("icao","city")], by = "icao") |>
      mutate(label = paste0(icao, " (", city, ")"),
             value = .data[[input$tx_metric]])
  })

  output$tx_trend <- renderPlot({
    d <- tx_filt() |> filter(!is.na(value))
    ggplot(d, aes(year, value, colour = region, group = label)) +
      geom_line(alpha = 0.7, linewidth = 0.8) +
      geom_point(size = 1.5, alpha = 0.8) +
      facet_wrap(~ label, ncol = 4, scales = "free_y") +
      scale_colour_manual(values = c(Brazil = COL_BRA, Europe = COL_EUR)) +
      scale_x_continuous(breaks = c(2019, 2021, 2023, 2025)) +
      labs(x = NULL,
           y = names(which(c(
             "Additional Taxi-Out (min)" = "add_taxi_out_min",
             "Additional Taxi-In (min)"  = "add_taxi_in_min",
             "Additional ASMA (min)"     = "add_asma_min"
           ) == input$tx_metric)),
           colour = NULL) +
      plot_theme +
      theme(strip.text = element_text(size = 7),
            axis.text  = element_text(size = 7))
  })

  # ── Airport Comparison ─────────────────────────────────────────────────────
  ap_name <- function(icao) {
    r <- airports[airports$icao == icao, ]
    paste0(icao, " – ", r$name, " (", r$city, ")")
  }

  output$cmp_title_bra <- renderText(ap_name(input$cmp_bra))
  output$cmp_title_eur <- renderText(ap_name(input$cmp_eur))

  cmp_punct <- function(icao_sel) {
    punctuality |>
      filter(icao == icao_sel, type == input$cmp_ptype) |>
      pivot_longer(c(early_gt15, early_5to15, within_5, late_5to15, late_gt15),
                   names_to = "band", values_to = "pct") |>
      mutate(
        band = factor(band,
          levels = c("early_gt15","early_5to15","within_5","late_5to15","late_gt15"),
          labels = c("Early (>15 min)","Early (5–15 min)","Within ±5 min",
                     "Late (5–15 min)","Late (>15 min)")),
        year = as.character(year)
      )
  }

  output$cmp_punct_bra <- renderPlot({
    d <- cmp_punct(input$cmp_bra)
    ggplot(d, aes(year, pct, fill = band)) +
      geom_col(position = "stack") +
      scale_fill_manual(values = PUNCT_COLS) +
      labs(x = NULL, y = "%", fill = NULL) +
      plot_theme
  })

  output$cmp_punct_eur <- renderPlot({
    d <- cmp_punct(input$cmp_eur)
    ggplot(d, aes(year, pct, fill = band)) +
      geom_col(position = "stack") +
      scale_fill_manual(values = PUNCT_COLS) +
      labs(x = NULL, y = "%", fill = NULL) +
      plot_theme
  })

  output$cmp_taxi <- renderPlot({
    icaos <- c(input$cmp_bra, input$cmp_eur)
    d <- taxi_asma |>
      filter(icao %in% icaos) |>
      pivot_longer(c(add_taxi_out_min, add_taxi_in_min, add_asma_min),
                   names_to = "metric", values_to = "value") |>
      mutate(
        metric = recode(metric,
          add_taxi_out_min = "Add. Taxi-Out",
          add_taxi_in_min  = "Add. Taxi-In",
          add_asma_min     = "Add. ASMA"),
        col = ifelse(icao == input$cmp_bra, COL_BRA, COL_EUR)
      ) |>
      left_join(airports[, c("icao","region")], by = "icao")

    ggplot(d, aes(year, value, colour = icao, group = icao)) +
      geom_line(linewidth = 1.2) +
      geom_point(size = 2.5) +
      facet_wrap(~ metric) +
      scale_colour_manual(
        values = setNames(
          c(COL_BRA, COL_EUR),
          c(input$cmp_bra, input$cmp_eur)
        )
      ) +
      scale_x_continuous(breaks = c(2019,2021,2023,2025)) +
      labs(x = NULL, y = "Minutes", colour = NULL) +
      plot_theme
  })

  # ── Data tables ────────────────────────────────────────────────────────────
  dt_opts <- list(scrollX = TRUE, pageLength = 15)
  output$dt_airports <- renderDT({ datatable(airports,     options = dt_opts, rownames = FALSE) })
  output$dt_traffic  <- renderDT({ datatable(traffic_vol,  options = dt_opts, rownames = FALSE) })
  output$dt_punct    <- renderDT({ datatable(punctuality,  options = dt_opts, rownames = FALSE) })
  output$dt_cap      <- renderDT({ datatable(cap_thr,      options = dt_opts, rownames = FALSE) })
  output$dt_taxi     <- renderDT({ datatable(taxi_asma,    options = dt_opts, rownames = FALSE) })
}

shinyApp(ui, server)
