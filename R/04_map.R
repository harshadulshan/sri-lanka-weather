library(tidyverse)
library(leaflet)
library(lubridate)
library(sf)          # ← NEW: for handling shapefiles
library(geodata)     # ← NEW: for downloading district boundaries

cat("🗺️ Building Sri Lanka Risk Area Map...\n\n")

# Load clean data
data <- readRDS(
  "D:/traning project/sri-lanka-weather/data/satellite/clean_data.rds"
)

# ── STEP 8A: Summarise by district ────────────
cat("Step 8A: Summarising district data...\n")

district_summary <- data %>%
  group_by(district) %>%
  summarise(
    avg_rain       = round(mean(rainfall, na.rm = TRUE), 2),
    max_rain       = round(max(rainfall,  na.rm = TRUE), 2),
    avg_temp       = round(mean(temp,     na.rm = TRUE), 1),
    avg_humidity   = round(mean(humidity, na.rm = TRUE), 1),
    high_risk_days = sum(flood_risk == "HIGH",     na.rm = TRUE),
    moderate_days  = sum(flood_risk == "MODERATE", na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    risk_color = case_when(
      high_risk_days >= 20 ~ "#FF0000",
      high_risk_days >= 10 ~ "#FF8C00",
      high_risk_days >= 5  ~ "#FFD700",
      TRUE                 ~ "#00CC44"
    ),
    risk_label = case_when(
      high_risk_days >= 20 ~ "HIGH",
      high_risk_days >= 10 ~ "MODERATE",
      high_risk_days >= 5  ~ "LOW",
      TRUE                 ~ "MINIMAL"
    )
  )

cat("✅ District summary done!\n")
print(district_summary)

# ── STEP 8B: Load Sri Lanka District Boundaries ──
cat("\nStep 8B: Loading district boundaries...\n")

# Download Sri Lanka GADM admin level 2 (districts)
# This saves to a local cache automatically
lka_districts <- geodata::gadm(
  country = "LKA",
  level   = 2,
  path    = "D:/traning project/sri-lanka-weather/data/"
) %>%
  sf::st_as_sf()  # convert to sf object for leaflet

cat("✅ Boundary data loaded!\n")
cat("Districts in shapefile:\n")
print(unique(lka_districts$NAME_2))

# ── STEP 8C: Match boundary data with your district names ──
cat("\nStep 8C: Matching your districts to boundary data...\n")

# Your 6 districts → match to GADM NAME_2 column
# (GADM may spell some differently, adjust if needed)
district_name_map <- c(
  "Colombo"   = "Colombo",
  "Kandy"     = "Kandy",
  "Galle"     = "Galle",
  "Jaffna"    = "Jaffna",
  "Badulla"   = "Badulla",
  "Ratnapura" = "Ratnapura"
)

# Join shapefile with your risk data
lka_joined <- lka_districts %>%
  left_join(
    district_summary,
    by = c("NAME_2" = "district")
  ) %>%
  mutate(
    # Districts with no data get grey
    risk_color = ifelse(is.na(risk_color), "#AAAAAA", risk_color),
    risk_label = ifelse(is.na(risk_label), "No Data",  risk_label),
    # Safe popup text (handles NAs)
    popup_text = ifelse(
      is.na(avg_rain),
      paste0("<b>", NAME_2, "</b><br>No data available"),
      paste0(
        "<div style='font-family:Arial; padding:10px;'>",
        "<h3 style='color:#FF6B35;'>📍 ", NAME_2, "</h3>",
        "<hr>",
        "<b>⚠️ Risk Level:</b> <span style='color:", risk_color, ";'>",
        risk_label, "</span><br>",
        "<b>🌧️ Avg Rainfall:</b> ", avg_rain, " mm/day<br>",
        "<b>⛈️ Max Rainfall:</b> ", max_rain, " mm/day<br>",
        "<b>🌡️ Avg Temp:</b> ",     avg_temp, " °C<br>",
        "<b>💧 Avg Humidity:</b> ", avg_humidity, "%<br>",
        "<hr>",
        "<b>🔴 HIGH Risk Days:</b> ",     high_risk_days, " days<br>",
        "<b>🟠 MODERATE Risk Days:</b> ", moderate_days,  " days<br>",
        "</div>"
      )
    )
  )

cat("✅ Join complete!\n")

# ── STEP 8D: Build interactive map with RISK AREAS ──
cat("\nStep 8D: Building interactive risk area map...\n")

map <- leaflet(lka_joined) %>%
  
  # Base map
  addProviderTiles("CartoDB.DarkMatter") %>%
  
  # Center on Sri Lanka
  setView(lng = 80.7, lat = 7.8, zoom = 7) %>%
  
  # ✅ KEY FIX: Draw filled district polygons (risk areas)
  addPolygons(
    fillColor   = ~risk_color,
    fillOpacity = 0.6,
    color       = "#FFFFFF",      # white border between districts
    weight      = 1.5,
    opacity     = 0.8,
    # Highlight on hover
    highlightOptions = highlightOptions(
      weight      = 3,
      color       = "#FFFFFF",
      fillOpacity = 0.85,
      bringToFront = TRUE
    ),
    popup = ~popup_text,
    label = ~paste0(NAME_2, " — ", risk_label, " Risk")
  ) %>%
  
  # Legend
  addLegend(
    position = "bottomright",
    colors   = c("#FF0000", "#FF8C00", "#FFD700", "#00CC44", "#AAAAAA"),
    labels   = c(
      "HIGH Risk (20+ high-risk days)",
      "MODERATE Risk (10–20 days)",
      "LOW Risk (5–10 days)",
      "MINIMAL Risk (<5 days)",
      "No Data"
    ),
    title   = "🌊 Flood Risk Level",
    opacity = 0.9
  ) %>%
  
  # Title
  addControl(
    html = "<div style='background:rgba(0,0,0,0.7);
            color:white; padding:10px; border-radius:5px;
            font-family:Arial; font-size:14px;'>
            🛰️ <b>Sri Lanka Weather Intelligence</b><br>
            <small>NASA Satellite Data 2020–2024</small>
            </div>",
    position = "topleft"
  )

# ── STEP 8E: Save ────────────────────────────────
cat("\nStep 8E: Saving map...\n")

htmlwidgets::saveWidget(
  map,
  "D:/traning project/sri-lanka-weather/output/sri_lanka_risk_map.html",
  selfcontained = TRUE
)

cat("✅ Risk area map saved!\n")
cat("📂 Open: D:/traning project/sri-lanka-weather/output/sri_lanka_risk_map.html\n")

print(map)
cat("\n✅ STEP 8 COMPLETE — Risk areas now visible!\n")