library(shiny)
library(shinydashboard)
library(tidyverse)
library(leaflet)
library(plotly)
library(DT)
library(sf)


select <- dplyr::select

# ══════════════════════════════════════════════════════════════
# LOAD DATA
# ══════════════════════════════════════════════════════════════
cat("📦 Loading data...\n")
data        <- readRDS("data/clean_data.rds")
flood_model <- readRDS("data/flood_model.rds")
predictions <- readRDS("data/today_predictions.rds")

cat("🗺️ Loading Sri Lanka boundaries...\n")
lka_districts <- readRDS("data/sl_districts_merged.rds")
cat("✅ District boundaries loaded! Districts:", nrow(lka_districts), "\n")

coords <- data.frame(
  district = c("Colombo","Kandy","Galle","Jaffna","Badulla","Ratnapura"),
  lat      = c(6.9271, 7.2906, 6.0535, 9.6615, 6.9934, 6.6828),
  lon      = c(79.8612, 80.6337, 80.2210, 80.0255, 81.0550, 80.3992)
)
predictions <- predictions %>% left_join(coords, by = "district")
cat("✅ All data loaded successfully!\n\n")

# ══════════════════════════════════════════════════════════════
# DESIGN SYSTEM — Premium Dark Sci-Fi Theme
# ══════════════════════════════════════════════════════════════
premium_css <- "
  @import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');

  :root {
    --bg-base:       #020408;
    --bg-surface:    #080d14;
    --bg-elevated:   #0d1520;
    --bg-card:       rgba(13,21,32,0.92);
    --bg-hover:      rgba(30,50,80,0.4);
    --border:        rgba(30,80,140,0.25);
    --border-bright: rgba(56,139,253,0.4);
    --accent-blue:   #388bfd;
    --accent-cyan:   #39c5cf;
    --accent-green:  #3fb950;
    --accent-orange: #f0883e;
    --accent-red:    #f85149;
    --accent-purple: #bc8cff;
    --text-primary:  #e6edf3;
    --text-secondary:#8b949e;
    --text-muted:    #484f58;
    --glow-blue:     0 0 20px rgba(56,139,253,0.3);
    --glow-red:      0 0 20px rgba(248,81,73,0.3);
    --glow-green:    0 0 20px rgba(63,185,80,0.3);
    --radius-sm:     6px;
    --radius-md:     10px;
    --radius-lg:     16px;
  }

  * { font-family: 'Space Grotesk', sans-serif !important; box-sizing: border-box; }
  code, .mono { font-family: 'JetBrains Mono', monospace !important; }

  /* ── BODY & LAYOUT ── */
  body, .wrapper, .content-wrapper, .right-side {
    background: var(--bg-base) !important;
    color: var(--text-primary) !important;
    background-image:
      radial-gradient(ellipse at 20% 10%, rgba(56,139,253,0.04) 0%, transparent 50%),
      radial-gradient(ellipse at 80% 90%, rgba(63,185,80,0.03) 0%, transparent 50%) !important;
  }

  /* ── HEADER ── */
  .skin-black .main-header .logo {
    background: linear-gradient(135deg, #080d14 0%, #0d1520 100%) !important;
    border-bottom: 1px solid var(--border) !important;
    border-right: 1px solid var(--border) !important;
    font-size: 14px !important;
    letter-spacing: 1px;
  }
  .skin-black .main-header .navbar {
    background: linear-gradient(135deg, #080d14 0%, #0a1020 100%) !important;
    border-bottom: 1px solid var(--border) !important;
  }
  .skin-black .main-header .logo:hover { background: var(--bg-elevated) !important; }

  /* ── SIDEBAR ── */
  .skin-black .main-sidebar {
    background: linear-gradient(180deg, #060b12 0%, #080d14 60%, #060b12 100%) !important;
    border-right: 1px solid var(--border) !important;
  }
  .skin-black .main-sidebar .sidebar .sidebar-menu > li > a {
    color: var(--text-secondary) !important;
    border-radius: var(--radius-md) !important;
    margin: 3px 10px !important;
    padding: 10px 14px !important;
    font-size: 13px !important;
    font-weight: 500 !important;
    letter-spacing: 0.3px !important;
    transition: all 0.25s cubic-bezier(0.4,0,0.2,1) !important;
    border-left: 2px solid transparent !important;
  }
  .skin-black .main-sidebar .sidebar .sidebar-menu > li.active > a,
  .skin-black .main-sidebar .sidebar .sidebar-menu > li > a:hover {
    color: var(--accent-blue) !important;
    background: rgba(56,139,253,0.1) !important;
    border-left: 2px solid var(--accent-blue) !important;
  }

  /* ── BOXES ── */
  .box {
    background: var(--bg-card) !important;
    backdrop-filter: blur(12px) !important;
    -webkit-backdrop-filter: blur(12px) !important;
    border: 1px solid var(--border) !important;
    border-radius: var(--radius-lg) !important;
    border-top: none !important;
    box-shadow: 0 4px 24px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.03) !important;
    overflow: hidden !important;
    transition: box-shadow 0.3s ease !important;
  }
  .box:hover { box-shadow: 0 8px 40px rgba(0,0,0,0.6), 0 0 0 1px var(--border-bright) !important; }
  .box-header {
    background: linear-gradient(135deg, rgba(13,21,32,0.95), rgba(8,13,20,0.95)) !important;
    border-bottom: 1px solid var(--border) !important;
    padding: 13px 18px !important;
  }
  .box-title {
    color: var(--text-primary) !important;
    font-weight: 600 !important;
    font-size: 13px !important;
    letter-spacing: 0.3px !important;
  }
  .box-body { padding: 16px !important; }

  /* ── VALUE BOXES ── */
  .small-box {
    border-radius: var(--radius-lg) !important;
    border: 1px solid var(--border) !important;
    background: var(--bg-card) !important;
    backdrop-filter: blur(12px) !important;
    box-shadow: 0 4px 20px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.03) !important;
    transition: transform 0.3s cubic-bezier(0.4,0,0.2,1), box-shadow 0.3s ease !important;
    overflow: hidden !important;
    position: relative !important;
  }
  .small-box::before {
    content: '';
    position: absolute;
    top: 0; left: 0; right: 0;
    height: 2px;
    background: linear-gradient(90deg, transparent, currentColor, transparent);
    opacity: 0.4;
  }
  .small-box:hover {
    transform: translateY(-5px) !important;
    box-shadow: 0 12px 40px rgba(0,0,0,0.6), 0 0 0 1px var(--border-bright) !important;
  }
  .small-box .inner { padding: 18px 22px !important; }
  .small-box h3 {
    font-size: 30px !important;
    font-weight: 700 !important;
    letter-spacing: -0.5px !important;
    margin-bottom: 2px !important;
  }
  .small-box p {
    font-size: 12px !important;
    font-weight: 500 !important;
    opacity: 0.8 !important;
    letter-spacing: 0.3px !important;
  }
  .small-box .icon { opacity: 0.12 !important; }

  /* ── BADGE-STYLE RISK INDICATORS ── */
  .risk-critical {
    color: var(--accent-red) !important;
    text-shadow: 0 0 12px rgba(248,81,73,0.6) !important;
    animation: pulse-red 2s ease-in-out infinite !important;
  }
  .risk-high     { color: var(--accent-orange) !important; text-shadow: 0 0 10px rgba(240,136,62,0.5) !important; }
  .risk-moderate { color: #e3b341 !important;              text-shadow: 0 0 10px rgba(227,179,65,0.4) !important; }
  .risk-normal   { color: var(--accent-green) !important;  text-shadow: 0 0 10px rgba(63,185,80,0.4) !important; }

  @keyframes pulse-red {
    0%, 100% { opacity: 1; text-shadow: 0 0 12px rgba(248,81,73,0.6); }
    50%       { opacity: 0.65; text-shadow: 0 0 24px rgba(248,81,73,0.9); }
  }

  /* ── CLOCK PILL ── */
  .clock-pill {
    background: rgba(56,139,253,0.1);
    border: 1px solid rgba(56,139,253,0.25);
    border-radius: 20px;
    padding: 5px 16px;
    color: var(--accent-blue);
    font-size: 12px;
    font-weight: 500;
    font-family: 'JetBrains Mono', monospace !important;
    letter-spacing: 0.5px;
  }

  /* ── STATUS BADGE ── */
  .status-badge {
    display: inline-block;
    padding: 2px 10px;
    border-radius: 20px;
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.5px;
    text-transform: uppercase;
  }
  .badge-high     { background: rgba(248,81,73,0.15);  color: var(--accent-red);    border: 1px solid rgba(248,81,73,0.3); }
  .badge-moderate { background: rgba(240,136,62,0.15); color: var(--accent-orange); border: 1px solid rgba(240,136,62,0.3); }
  .badge-low      { background: rgba(227,179,65,0.15); color: #e3b341;              border: 1px solid rgba(227,179,65,0.3); }
  .badge-minimal  { background: rgba(63,185,80,0.15);  color: var(--accent-green);  border: 1px solid rgba(63,185,80,0.3); }

  /* ── FORM CONTROLS ── */
  .selectize-input, .form-control, .selectize-dropdown {
    background: var(--bg-elevated) !important;
    border: 1px solid var(--border) !important;
    color: var(--text-primary) !important;
    border-radius: var(--radius-sm) !important;
    font-size: 13px !important;
    box-shadow: none !important;
  }
  .selectize-input:focus-within, .form-control:focus {
    border-color: var(--accent-blue) !important;
    box-shadow: 0 0 0 3px rgba(56,139,253,0.15) !important;
  }
  .selectize-dropdown { background: var(--bg-elevated) !important; border-color: var(--border-bright) !important; }
  .selectize-dropdown .option:hover, .selectize-dropdown .option.active {
    background: rgba(56,139,253,0.15) !important;
    color: var(--accent-blue) !important;
  }
  .control-label { color: var(--text-secondary) !important; font-size: 11px !important; font-weight: 500 !important; letter-spacing: 0.5px !important; text-transform: uppercase !important; }
  input[type=date] { color-scheme: dark; }

  /* ── DATA TABLES ── */
  .dataTables_wrapper { color: var(--text-primary) !important; }
  table.dataTable {
    border-collapse: separate !important;
    border-spacing: 0 !important;
    width: 100% !important;
  }
  table.dataTable thead tr th {
    background: rgba(8,13,20,0.9) !important;
    color: var(--accent-blue) !important;
    border-bottom: 1px solid var(--border-bright) !important;
    font-weight: 600 !important;
    font-size: 11px !important;
    text-transform: uppercase !important;
    letter-spacing: 0.8px !important;
    padding: 12px 14px !important;
  }
  table.dataTable tbody tr {
    background: rgba(8,13,20,0.5) !important;
    color: #c9d1d9 !important;
    border-bottom: 1px solid var(--border) !important;
    transition: background 0.15s ease !important;
  }
  table.dataTable tbody tr:hover td { background: var(--bg-hover) !important; }
  table.dataTable tbody td { padding: 10px 14px !important; border: none !important; }
  .dataTables_info, .dataTables_length label, .dataTables_filter label {
    color: var(--text-muted) !important;
    font-size: 12px !important;
  }
  .dataTables_paginate .paginate_button { color: var(--text-secondary) !important; }
  .dataTables_paginate .paginate_button.current { background: rgba(56,139,253,0.2) !important; color: var(--accent-blue) !important; border-color: var(--border-bright) !important; }

  /* ── PLAIN TABLE (shiny tableOutput) ── */
  .shiny-html-output table { width: 100% !important; border-collapse: collapse !important; font-size: 12px !important; }
  .shiny-html-output table th {
    background: rgba(8,13,20,0.9) !important;
    color: var(--accent-blue) !important;
    padding: 10px 12px !important;
    font-size: 10px !important;
    text-transform: uppercase !important;
    letter-spacing: 0.8px !important;
    border-bottom: 1px solid var(--border-bright) !important;
    font-weight: 600 !important;
  }
  .shiny-html-output table td {
    padding: 9px 12px !important;
    border-bottom: 1px solid var(--border) !important;
    color: #c9d1d9 !important;
    font-size: 12px !important;
  }
  .shiny-html-output table tr:hover td { background: var(--bg-hover) !important; }
  .shiny-html-output table tr:nth-child(even) td { background: rgba(56,139,253,0.03) !important; }
  .shiny-html-output table tr:nth-child(even):hover td { background: var(--bg-hover) !important; }

  /* ── SIDEBAR INFO ── */
  .sidebar-info {
    padding: 12px 14px;
    margin: 8px;
    background: rgba(56,139,253,0.05);
    border: 1px solid rgba(56,139,253,0.12);
    border-radius: var(--radius-md);
    font-size: 11px;
    color: var(--text-muted);
    line-height: 2;
    font-family: 'JetBrains Mono', monospace !important;
  }
  .sidebar-info span { color: var(--text-secondary); }

  /* ── DIVIDERS ── */
  hr { border-color: var(--border) !important; margin: 10px 0 !important; }

  /* ── SCROLLBARS ── */
  ::-webkit-scrollbar       { width: 5px; height: 5px; }
  ::-webkit-scrollbar-track { background: var(--bg-base); }
  ::-webkit-scrollbar-thumb { background: rgba(56,139,253,0.25); border-radius: 3px; }
  ::-webkit-scrollbar-thumb:hover { background: var(--accent-blue); }

  /* ── MODEL SPEC TABLE ── */
  .spec-table { width: 100%; border-collapse: collapse; }
  .spec-table td { padding: 10px 12px; border-bottom: 1px solid var(--border); font-size: 13px; }
  .spec-table td:first-child { color: var(--text-secondary); font-size: 12px; width: 45%; }
  .spec-table td:last-child  { font-weight: 600; }
  .spec-table tr:last-child td { border-bottom: none; }

  /* ── CONTENT PADDING ── */
  .tab-content > .active { padding-top: 4px; }
  .content-header { display: none !important; }
"

# ══════════════════════════════════════════════════════════════
# PLOTLY DARK LAYOUT HELPER
# ══════════════════════════════════════════════════════════════
dark_layout <- function(p, xtitle = "", ytitle = "") {
  p %>% layout(
    plot_bgcolor  = "rgba(0,0,0,0)",
    paper_bgcolor = "rgba(0,0,0,0)",
    font   = list(color = "#8b949e", family = "Space Grotesk"),
    xaxis  = list(
      title      = list(text = xtitle, font = list(size = 12, color = "#484f58")),
      color      = "#484f58",
      gridcolor  = "rgba(30,80,140,0.12)",
      zerolinecolor = "rgba(30,80,140,0.2)",
      tickfont   = list(size = 11, color = "#8b949e")
    ),
    yaxis  = list(
      title      = list(text = ytitle, font = list(size = 12, color = "#484f58")),
      color      = "#484f58",
      gridcolor  = "rgba(30,80,140,0.12)",
      zerolinecolor = "rgba(30,80,140,0.2)",
      tickfont   = list(size = 11, color = "#8b949e")
    ),
    legend = list(
      font        = list(color = "#8b949e", size = 12),
      bgcolor     = "rgba(8,13,20,0.85)",
      bordercolor = "rgba(30,80,140,0.3)",
      borderwidth = 1
    ),
    margin   = list(t = 20, r = 20, b = 50, l = 55),
    hoverlabel = list(
      bgcolor   = "#0d1520",
      bordercolor = "#388bfd",
      font      = list(color = "#e6edf3", family = "Space Grotesk", size = 12)
    )
  )
}

SL_PALETTE <- c("#388bfd", "#f85149", "#3fb950", "#bc8cff",
                "#f0883e", "#39c5cf", "#e3b341", "#56d364")

# ══════════════════════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════════════════════
ui <- dashboardPage(
  skin = "black",
  
  # ── HEADER ──────────────────────────────────────────────────
  dashboardHeader(
    title = tags$span(
      style = "font-weight:700; font-size:13px; letter-spacing:1px; color:#e6edf3;",
      tags$span(style = "color:#388bfd;", "◈ "),
      "SL WEATHER INTEL"
    ),
    titleWidth = 240,
    tags$li(
      class = "dropdown",
      style = "padding:9px 20px;",
      div(class = "clock-pill", textOutput("live_clock", inline = TRUE))
    )
  ),
  
  # ── SIDEBAR ─────────────────────────────────────────────────
  dashboardSidebar(
    width = 230,
    tags$head(tags$style(HTML(premium_css))),
    sidebarMenu(
      id = "tabs",
      menuItem("🗺️  Live Risk Map",    tabName = "map",    icon = icon("satellite-dish")),
      menuItem("🌊  Flood Analysis",   tabName = "flood",  icon = icon("water")),
      menuItem("🌧️  Rainfall Trends",  tabName = "trend",  icon = icon("cloud-rain")),
      menuItem("🌡️  Temperature",      tabName = "temp",   icon = icon("temperature-half")),
      menuItem("📊  District Stats",   tabName = "stats",  icon = icon("table-cells")),
      menuItem("🤖  ML Predictions",   tabName = "ml",     icon = icon("robot")),
      menuItem("☀️  Drought Monitor",  tabName = "drought", icon = icon("sun"))
    ),
    hr(),
    div(style = "padding: 0 12px;",
        selectInput(
          "selected_district", "DISTRICT FILTER",
          choices  = c("All Districts", sort(unique(data$district))),
          selected = "All Districts"
        ),
        dateRangeInput(
          "date_range", "DATE RANGE",
          start = max(data$date, na.rm = TRUE) - 90,
          end   = max(data$date, na.rm = TRUE)
        )
    ),
    hr(),
    div(class = "sidebar-info",
        tags$span("🛰️"), " NASA POWER API", br(),
        tags$span("🔄"), " Refresh: Daily",  br(),
        tags$span("📅"), paste0(" Latest: ", max(data$date, na.rm = TRUE)), br(),
        tags$span("🇱🇰"), " 6 Districts Covered"
    )
  ),
  
  # ── BODY ────────────────────────────────────────────────────
  dashboardBody(
    tabItems(
      
      # ══════════════ TAB 1 — LIVE MAP ══════════════
      tabItem("map",
              fluidRow(
                valueBoxOutput("box_high",    width = 3),
                valueBoxOutput("box_mod",     width = 3),
                valueBoxOutput("box_rain",    width = 3),
                valueBoxOutput("box_hottest", width = 3)
              ),
              fluidRow(
                box(
                  width = 8, height = 560,
                  title = tags$span(style = "color:#388bfd; font-size:13px;",
                                    "🗺️  Sri Lanka — Live Risk Map"),
                  solidHeader = TRUE, status = "primary",
                  leafletOutput("live_map", height = 485)
                ),
                box(
                  width = 4, height = 560,
                  title = tags$span(style = "color:#f0883e; font-size:13px;",
                                    "⚡  District Alerts"),
                  solidHeader = TRUE, status = "warning",
                  div(style = "overflow-y:auto; max-height:490px;",
                      tableOutput("alert_table"))
                )
              )
      ),
      
      # ══════════════ TAB 2 — FLOOD RISK ═══════════
      tabItem("flood",
              fluidRow(
                box(
                  width = 12,
                  title = tags$span(style = "color:#f85149; font-size:13px;",
                                    "🌊  Flood Risk Days by District (2020–2024)"),
                  solidHeader = TRUE, status = "danger",
                  plotlyOutput("flood_bar", height = 360)
                )
              ),
              fluidRow(
                box(
                  width = 6,
                  title = tags$span(style = "color:#f0883e; font-size:13px;",
                                    "📅  Monthly High-Risk Pattern"),
                  solidHeader = TRUE, status = "warning",
                  plotlyOutput("flood_monthly", height = 300)
                ),
                box(
                  width = 6,
                  title = tags$span(style = "color:#f85149; font-size:13px;",
                                    "🔥  District × Month Risk Heatmap"),
                  solidHeader = TRUE, status = "danger",
                  plotlyOutput("flood_heatmap", height = 300)
                )
              )
      ),
      
      # ══════════════ TAB 3 — RAINFALL ═════════════
      tabItem("trend",
              fluidRow(
                box(
                  width = 12,
                  title = tags$span(style = "color:#388bfd; font-size:13px;",
                                    "🌧️  Rainfall Trend Over Time"),
                  solidHeader = TRUE, status = "info",
                  plotlyOutput("rainfall_trend", height = 360)
                )
              ),
              fluidRow(
                box(
                  width = 6,
                  title = tags$span(style = "color:#388bfd; font-size:13px;",
                                    "📊  Monthly Average Rainfall"),
                  solidHeader = TRUE, status = "primary",
                  plotlyOutput("monthly_rain", height = 300)
                ),
                box(
                  width = 6,
                  title = tags$span(style = "color:#39c5cf; font-size:13px;",
                                    "📈  Rainfall Distribution"),
                  solidHeader = TRUE, status = "info",
                  plotlyOutput("rain_dist", height = 300)
                )
              )
      ),
      
      # ══════════════ TAB 4 — TEMPERATURE ══════════
      tabItem("temp",
              fluidRow(
                box(
                  width = 12,
                  title = tags$span(style = "color:#f0883e; font-size:13px;",
                                    "🌡️  Temperature Trends by District"),
                  solidHeader = TRUE, status = "danger",
                  plotlyOutput("temp_trend", height = 360)
                )
              ),
              fluidRow(
                box(
                  width = 6,
                  title = tags$span(style = "color:#f0883e; font-size:13px;",
                                    "🌡️  Average Temperature by District"),
                  solidHeader = TRUE, status = "warning",
                  plotlyOutput("temp_bar", height = 300)
                ),
                box(
                  width = 6,
                  title = tags$span(style = "color:#388bfd; font-size:13px;",
                                    "💧  Humidity vs Temperature Scatter"),
                  solidHeader = TRUE, status = "info",
                  plotlyOutput("temp_humidity", height = 300)
                )
              )
      ),
      
      # ══════════════ TAB 5 — STATS ════════════════
      tabItem("stats",
              fluidRow(
                box(
                  width = 12,
                  title = tags$span(style = "color:#3fb950; font-size:13px;",
                                    "📊  Full District Statistics — 2020 to 2024"),
                  solidHeader = TRUE, status = "success",
                  DTOutput("stats_table")
                )
              )
      ),
      
      # ══════════════ TAB 6 — ML PREDICTIONS ═══════
      tabItem("ml",
              fluidRow(
                box(
                  width = 12,
                  title = tags$span(style = "color:#3fb950; font-size:13px;",
                                    "🤖  ML Flood Risk Probability by District"),
                  solidHeader = TRUE, status = "success",
                  plotlyOutput("ml_chart", height = 360)
                )
              ),
              fluidRow(
                # Model Specification Card
                box(
                  width = 5,
                  title = tags$span(style = "color:#388bfd; font-size:13px;",
                                    "🎯  Model Specifications"),
                  solidHeader = TRUE, status = "info",
                  div(style = "padding: 8px 4px;",
                      tags$table(
                        class = "spec-table",
                        tags$tr(
                          tags$td("Algorithm"),
                          tags$td(style = "color:#388bfd;", "Random Forest 🌲")
                        ),
                        tags$tr(
                          tags$td("Decision Trees"),
                          tags$td(style = "color:#3fb950;", "500 trees")
                        ),
                        tags$tr(
                          tags$td("Input Features"),
                          tags$td(style = "color:#f0883e;", "9 weather variables")
                        ),
                        tags$tr(
                          tags$td("Output Classes"),
                          tags$td(style = "color:#bc8cff;", "4 risk levels")
                        ),
                        tags$tr(
                          tags$td(tags$hr(), colspan = 2)
                        ),
                        tags$tr(
                          tags$td("🥇 Top Feature"),
                          tags$td(style = "color:#f85149;", "Rain Spike Index")
                        ),
                        tags$tr(
                          tags$td("🥈 2nd Feature"),
                          tags$td(style = "color:#f85149;", "7-Day Rainfall Avg")
                        ),
                        tags$tr(
                          tags$td("🥉 3rd Feature"),
                          tags$td(style = "color:#f85149;", "Humidity Level")
                        )
                      ) # end tags$table
                  )   # end div
                ),    # end box (model specs)
                
                # Live Prediction Results Card
                box(
                  width = 7,
                  title = tags$span(style = "color:#3fb950; font-size:13px;",
                                    "📋  Live Prediction Results"),
                  solidHeader = TRUE, status = "success",
                  DTOutput("pred_table")
                )   # end box (pred table)
              )     # end fluidRow
      ),      # end tabItem("ml")
      
      # ══════════════ TAB 7 — DROUGHT MONITOR ══════
      tabItem("drought",
              # Value boxes row
              fluidRow(
                valueBoxOutput("drought_box1", width = 3),
                valueBoxOutput("drought_box2", width = 3),
                valueBoxOutput("drought_box3", width = 3),
                valueBoxOutput("drought_box4", width = 3)
              ),
              # Main charts row
              fluidRow(
                box(
                  width = 8,
                  title = tags$span(style = "color:#f0883e; font-size:13px;",
                                    "☀️  Drought Risk Score by District (2020–2024)"),
                  solidHeader = TRUE, status = "warning",
                  plotlyOutput("drought_score_chart", height = 330)
                ),
                box(
                  width = 4,
                  title = tags$span(style = "color:#f85149; font-size:13px;",
                                    "📋  Current Drought Status"),
                  solidHeader = TRUE, status = "danger",
                  div(style = "overflow-y:auto; max-height:330px;",
                      tableOutput("drought_status_table"))
                )
              ),
              # SPI trend and forecast row
              fluidRow(
                box(
                  width = 6,
                  title = tags$span(style = "color:#388bfd; font-size:13px;",
                                    "📈  SPI Index Trend Over Time"),
                  solidHeader = TRUE, status = "info",
                  plotlyOutput("spi_trend", height = 300)
                ),
                box(
                  width = 6,
                  title = tags$span(style = "color:#3fb950; font-size:13px;",
                                    "🔮  6-Month Drought Forecast"),
                  solidHeader = TRUE, status = "success",
                  plotlyOutput("drought_forecast_chart", height = 300)
                )
              ),
              # Heatmap row
              fluidRow(
                box(
                  width = 12,
                  title = tags$span(style = "color:#f0883e; font-size:13px;",
                                    "🔥  Monthly Drought Heatmap by District"),
                  solidHeader = TRUE, status = "warning",
                  plotlyOutput("drought_heatmap", height = 280)
                )
              )
      )   # end tabItem("drought")
      
    )   # end tabItems()
  )     # end dashboardBody()
)       # end dashboardPage()


# ══════════════════════════════════════════════════════════════
# SERVER
# ══════════════════════════════════════════════════════════════
server <- function(input, output, session) {
  
  # ── Load drought data once at server start ───────────────────
  drought_data     <- readRDS("data/drought_data.rds")
  drought_scores   <- readRDS("data/drought_scores.rds")
  drought_forecast <- readRDS("data/drought_forecast.rds")
  current_drought  <- readRDS("data/current_drought.rds")
  
  # ── Live clock ───────────────────────────────────────────────
  output$live_clock <- renderText({
    invalidateLater(1000, session)
    format(Sys.time(), "%H:%M:%S  ·  %d %b %Y")
  })
  
  # ── Reactive filtered data ───────────────────────────────────
  filtered <- reactive({
    d <- data %>%
      filter(date >= input$date_range[1], date <= input$date_range[2])
    if (input$selected_district != "All Districts")
      d <- d %>% filter(district == input$selected_district)
    d
  })
  
  # ═══════════════════════════════════════
  # MAP TAB — VALUE BOXES
  # ═══════════════════════════════════════
  output$box_high <- renderValueBox({
    n <- sum(filtered()$flood_risk == "HIGH", na.rm = TRUE)
    valueBox(
      formatC(n, big.mark = ","),
      "🔴 HIGH Risk Days",
      color = "red",
      icon  = icon("triangle-exclamation")
    )
  })
  
  output$box_mod <- renderValueBox({
    n <- sum(filtered()$flood_risk == "MODERATE", na.rm = TRUE)
    valueBox(
      formatC(n, big.mark = ","),
      "🟠 Moderate Risk Days",
      color = "orange",
      icon  = icon("cloud-rain")
    )
  })
  
  output$box_rain <- renderValueBox({
    avg <- round(mean(filtered()$rainfall, na.rm = TRUE), 1)
    valueBox(
      paste0(avg, " mm"),
      "💧 Avg Daily Rainfall",
      color = "blue",
      icon  = icon("droplet")
    )
  })
  
  output$box_hottest <- renderValueBox({
    hot <- filtered() %>%
      group_by(district) %>%
      summarise(avg = mean(temp, na.rm = TRUE), .groups = "drop") %>%
      slice_max(avg, n = 1)
    valueBox(
      hot$district,
      paste0("🌡️ Hottest: ", round(hot$avg, 1), "°C"),
      color = "yellow",
      icon  = icon("sun")
    )
  })
  
  # ═══════════════════════════════════════
  # LIVE MAP
  # ═══════════════════════════════════════
  output$live_map <- renderLeaflet({
    lka_map <- readRDS("data/sl_districts_merged.rds")
    preds   <- readRDS("data/today_predictions.rds")
    
    preds$risk_level <- as.character(preds$risk_level)
    
    preds$color <- dplyr::case_when(
      preds$risk_level == "HIGH"     ~ "#f85149",
      preds$risk_level == "MODERATE" ~ "#f0883e",
      preds$risk_level == "LOW"      ~ "#e3b341",
      TRUE                           ~ "#3fb950"
    )
    
    # Initialise defaults
    lka_map$color      <- "#484f58"
    lka_map$risk_level <- "No Data"
    lka_map$prob_high  <- 0
    lka_map$alert      <- "—"
    
    # Loop join (most reliable for sf objects)
    for (i in seq_len(nrow(lka_map))) {
      m <- preds[preds$district == lka_map$district[i], ]
      if (nrow(m) > 0) {
        lka_map$color[i]      <- m$color[1]
        lka_map$risk_level[i] <- m$risk_level[1]
        lka_map$prob_high[i]  <- m$prob_high[1]
        lka_map$alert[i]      <- m$alert[1]
      }
    }
    
    lka_map$popup_html <- paste0(
      "<div style='background:#0d1520;color:#e6edf3;",
      "padding:16px 18px;border-radius:10px;",
      "font-family:Arial,sans-serif;min-width:210px;",
      "border:1px solid ", lka_map$color, ";",
      "box-shadow:0 8px 24px rgba(0,0,0,0.5);'>",
      "<p style='margin:0 0 10px;font-size:16px;font-weight:700;color:",
      lka_map$color, ";'>📍 ", lka_map$district, "</p>",
      "<hr style='border-color:#21262d;margin:8px 0;'>",
      "<table style='width:100%;font-size:12px;'>",
      "<tr><td style='color:#8b949e;padding:3px 0;'>Risk Level</td>",
      "<td style='text-align:right;font-weight:700;color:", lka_map$color, ";'>",
      lka_map$risk_level, "</td></tr>",
      "<tr><td style='color:#8b949e;padding:3px 0;'>High Probability</td>",
      "<td style='text-align:right;font-weight:700;color:#f85149;'>",
      lka_map$prob_high, "%</td></tr>",
      "<tr><td style='color:#8b949e;padding:3px 0;'>Alert</td>",
      "<td style='text-align:right;color:#e6edf3;'>", lka_map$alert, "</td></tr>",
      "</table></div>"
    )
    
    leaflet(lka_map) %>%
      addProviderTiles(
        "CartoDB.DarkMatter",
        options = providerTileOptions(opacity = 0.85)
      ) %>%
      setView(lng = 80.7, lat = 7.8, zoom = 7) %>%
      addPolygons(
        fillColor   = ~color,
        fillOpacity = 0.78,
        color       = "rgba(255,255,255,0.15)",
        weight      = 1.5,
        highlightOptions = highlightOptions(
          weight      = 2.5,
          color       = "#388bfd",
          fillOpacity = 0.92,
          bringToFront = TRUE
        ),
        popup = ~popup_html,
        label = ~paste0("📍 ", district, "  ·  ", risk_level, "  ·  ", prob_high, "%")
      ) %>%
      addLegend(
        "bottomright",
        colors  = c("#f85149", "#f0883e", "#e3b341", "#3fb950", "#484f58"),
        labels  = c("HIGH", "MODERATE", "LOW", "MINIMAL", "No Data"),
        title   = "🌊 Flood Risk",
        opacity = 0.9
      )
  })
  
  # ── Alert table ──────────────────────────────────────────────
  output$alert_table <- renderTable({
    predictions %>%
      dplyr::select(district, risk_level, prob_high, alert) %>%
      arrange(desc(prob_high)) %>%
      rename(District = district, Risk = risk_level, "High %" = prob_high, Alert = alert)
  }, striped = TRUE, hover = TRUE, bordered = TRUE)
  
  # ═══════════════════════════════════════
  # FLOOD TAB
  # ═══════════════════════════════════════
  output$flood_bar <- renderPlotly({
    d <- data %>%
      filter(flood_risk %in% c("HIGH", "MODERATE", "LOW")) %>%
      group_by(district, flood_risk) %>%
      summarise(days = n(), .groups = "drop")
    
    plot_ly(
      d, x = ~district, y = ~days, color = ~flood_risk, type = "bar",
      colors = c("HIGH" = "#f85149", "MODERATE" = "#f0883e", "LOW" = "#e3b341")
    ) %>%
      layout(barmode = "group") %>%
      dark_layout("District", "Number of Days")
  })
  
  output$flood_monthly <- renderPlotly({
    m <- filtered() %>%
      group_by(month) %>%
      summarise(high_days = sum(flood_risk == "HIGH", na.rm = TRUE), .groups = "drop")
    
    plot_ly(
      m, x = ~month, y = ~high_days, type = "scatter", mode = "lines+markers",
      line   = list(color = "#f85149", width = 2.5, shape = "spline"),
      marker = list(color = "#f85149", size = 8,
                    line = list(color = "#080d14", width = 2))
    ) %>%
      dark_layout("Month", "High Risk Days")
  })
  
  output$flood_heatmap <- renderPlotly({
    h <- data %>%
      mutate(month_num = as.numeric(format(date, "%m"))) %>%
      group_by(district, month_num) %>%
      summarise(high_days = sum(flood_risk == "HIGH", na.rm = TRUE), .groups = "drop")
    
    plot_ly(
      h, x = ~month_num, y = ~district, z = ~high_days, type = "heatmap",
      colorscale = list(
        list(0,   "#080d14"),
        list(0.3, "#3fb950"),
        list(0.6, "#e3b341"),
        list(1,   "#f85149")
      ),
      colorbar = list(tickfont = list(color = "#8b949e"))
    ) %>%
      dark_layout("Month", "")
  })
  
  # ═══════════════════════════════════════
  # RAINFALL TAB
  # ═══════════════════════════════════════
  output$rainfall_trend <- renderPlotly({
    d <- filtered() %>%
      group_by(date, district) %>%
      summarise(rain = mean(rainfall, na.rm = TRUE), .groups = "drop")
    
    plot_ly(
      d, x = ~date, y = ~rain, color = ~district,
      type = "scatter", mode = "lines",
      colors = SL_PALETTE, line = list(width = 2)
    ) %>%
      dark_layout("Date", "Rainfall (mm)")
  })
  
  output$monthly_rain <- renderPlotly({
    m <- filtered() %>%
      group_by(month) %>%
      summarise(avg_rain = mean(rainfall, na.rm = TRUE), .groups = "drop")
    
    plot_ly(
      m, x = ~month, y = ~avg_rain, type = "bar",
      marker = list(
        color = ~avg_rain,
        colorscale = list(list(0, "#1c3a6b"), list(1, "#388bfd")),
        showscale  = FALSE,
        line = list(color = "rgba(255,255,255,0.05)", width = 0.5)
      )
    ) %>%
      dark_layout("Month", "Avg Rainfall (mm)")
  })
  
  output$rain_dist <- renderPlotly({
    plot_ly(
      filtered(), x = ~rainfall, type = "histogram", nbinsx = 40,
      marker = list(
        color = "rgba(56,139,253,0.65)",
        line  = list(color = "rgba(56,139,253,0.15)", width = 0.5)
      )
    ) %>%
      dark_layout("Rainfall (mm)", "Frequency")
  })
  
  # ═══════════════════════════════════════
  # TEMPERATURE TAB
  # ═══════════════════════════════════════
  output$temp_trend <- renderPlotly({
    d <- filtered() %>%
      group_by(date, district) %>%
      summarise(temp = mean(temp, na.rm = TRUE), .groups = "drop")
    
    plot_ly(
      d, x = ~date, y = ~temp, color = ~district,
      type = "scatter", mode = "lines",
      colors = SL_PALETTE, line = list(width = 2)
    ) %>%
      dark_layout("Date", "Temperature (°C)")
  })
  
  output$temp_bar <- renderPlotly({
    d <- data %>%
      group_by(district) %>%
      summarise(avg_temp = mean(temp, na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(avg_temp))
    
    plot_ly(
      d, x = ~reorder(district, -avg_temp), y = ~avg_temp, type = "bar",
      marker = list(
        color = ~avg_temp,
        colorscale = list(list(0, "#1c3a6b"), list(0.5, "#f0883e"), list(1, "#f85149")),
        showscale  = FALSE
      )
    ) %>%
      dark_layout("District", "Avg Temperature (°C)")
  })
  
  output$temp_humidity <- renderPlotly({
    plot_ly(
      filtered(), x = ~temp, y = ~humidity, color = ~district,
      type = "scatter", mode = "markers",
      colors = SL_PALETTE,
      marker = list(size = 5, opacity = 0.5)
    ) %>%
      dark_layout("Temperature (°C)", "Humidity (%)")
  })
  
  # ═══════════════════════════════════════
  # STATS TAB
  # ═══════════════════════════════════════
  output$stats_table <- renderDT({
    data %>%
      group_by(district) %>%
      summarise(
        `Avg Rain (mm)`  = round(mean(rainfall, na.rm = TRUE), 2),
        `Max Rain (mm)`  = round(max(rainfall,  na.rm = TRUE), 2),
        `Avg Temp (°C)`  = round(mean(temp,     na.rm = TRUE), 1),
        `Humidity (%)`   = round(mean(humidity, na.rm = TRUE), 1),
        `HIGH Risk Days` = sum(flood_risk == "HIGH",     na.rm = TRUE),
        `MODERATE Days`  = sum(flood_risk == "MODERATE", na.rm = TRUE),
        `LOW Days`       = sum(flood_risk == "LOW",      na.rm = TRUE)
      ) %>%
      rename(District = district)
  },
  options = list(
    pageLength = 10, dom = "ft",
    initComplete = JS(
      "function(s,j) {
        $(this.api().table().header()).css({'color':'#388bfd','font-size':'11px'});
      }"
    )
  ),
  style = "bootstrap4",
  class = "table-dark table-striped table-hover"
  )
  
  # ═══════════════════════════════════════
  # ML TAB
  # ═══════════════════════════════════════
  output$ml_chart <- renderPlotly({
    pred <- predictions %>% arrange(desc(prob_high))
    
    plot_ly(
      pred, x = ~reorder(district, prob_high), y = ~prob_high,
      type = "bar",
      marker = list(
        color = ~prob_high,
        colorscale = list(
          list(0.0, "#3fb950"),
          list(0.4, "#e3b341"),
          list(0.7, "#f0883e"),
          list(1.0, "#f85149")
        ),
        showscale = TRUE,
        colorbar  = list(title = "Risk %", tickfont = list(color = "#8b949e")),
        line      = list(color = "rgba(255,255,255,0.06)", width = 0.5)
      ),
      text         = ~paste0(prob_high, "%"),
      textposition = "outside",
      textfont     = list(color = "#e6edf3", size = 13)
    ) %>%
      dark_layout("District", "High Flood Risk Probability (%)")
  })
  
  output$pred_table <- renderDT({
    predictions %>%
      dplyr::select(district, risk_level, prob_high, alert) %>%
      arrange(desc(prob_high)) %>%
      rename(
        District     = district,
        `Risk Level` = risk_level,
        `High Risk %`= prob_high,
        Alert        = alert
      )
  },
  options = list(pageLength = 10, dom = "t"),
  style   = "bootstrap4",
  class   = "table-dark table-striped table-hover"
  )
  
  # ═══════════════════════════════════════
  # DROUGHT TAB
  # ═══════════════════════════════════════
  output$drought_box1 <- renderValueBox({
    extreme <- sum(drought_data$drought_level == "EXTREME", na.rm = TRUE)
    valueBox(extreme, "🔴 Extreme Drought Months", color = "red",    icon = icon("sun"))
  })
  output$drought_box2 <- renderValueBox({
    severe <- sum(drought_data$drought_level == "SEVERE", na.rm = TRUE)
    valueBox(severe,  "🟠 Severe Drought Months",  color = "orange", icon = icon("droplet-slash"))
  })
  output$drought_box3 <- renderValueBox({
    worst <- drought_scores %>% slice_max(drought_score, n = 1)
    valueBox(
      worst$district,
      paste0("☀️ Highest Risk Score: ", worst$drought_score),
      color = "yellow",
      icon  = icon("triangle-exclamation")
    )
  })
  output$drought_box4 <- renderValueBox({
    avg_spi <- round(mean(drought_data$spi, na.rm = TRUE), 2)
    valueBox(avg_spi, "📊 Avg SPI Index", color = "blue", icon = icon("chart-line"))
  })
  
  output$drought_score_chart <- renderPlotly({
    plot_ly(
      drought_scores,
      x    = ~reorder(district, drought_score),
      y    = ~drought_score,
      type = "bar",
      marker = list(
        color = ~drought_score,
        colorscale = list(
          list(0.0, "#3fb950"), list(0.3, "#e3b341"),
          list(0.6, "#f0883e"), list(1.0, "#f85149")
        ),
        showscale = TRUE,
        colorbar  = list(title = "Score", tickfont = list(color = "#8b949e"))
      ),
      text         = ~paste0(drought_score, " — ", risk_rating),
      textposition = "outside",
      textfont     = list(color = "#e6edf3", size = 11)
    ) %>%
      dark_layout("District", "Drought Risk Score") %>%
      layout(
        annotations = list(list(
          x = 0.5, y = 1.08, xref = "paper", yref = "paper",
          text = "Higher score = more drought months historically",
          showarrow = FALSE,
          font = list(color = "#484f58", size = 11)
        ))
      )
  })
  
  output$drought_status_table <- renderTable({
    current_drought %>%
      dplyr::select(district, monthly_rain, spi, drought_level) %>%
      rename(
        District  = district,
        "Rain(mm)"= monthly_rain,
        SPI       = spi,
        Status    = drought_level
      ) %>%
      mutate(SPI = round(SPI, 2), "Rain(mm)" = round(`Rain(mm)`, 1))
  }, striped = TRUE, hover = TRUE, bordered = TRUE)
  
  output$spi_trend <- renderPlotly({
    spi_data <- drought_data
    if (input$selected_district != "All Districts")
      spi_data <- spi_data %>% filter(district == input$selected_district)
    
    plot_ly(
      spi_data, x = ~date, y = ~spi, color = ~district,
      type = "scatter", mode = "lines",
      colors = SL_PALETTE, line = list(width = 2)
    ) %>%
      dark_layout("Date", "SPI Index") %>%
      layout(
        shapes = list(
          list(type = "line", x0 = min(spi_data$date), x1 = max(spi_data$date),
               y0 = -1, y1 = -1,
               line = list(color = "#f0883e", dash = "dash", width = 1.5)),
          list(type = "line", x0 = min(spi_data$date), x1 = max(spi_data$date),
               y0 = -1.5, y1 = -1.5,
               line = list(color = "#f85149", dash = "dash", width = 1.5)),
          list(type = "line", x0 = min(spi_data$date), x1 = max(spi_data$date),
               y0 = 0, y1 = 0,
               line = list(color = "#484f58", dash = "dot", width = 1))
        ),
        annotations = list(
          list(x = max(spi_data$date), y = -1, text = "Moderate",
               showarrow = FALSE, font = list(color = "#f0883e", size = 10)),
          list(x = max(spi_data$date), y = -1.5, text = "Severe",
               showarrow = FALSE, font = list(color = "#f85149", size = 10))
        )
      )
  })
  
  output$drought_forecast_chart <- renderPlotly({
    plot_ly(
      drought_forecast, x = ~ds, y = ~spi_forecast, color = ~district,
      type = "scatter", mode = "lines+markers",
      colors = SL_PALETTE,
      line   = list(width = 2),
      marker = list(size = 7)
    ) %>%
      dark_layout("Date", "Forecasted SPI") %>%
      layout(
        shapes = list(list(
          type = "line",
          x0   = min(drought_forecast$ds),
          x1   = max(drought_forecast$ds),
          y0 = -1, y1 = -1,
          line = list(color = "#f0883e", dash = "dash", width = 1.5)
        ))
      )
  })
  
  output$drought_heatmap <- renderPlotly({
    hm <- drought_data %>%
      mutate(month_num = as.numeric(format(as.Date(date), "%m"))) %>%
      group_by(district, month_num) %>%
      summarise(avg_spi = mean(spi, na.rm = TRUE), .groups = "drop")
    
    plot_ly(
      hm, x = ~month_num, y = ~district, z = ~avg_spi,
      type = "heatmap",
      colorscale = list(
        list(0,   "#7d0000"),
        list(0.3, "#f85149"),
        list(0.5, "#e3b341"),
        list(0.7, "#3fb950"),
        list(1,   "#388bfd")
      ),
      colorbar = list(title = "SPI", tickfont = list(color = "#8b949e"))
    ) %>%
      dark_layout("Month", "") %>%
      layout(
        xaxis = list(
          tickvals = 1:12,
          ticktext = c("Jan","Feb","Mar","Apr","May","Jun",
                       "Jul","Aug","Sep","Oct","Nov","Dec")
        )
      )
  })
  
} # end server()


# ══════════════════════════════════════════════════════════════
# LAUNCH
# ══════════════════════════════════════════════════════════════
cat("\n╔══════════════════════════════════════════════════╗\n")
cat("║  ◈  SL WEATHER INTELLIGENCE  v3.0               ║\n")
cat("║  🚀  Launching Premium Dashboard...              ║\n")
cat("║  ⛔  Press Ctrl+C to stop                       ║\n")
cat("╚══════════════════════════════════════════════════╝\n\n")

shinyApp(ui = ui, server = server)
