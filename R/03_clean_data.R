library(tidyverse)
library(lubridate)

cat("🧹 Starting data cleaning...\n\n")

# Load raw data
data <- readRDS(
  "D:/traning project/sri-lanka-weather/data/satellite/weather_data.rds"
)

# ── STEP 7A: Fix column names ──────────────────
cat("Step 7A: Fixing column names...\n")

data <- data %>%
  rename(
    date      = YYYYMMDD,
    rainfall  = PRECTOTCORR,
    temp      = T2M,
    humidity  = RH2M,
    wind      = WS10M
  )

cat("✅ Column names fixed!\n")
print(names(data))

# ── STEP 7B: Fix date column ───────────────────
cat("\nStep 7B: Fixing dates...\n")

data <- data %>%
  mutate(
    date  = as.Date(as.character(date), format="%Y%m%d"),
    year  = year(date),
    month = month(date, label=TRUE),  # Jan, Feb, Mar...
    day   = day(date),
    season = case_when(
      month %in% c("Mar","Apr","May") ~ "SW Monsoon Start",
      month %in% c("Jun","Jul","Aug","Sep") ~ "SW Monsoon Peak",
      month %in% c("Oct","Nov") ~ "NE Monsoon Start",
      month %in% c("Dec","Jan","Feb") ~ "NE Monsoon Peak",
      TRUE ~ "Other"
    )
  )

cat("✅ Dates fixed!\n")
cat("Date range:", format(min(data$date)), "to",
    format(max(data$date)), "\n")

# ── STEP 7C: Handle missing values ────────────
cat("\nStep 7C: Checking missing values...\n")

missing <- data %>%
  summarise(across(everything(), ~sum(is.na(.))))

print(missing)

# Fill missing with district average
data <- data %>%
  group_by(district) %>%
  mutate(
    rainfall = ifelse(is.na(rainfall),
                      mean(rainfall, na.rm=TRUE), rainfall),
    temp     = ifelse(is.na(temp),
                      mean(temp, na.rm=TRUE), temp),
    humidity = ifelse(is.na(humidity),
                      mean(humidity, na.rm=TRUE), humidity),
    wind     = ifelse(is.na(wind),
                      mean(wind, na.rm=TRUE), wind)
  ) %>%
  ungroup()

cat("✅ Missing values handled!\n")

# ── STEP 7D: Add flood risk features ──────────
cat("\nStep 7D: Adding flood risk features...\n")

data <- data %>%
  arrange(district, date) %>%
  group_by(district) %>%
  mutate(
    # Rolling rainfall — last 3, 7, 30 days
    rain_3day  = zoo::rollmean(rainfall, 3,  fill=NA, align="right"),
    rain_7day  = zoo::rollmean(rainfall, 7,  fill=NA, align="right"),
    rain_30day = zoo::rollmean(rainfall, 30, fill=NA, align="right"),
    
    # Rain spike — sudden increase vs 30 day average
    rain_spike = rainfall / (rain_30day + 0.01),
    
    # Humidity spike
    humidity_spike = humidity / mean(humidity, na.rm=TRUE),
    
    # Is this a HIGH RAIN day? (top 10% for that district)
    high_rain_day = rainfall > quantile(rainfall, 0.90, na.rm=TRUE),
    
    # Flood risk label (for ML training!)
    # Based on: very high rain + high humidity + sustained rain
    flood_risk = case_when(
      rain_spike > 3 & humidity > 90 & rain_7day > 10 ~ "HIGH",
      rain_spike > 2 & humidity > 85                  ~ "MODERATE",
      high_rain_day                                    ~ "LOW",
      TRUE                                             ~ "MINIMAL"
    )
  ) %>%
  ungroup()

cat("✅ Flood features added!\n")

# ── STEP 7E: Summary of flood risk days ───────
cat("\nStep 7E: Flood risk summary...\n")

data %>%
  group_by(district, flood_risk) %>%
  summarise(days = n(), .groups="drop") %>%
  pivot_wider(names_from=flood_risk, values_from=days) %>%
  print()

# ── STEP 7F: Save clean data ───────────────────
cat("\nStep 7F: Saving clean data...\n")

saveRDS(
  data,
  "D:/traning project/sri-lanka-weather/data/satellite/clean_data.rds"
)

cat("\n✅ STEP 7 COMPLETE!\n")
cat("Clean data saved!\n")
cat("Total rows:", nrow(data), "\n")
cat("Total columns:", ncol(data), "\n")
cat("\nNew columns added:\n")
cat("→ rain_3day, rain_7day, rain_30day\n")
cat("→ rain_spike, humidity_spike\n")
cat("→ high_rain_day, flood_risk\n")
cat("→ year, month, day, season\n")