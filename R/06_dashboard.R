library(shiny)
library(shinydashboard)
library(tidyverse)
library(leaflet)
library(plotly)
library(DT)
library(sf)        
library(geodata)

select <- dplyr::select

# ── Load Data ──────────────────────────────────
data        <- readRDS("D:/traning project/sri-lanka-weather/data/satellite/clean_data.rds")
flood_model <- readRDS("D:/traning project/sri-lanka-weather/data/flood_model.rds")
predictions <- readRDS("D:/traning project/sri-lanka-weather/data/today_predictions.rds")

coords <- data.frame(
  district = c("Colombo","Kandy","Galle","Jaffna","Badulla","Ratnapura"),
  lat      = c(6.9271,   7.2906, 6.0535, 9.6615,  6.9934,   6.6828),
  lon      = c(79.8612,  80.6337,80.2210,80.0255,  81.0550,  80.3992)
)
predictions <- predictions %>% left_join(coords, by="district")

# ══════════════════════════════════════════════
# ULTRA MODERN CSS
# ══════════════════════════════════════════════
modern_css <- "
  /* ── Import Google Font ── */
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap');

  * { font-family: 'Inter', sans-serif !important; }

  /* ── Animated gradient background ── */
  body, .content-wrapper, .right-side {
    background: linear-gradient(135deg, #0a0a1a 0%, #0d1117 40%, #0a1628 100%) !important;
    color: #e6edf3 !important;
  }

  /* ── Header ── */
  .skin-black .main-header .logo {
    background: linear-gradient(90deg, #0d1117, #161b22) !important;
    border-bottom: 1px solid #21262d !important;
    font-size: 16px !important;
    letter-spacing: 0.5px;
  }
  .skin-black .main-header .navbar {
    background: linear-gradient(90deg, #161b22, #0d1117) !important;
    border-bottom: 1px solid #21262d !important;
  }

  /* ── Sidebar ── */
  .skin-black .main-sidebar {
    background: linear-gradient(180deg, #0d1117 0%, #161b22 100%) !important;
    border-right: 1px solid #21262d !important;
  }
  .skin-black .main-sidebar .sidebar .sidebar-menu > li > a {
    color: #8b949e !important;
    border-radius: 8px !important;
    margin: 2px 8px !important;
    transition: all 0.3s ease !important;
  }
  .skin-black .main-sidebar .sidebar .sidebar-menu > li.active > a,
  .skin-black .main-sidebar .sidebar .sidebar-menu > li > a:hover {
    color: #58a6ff !important;
    background: rgba(88, 166, 255, 0.12) !important;
    border-left: 3px solid #58a6ff !important;
  }

  /* ── Glassmorphism Boxes ── */
  .box {
    background: rgba(22, 27, 34, 0.85) !important;
    backdrop-filter: blur(10px) !important;
    border: 1px solid #21262d !important;
    border-radius: 12px !important;
    border-top: none !important;
    box-shadow: 0 8px 32px rgba(0,0,0,0.4) !important;
    overflow: hidden !important;
  }
  .box-header {
    background: linear-gradient(90deg, rgba(31,35,40,0.9), rgba(22,27,34,0.9)) !important;
    border-bottom: 1px solid #21262d !important;
    padding: 12px 18px !important;
    color: #e6edf3 !important;
  }
  .box-title { color: #e6edf3 !important; font-weight: 600 !important; font-size: 14px !important; }

  /* ── Value Boxes ── */
  .small-box {
    border-radius: 12px !important;
    border: 1px solid #21262d !important;
    background: rgba(22, 27, 34, 0.9) !important;
    backdrop-filter: blur(10px) !important;
    box-shadow: 0 4px 20px rgba(0,0,0,0.3) !important;
    transition: transform 0.3s ease, box-shadow 0.3s ease !important;
  }
  .small-box:hover {
    transform: translateY(-4px) !important;
    box-shadow: 0 8px 30px rgba(0,0,0,0.5) !important;
  }
  .small-box .inner { padding: 16px 20px !important; }
  .small-box h3 { font-size: 32px !important; font-weight: 700 !important; }
  .small-box p  { font-size: 13px !important; font-weight: 500 !important; opacity: 0.85; }

  /* ── Glowing risk badge ── */
  .risk-critical { color:#ff4444; text-shadow: 0 0 10px #ff4444; animation: pulse 2s infinite; }
  .risk-high     { color:#ff8c00; text-shadow: 0 0 10px #ff8c00; }
  .risk-moderate { color:#ffd700; text-shadow: 0 0 8px #ffd700; }
  .risk-normal   { color:#00cc44; text-shadow: 0 0 8px #00cc44; }

  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50%       { opacity: 0.5; }
  }

  /* ── Live clock pill ── */
  .clock-pill {
    background: rgba(88,166,255,0.12);
    border: 1px solid rgba(88,166,255,0.3);
    border-radius: 20px;
    padding: 6px 16px;
    color: #58a6ff;
    font-size: 13px;
    font-weight: 500;
  }

  /* ── Sidebar inputs ── */
  .selectize-input, .form-control {
    background: rgba(22,27,34,0.95) !important;
    border: 1px solid #30363d !important;
    color: #e6edf3 !important;
    border-radius: 8px !important;
  }
  .control-label { color: #8b949e !important; font-size: 12px !important; }

  /* ── DataTable ── */
  .dataTables_wrapper { color: #e6edf3 !important; }
  table.dataTable thead th {
    background: #161b22 !important;
    color: #58a6ff !important;
    border-bottom: 2px solid #21262d !important;
    font-weight: 600 !important;
    font-size: 12px !important;
    text-transform: uppercase !important;
    letter-spacing: 0.5px !important;
  }
  table.dataTable tbody tr {
    background: rgba(13,17,23,0.6) !important;
    color: #c9d1d9 !important;
    border-bottom: 1px solid #21262d !important;
    transition: background 0.2s;
  }
  table.dataTable tbody tr:hover {
    background: rgba(88,166,255,0.08) !important;
  }
  .dataTables_info, .dataTables_length, .dataTables_filter { color: #8b949e !important; }

  /* ── Alert table ── */
  .shiny-html-output table {
    width: 100% !important;
    border-collapse: collapse !important;
    font-size: 13px !important;
  }
  .shiny-html-output table th {
    background: #161b22 !important;
    color: #58a6ff !important;
    padding: 10px !important;
    text-transform: uppercase !important;
    font-size: 11px !important;
    letter-spacing: 0.5px !important;
  }
  .shiny-html-output table td {
    padding: 10px !important;
    border-bottom: 1px solid #21262d !important;
    color: #c9d1d9 !important;
  }
  .shiny-html-output table tr:hover td { background: rgba(88,166,255,0.06) !important; }

  /* ── Scrollbar ── */
  ::-webkit-scrollbar { width: 6px; }
  ::-webkit-scrollbar-track { background: #0d1117; }
  ::-webkit-scrollbar-thumb { background: #30363d; border-radius: 3px; }
  ::-webkit-scrollbar-thumb:hover { background: #58a6ff; }

  /* ── HR divider ── */
  hr { border-color: #21262d !important; }

  /* ── Sidebar info text ── */
  .sidebar-info {
    padding: 12px 16px;
    margin: 8px;
    background: rgba(88,166,255,0.06);
    border: 1px solid rgba(88,166,255,0.15);
    border-radius: 8px;
    font-size: 11px;
    color: #8b949e;
    line-height: 1.8;
  }
"

# ══════════════════════════════════════════════
# PLOTLY LAYOUT DEFAULTS
# ══════════════════════════════════════════════
dark_layout <- function(p, xtitle="", ytitle="") {
  p %>% layout(
    plot_bgcolor  = "rgba(13,17,23,0.0)",
    paper_bgcolor = "rgba(13,17,23,0.0)",
    font  = list(color="#c9d1d9", family="Inter"),
    xaxis = list(title=xtitle, color="#8b949e", gridcolor="#21262d", zerolinecolor="#21262d"),
    yaxis = list(title=ytitle, color="#8b949e", gridcolor="#21262d", zerolinecolor="#21262d"),
    legend = list(font=list(color="#c9d1d9"), bgcolor="rgba(22,27,34,0.8)",
                  bordercolor="#21262d", borderwidth=1),
    margin = list(t=30, r=20, b=50, l=50)
  )
}

SL_PALETTE <- c("#58a6ff","#f78166","#3fb950","#d2a8ff",
                "#ffa657","#79c0ff","#ff7b72","#56d364")

# ══════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════
ui <- dashboardPage(
  skin = "black",
  
  dashboardHeader(
    title = tags$span(
      style = "font-weight:700; font-size:15px; letter-spacing:0.5px; color:#e6edf3;",
      "🛰️  SL Weather Intel"
    ),
    titleWidth = 240,
    tags$li(
      class = "dropdown",
      style = "padding:10px 20px;",
      div(class="clock-pill", textOutput("live_clock", inline=TRUE))
    )
  ),
  
  dashboardSidebar(
    width = 230,
    tags$head(tags$style(HTML(modern_css))),
    
    sidebarMenu(
      id = "tabs",
      menuItem("🗺️  Live Map",       tabName="map",     icon=icon("satellite-dish")),
      menuItem("🌊  Flood Risk",     tabName="flood",   icon=icon("water")),
      menuItem("🌧️  Rainfall",       tabName="trend",   icon=icon("cloud-rain")),
      menuItem("🌡️  Temperature",    tabName="temp",    icon=icon("temperature-half")),
      menuItem("📊  District Stats", tabName="stats",   icon=icon("table-cells")),
      menuItem("🤖  ML Predictions", tabName="ml",      icon=icon("robot"))
    ),
    
    hr(),
    
    div(style="padding:0 12px;",
        selectInput("selected_district", "📍 District Filter:",
                    choices  = c("All Districts", sort(unique(data$district))),
                    selected = "All Districts"),
        dateRangeInput("date_range", "📅 Date Range:",
                       start = max(data$date, na.rm=TRUE) - 90,
                       end   = max(data$date, na.rm=TRUE))
    ),
    
    hr(),
    
    div(class="sidebar-info",
        "🛰️ Source: NASA POWER API", br(),
        "🔄 Refresh: Daily", br(),
        paste0("📅 Latest data: ", max(data$date, na.rm=TRUE)), br(),
        "🇱🇰 Coverage: 6 districts"
    )
  ),
  
  dashboardBody(
    
    tabItems(
      
      # ══════════════════════════════════════════
      # TAB 1 — LIVE MAP
      # ══════════════════════════════════════════
      tabItem("map",
              fluidRow(
                valueBoxOutput("box_high",    width=3),
                valueBoxOutput("box_mod",     width=3),
                valueBoxOutput("box_rain",    width=3),
                valueBoxOutput("box_hottest", width=3)
              ),
              fluidRow(
                box(width=8, height=570,
                    title=tags$span(style="color:#58a6ff;", "🗺️ Sri Lanka Live Risk Map"),
                    solidHeader=TRUE, status="primary",
                    leafletOutput("live_map", height=490)),
                box(width=4, height=570,
                    title=tags$span(style="color:#ffa657;", "⚡ District Alerts"),
                    solidHeader=TRUE, status="warning",
                    div(style="overflow-y:auto; max-height:490px;",
                        tableOutput("alert_table")))
              )
      ),
      
      # ══════════════════════════════════════════
      # TAB 2 — FLOOD RISK
      # ══════════════════════════════════════════
      tabItem("flood",
              fluidRow(
                box(width=12,
                    title=tags$span(style="color:#f78166;","🌊 Flood Risk Days by District (2020–2024)"),
                    solidHeader=TRUE, status="danger",
                    plotlyOutput("flood_bar", height=380))
              ),
              fluidRow(
                box(width=6,
                    title=tags$span(style="color:#ffa657;","📅 Monthly High Risk Pattern"),
                    solidHeader=TRUE, status="warning",
                    plotlyOutput("flood_monthly", height=320)),
                box(width=6,
                    title=tags$span(style="color:#f78166;","🔥 Risk Heatmap"),
                    solidHeader=TRUE, status="danger",
                    plotlyOutput("flood_heatmap", height=320))
              )
      ),
      
      # ══════════════════════════════════════════
      # TAB 3 — RAINFALL
      # ══════════════════════════════════════════
      tabItem("trend",
              fluidRow(
                box(width=12,
                    title=tags$span(style="color:#58a6ff;","🌧️ Rainfall Trend Over Time"),
                    solidHeader=TRUE, status="info",
                    plotlyOutput("rainfall_trend", height=380))
              ),
              fluidRow(
                box(width=6,
                    title=tags$span(style="color:#58a6ff;","📊 Monthly Average Rainfall"),
                    solidHeader=TRUE, status="primary",
                    plotlyOutput("monthly_rain", height=320)),
                box(width=6,
                    title=tags$span(style="color:#79c0ff;","📈 Rainfall Distribution"),
                    solidHeader=TRUE, status="info",
                    plotlyOutput("rain_dist", height=320))
              )
      ),
      
      # ══════════════════════════════════════════
      # TAB 4 — TEMPERATURE
      # ══════════════════════════════════════════
      tabItem("temp",
              fluidRow(
                box(width=12,
                    title=tags$span(style="color:#ffa657;","🌡️ Temperature Trends"),
                    solidHeader=TRUE, status="danger",
                    plotlyOutput("temp_trend", height=380))
              ),
              fluidRow(
                box(width=6,
                    title=tags$span(style="color:#ffa657;","🌡️ Avg Temperature by District"),
                    solidHeader=TRUE, status="warning",
                    plotlyOutput("temp_bar", height=320)),
                box(width=6,
                    title=tags$span(style="color:#58a6ff;","💧 Humidity vs Temperature"),
                    solidHeader=TRUE, status="info",
                    plotlyOutput("temp_humidity", height=320))
              )
      ),
      
      # ══════════════════════════════════════════
      # TAB 5 — DISTRICT STATS
      # ══════════════════════════════════════════
      tabItem("stats",
              fluidRow(
                box(width=12,
                    title=tags$span(style="color:#3fb950;","📊 Full District Statistics Table"),
                    solidHeader=TRUE, status="success",
                    DTOutput("stats_table"))
              )
      ),
      
      # ══════════════════════════════════════════
      # TAB 6 — ML PREDICTIONS
      # ══════════════════════════════════════════
      tabItem("ml",
              fluidRow(
                box(width=12,
                    title=tags$span(style="color:#3fb950;","🤖 ML Flood Risk Probability by District"),
                    solidHeader=TRUE, status="success",
                    plotlyOutput("ml_chart", height=380))
              ),
              fluidRow(
                box(width=5,
                    title=tags$span(style="color:#58a6ff;","🎯 Model Specifications"),
                    solidHeader=TRUE, status="info",
                    div(style="padding:20px; line-height:2.2; font-size:14px; color:#c9d1d9;",
                        tags$table(style="width:100%;",
                                   tags$tr(
                                     tags$td(style="color:#8b949e; width:45%;","Algorithm"),
                                     tags$td(style="color:#58a6ff; font-weight:600;","Random Forest 🌲")
                                   ),
                                   tags$tr(
                                     tags$td(style="color:#8b949e;","Decision Trees"),
                                     tags$td(style="color:#3fb950; font-weight:600;","500 trees")
                                   ),
                                   tags$tr(
                                     tags$td(style="color:#8b949e;","Input Features"),
                                     tags$td(style="color:#ffa657; font-weight:600;","9 weather variables")
                                   ),
                                   tags$tr(
                                     tags$td(style="color:#8b949e;","Output Classes"),
                                     tags$td(style="color:#d2a8ff; font-weight:600;","4 risk levels")
                                   ),
                                   tags$tr(tags$td(tags$hr(), colspan=2)),
                                   tags$tr(
                                     tags$td(style="color:#8b949e;","🥇 Top Feature"),
                                     tags$td(style="color:#f78166; font-weight:600;","Rain Spike Index")
                                   ),
                                   tags$tr(
                                     tags$td(style="color:#8b949e;","🥈 2nd Feature"),
                                     tags$td(style="color:#f78166;","7-Day Rainfall Avg")
                                   ),
                                   tags$tr(
                                     tags$td(style="color:#8b949e;","🥉 3rd Feature"),
                                     tags$td(style="color:#f78166;","Humidity Level")
                                   )
                        )
                    )
                ),
                box(width=7,
                    title=tags$span(style="color:#3fb950;","📋 Live Prediction Results"),
                    solidHeader=TRUE, status="success",
                    DTOutput("pred_table"))
              )
      )
    )
  )
)

# ══════════════════════════════════════════════
# SERVER
# ══════════════════════════════════════════════
server <- function(input, output, session) {
  
  # Live clock
  output$live_clock <- renderText({
    invalidateLater(1000, session)
    format(Sys.time(), "%H:%M:%S  |  %d %b %Y")
  })
  
  # Reactive filtered data
  filtered <- reactive({
    d <- data %>%
      filter(date >= input$date_range[1],
             date <= input$date_range[2])
    if(input$selected_district != "All Districts")
      d <- d %>% filter(district == input$selected_district)
    d
  })
  
  # ── VALUE BOXES ──
  output$box_high <- renderValueBox({
    n <- sum(filtered()$flood_risk == "HIGH", na.rm=TRUE)
    valueBox(
      value    = n,
      subtitle = "🔴 HIGH Risk Days",
      color    = "red",
      icon     = icon("triangle-exclamation")
    )
  })
  output$box_mod <- renderValueBox({
    n <- sum(filtered()$flood_risk == "MODERATE", na.rm=TRUE)
    valueBox(n, "🟠 Moderate Risk Days", color="orange", icon=icon("cloud-rain"))
  })
  output$box_rain <- renderValueBox({
    avg <- round(mean(filtered()$rainfall, na.rm=TRUE), 1)
    valueBox(paste0(avg," mm"), "💧 Avg Daily Rainfall", color="blue", icon=icon("droplet"))
  })
  output$box_hottest <- renderValueBox({
    hot <- filtered() %>%
      group_by(district) %>%
      summarise(avg=mean(temp, na.rm=TRUE), .groups="drop") %>%
      slice_max(avg, n=1)
    valueBox(hot$district,
             paste0("🌡️ Hottest: ", round(hot$avg,1),"°C"),
             color="yellow", icon=icon("sun"))
  })
  
  # ── LIVE MAP ──
  # ── LIVE MAP ──
  output$live_map <- renderLeaflet({
    
    pal <- c(HIGH="#ff4444", MODERATE="#ff8c00", LOW="#ffd700", MINIMAL="#00cc44")
    
    # Join boundary shapefile with today's predictions
    map_data <- lka_districts %>%
      left_join(
        predictions %>% mutate(color = pal[as.character(risk_level)]),
        by = c("NAME_2" = "district")
      ) %>%
      mutate(
        color      = ifelse(is.na(color), "#555555", color),
        risk_level = ifelse(is.na(risk_level), "No Data", as.character(risk_level)),
        prob_high  = ifelse(is.na(prob_high), 0, prob_high),
        alert      = ifelse(is.na(alert), "—", as.character(alert)),
        popup_html = ifelse(
          risk_level == "No Data",
          paste0("<b>", NAME_2, "</b><br>No prediction data"),
          paste0(
            "<div style='background:#0d1117;color:#c9d1d9;padding:16px;",
            "border-radius:10px;font-family:Inter,sans-serif;min-width:210px;",
            "border:1px solid #21262d;'>",
            "<h3 style='color:#58a6ff;margin:0 0 10px;font-size:15px;'>📍 ", NAME_2, "</h3>",
            "<div style='font-size:13px;line-height:2;'>",
            "<span style='color:#8b949e;'>🤖 Risk Level</span>  <b style='color:#e6edf3;'>", risk_level, "</b><br>",
            "<span style='color:#8b949e;'>📊 High Prob</span>  <b style='color:#f78166;'>", prob_high, "%</b><br>",
            "<span style='color:#8b949e;'>🚨 Alert</span>  <b>", alert, "</b>",
            "</div></div>"
          )
        )
      )
    
    leaflet(map_data) %>%
      addProviderTiles("CartoDB.DarkMatter") %>%
      setView(lng = 80.7, lat = 7.8, zoom = 7) %>%
      
      # ✅ Filled district risk areas instead of dots
      addPolygons(
        fillColor    = ~color,
        fillOpacity  = 0.65,
        color        = "#ffffff",
        weight       = 1.2,
        opacity      = 0.7,
        highlightOptions = highlightOptions(
          weight       = 3,
          color        = "#58a6ff",
          fillOpacity  = 0.85,
          bringToFront = TRUE
        ),
        popup = ~popup_html,
        label = ~paste0("📍 ", NAME_2, "  |  ", risk_level, "  |  ", prob_high, "%")
      ) %>%
      
      addLegend(
        "bottomright",
        colors  = c("#ff4444","#ff8c00","#ffd700","#00cc44","#555555"),
        labels  = c("HIGH","MODERATE","LOW","MINIMAL","No Data"),
        title   = "🌊 Flood Risk",
        opacity = 0.9
      )
  })  
  # ── ALERT TABLE ──
  output$alert_table <- renderTable({
    predictions %>%
      dplyr::select(district, risk_level, prob_high, alert) %>%
      arrange(desc(prob_high)) %>%
      rename(District=district, Risk=risk_level, "High%"=prob_high, Alert=alert)
  }, striped=TRUE, hover=TRUE, bordered=TRUE)
  
  # ── FLOOD BAR ──
  output$flood_bar <- renderPlotly({
    d <- data %>%
      filter(flood_risk %in% c("HIGH","MODERATE","LOW")) %>%
      group_by(district, flood_risk) %>%
      summarise(days=n(), .groups="drop")
    
    plot_ly(d, x=~district, y=~days, color=~flood_risk, type="bar",
            colors=c("HIGH"="#ff4444","MODERATE"="#ff8c00","LOW"="#ffd700")) %>%
      layout(barmode="group") %>%
      dark_layout("District", "Number of Days")
  })
  
  # ── MONTHLY FLOOD ──
  output$flood_monthly <- renderPlotly({
    m <- filtered() %>%
      group_by(month) %>%
      summarise(high_days=sum(flood_risk=="HIGH", na.rm=TRUE), .groups="drop")
    
    plot_ly(m, x=~month, y=~high_days, type="scatter", mode="lines+markers",
            line=list(color="#ff4444", width=3, shape="spline"),
            marker=list(color="#ff4444", size=9,
                        line=list(color="#ffffff", width=1.5))) %>%
      dark_layout("Month", "High Risk Days")
  })
  
  # ── HEATMAP ──
  output$flood_heatmap <- renderPlotly({
    h <- data %>%
      mutate(month_num=as.numeric(format(date,"%m"))) %>%
      group_by(district, month_num) %>%
      summarise(high_days=sum(flood_risk=="HIGH", na.rm=TRUE), .groups="drop")
    
    plot_ly(h, x=~month_num, y=~district, z=~high_days, type="heatmap",
            colorscale=list(
              list(0,"#0d1117"), list(0.3,"#3fb950"),
              list(0.6,"#ffd700"), list(1,"#ff4444")
            )) %>%
      dark_layout("Month","")
  })
  
  # ── RAINFALL TREND ──
  output$rainfall_trend <- renderPlotly({
    d <- filtered() %>%
      group_by(date, district) %>%
      summarise(rain=mean(rainfall, na.rm=TRUE), .groups="drop")
    
    plot_ly(d, x=~date, y=~rain, color=~district, type="scatter", mode="lines",
            colors=SL_PALETTE,
            line=list(width=2)) %>%
      dark_layout("Date", "Rainfall (mm)")
  })
  
  # ── MONTHLY RAIN ──
  output$monthly_rain <- renderPlotly({
    m <- filtered() %>%
      group_by(month) %>%
      summarise(avg_rain=mean(rainfall, na.rm=TRUE), .groups="drop")
    
    plot_ly(m, x=~month, y=~avg_rain, type="bar",
            marker=list(
              color=~avg_rain,
              colorscale=list(list(0,"#1f6feb"), list(1,"#58a6ff")),
              line=list(color="rgba(255,255,255,0.1)", width=0.5)
            )) %>%
      dark_layout("Month", "Avg Rainfall (mm)")
  })
  
  # ── RAIN DISTRIBUTION ──
  output$rain_dist <- renderPlotly({
    plot_ly(filtered(), x=~rainfall, type="histogram", nbinsx=40,
            marker=list(
              color="rgba(88,166,255,0.7)",
              line=list(color="rgba(88,166,255,0.2)", width=0.5)
            )) %>%
      dark_layout("Rainfall (mm)", "Frequency")
  })
  
  # ── TEMP TREND ──
  output$temp_trend <- renderPlotly({
    d <- filtered() %>%
      group_by(date, district) %>%
      summarise(temp=mean(temp, na.rm=TRUE), .groups="drop")
    
    plot_ly(d, x=~date, y=~temp, color=~district, type="scatter", mode="lines",
            colors=SL_PALETTE, line=list(width=2)) %>%
      dark_layout("Date","Temperature (°C)")
  })
  
  # ── TEMP BAR ──
  output$temp_bar <- renderPlotly({
    d <- data %>%
      group_by(district) %>%
      summarise(avg_temp=mean(temp, na.rm=TRUE), .groups="drop") %>%
      arrange(desc(avg_temp))
    
    plot_ly(d, x=~reorder(district,-avg_temp), y=~avg_temp, type="bar",
            marker=list(
              color=~avg_temp,
              colorscale=list(list(0,"#1f6feb"), list(0.5,"#ffa657"), list(1,"#ff4444")),
              showscale=FALSE
            )) %>%
      dark_layout("District","Avg Temperature (°C)")
  })
  
  # ── HUMIDITY vs TEMP ──
  output$temp_humidity <- renderPlotly({
    plot_ly(filtered(), x=~temp, y=~humidity, color=~district,
            type="scatter", mode="markers",
            colors=SL_PALETTE,
            marker=list(size=5, opacity=0.55)) %>%
      dark_layout("Temperature (°C)","Humidity (%)")
  })
  
  # ── STATS TABLE ──
  output$stats_table <- renderDT({
    data %>%
      group_by(district) %>%
      summarise(
        `Avg Rain (mm)` = round(mean(rainfall,  na.rm=TRUE), 2),
        `Max Rain (mm)` = round(max(rainfall,   na.rm=TRUE), 2),
        `Avg Temp (°C)` = round(mean(temp,      na.rm=TRUE), 1),
        `Humidity (%)`  = round(mean(humidity,  na.rm=TRUE), 1),
        `HIGH Risk Days`= sum(flood_risk=="HIGH",     na.rm=TRUE),
        `MODERATE Days` = sum(flood_risk=="MODERATE", na.rm=TRUE),
        `LOW Days`      = sum(flood_risk=="LOW",      na.rm=TRUE)
      ) %>%
      rename(District=district)
  },
  options=list(pageLength=10, dom="ft",
               initComplete=JS("function(settings,json){ $(this.api().table().header()).css({'color':'#58a6ff'}); }")),
  style="bootstrap4",
  class="table-dark table-striped table-hover"
  )
  
  # ── ML CHART ──
  output$ml_chart <- renderPlotly({
    pred <- predictions %>% arrange(desc(prob_high))
    
    plot_ly(pred, x=~reorder(district, prob_high), y=~prob_high,
            type="bar", orientation="v",
            marker=list(
              color=~prob_high,
              colorscale=list(
                list(0.0,"#3fb950"),
                list(0.4,"#ffd700"),
                list(0.7,"#ff8c00"),
                list(1.0,"#ff4444")
              ),
              showscale=TRUE,
              colorbar=list(title="Risk %", tickfont=list(color="#8b949e")),
              line=list(color="rgba(255,255,255,0.1)", width=0.5)
            ),
            text=~paste0(prob_high, "%"),
            textposition="outside",
            textfont=list(color="#e6edf3", size=13)) %>%
      dark_layout("District","High Flood Risk Probability (%)")
  })
  
  # ── ML PRED TABLE ──
  output$pred_table <- renderDT({
    predictions %>%
      dplyr::select(district, risk_level, prob_high, alert) %>%
      arrange(desc(prob_high)) %>%
      rename(District=district, `Risk Level`=risk_level,
             `High Risk %`=prob_high, Alert=alert)
  },
  options=list(pageLength=10, dom="t"),
  style="bootstrap4",
  class="table-dark table-striped table-hover"
  )
}

# ══════════════════════════════════════════════
# LAUNCH
# ══════════════════════════════════════════════
cat("\n")
cat("╔══════════════════════════════════════════════╗\n")
cat("║  🛰️  SL WEATHER INTELLIGENCE v2.0           ║\n")
cat("║  🚀  Launching Ultra Modern Dashboard...     ║\n")
cat("║  ⛔  Press Ctrl+C to stop                   ║\n")
cat("╚══════════════════════════════════════════════╝\n\n")

shinyApp(ui=ui, server=server)